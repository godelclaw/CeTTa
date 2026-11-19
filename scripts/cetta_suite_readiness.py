"""The complete suite, one stage at a time, cheapest first.

The stages are the Makefile's: the gates in SUITE_CORRECTNESS_GATES check
correctness, then come those in SUITE_ASYMPTOTIC_GATES, SUITE_EXAMPLES_GATES
and SUITE_COMPREHENSIVE_GATES.  make test-all and the other stage targets run
this suite; a stage target has no prerequisites, so no make reaches the gates
except through it.  Each gate runs with CETTA_SUITE_STAGE set: the Makefile
then keeps the stage's configuration for every gate, instead of choosing one
for a gate it is asked for alone.

Within a stage, the gates that failed when last run go first, then the
longest.  One make first brings the files of the stage's configuration up to
date, and those of its runtime-stats build, so no two makes build the same
file.  The gates that build another configuration then run one after another
in one lane; the others run beside them, --jobs at a time in all, each in its
own make.  The asymptotic checks run one at a time, as other runs would
disturb what they measure.  A gate that is a prerequisite of another gate of
its stage runs inside that gate; a gate that only gathers others runs as
those gates.  A named target inside a gate runs as a gate of its own.  The
run stops after the first stage with a failure.

Each gate's latest output is runtime/main-readiness/suite/logs/GATE.log, and
every result is appended to runtime/main-readiness/suite/results.tsv.
"""

from __future__ import annotations

import collections
import concurrent.futures
import fcntl
import os
import re
import subprocess
import sys
import time
from pathlib import Path

STAGES = ("correctness", "asymptotic", "examples", "comprehensive")
STAGE_TARGETS = {"test-all"} | {f"test-{stage}" for stage in STAGES[1:]}
STAGE_VARIABLES = {stage: f"SUITE_{stage.upper()}_GATES" for stage in STAGES}
# Settings that name a build configuration.  A make that sets none of them, or
# only the configuration it already has, builds nothing new.
CONFIGURATION_SETTING = re.compile(
    r"^(BUILD|ENABLE_[A-Z0-9_]+|SANITIZERS|CETTA_TEST_ISOLATED|CETTA_PROVENANCE_ASSERT|"
    r"RHOCOST_COMMIT_AUDIT|TERM_UNIVERSE_COLLECTION_CHECKS|CETTA_INTERACTION_COMMIT_CHECKED|"
    r"CETTA_PROC_FORK_SPAWN|CETTA_PGO|CETTA_PGO_RUN|SQLITE_PROVIDER|PYTHON_CONFIG)=")
SAME_CONFIGURATION = {"BUILD=$(BUILD_CANON)", "BUILD=$(BUILD)"}


def gate_environment(stage):
    """The environment of the makes the suite runs: the stage named, test
    executables named by their configuration, as the prebuild makes them, and
    make's own flags without a job count or job server, which each make gets
    anew; settings given to the make that started the suite stay."""
    environment = dict(os.environ, CETTA_SUITE_STAGE=stage, CETTA_TEST_ISOLATED="1")
    flags = environment.get("MAKEFLAGS", "")
    if flags:
        head, separator, settings = flags.partition(" -- ")
        words = [word for word in head.split()
                 if not word.startswith(("-j", "--jobserver", "--jobs"))]
        if words and not words[0].startswith("-") and "=" not in words[0]:
            # single-letter flags first, as make writes them ("ks")
            words[0] = words[0].replace("j", "")
            if not words[0]:
                words = words[1:]
        environment["MAKEFLAGS"] = " ".join(words) + (separator + settings if separator else "")
    environment.pop("MAKELEVEL", None)
    return environment


def make_database(root, settings=(), stage="correctness"):
    """Prerequisites, recipes, phony targets and the stages' gate lists, as
    make itself reads them.

    The goal has no rule, so make prints what it read and runs nothing, not even
    the recipe lines that -n runs; its name starts with test, as test-all's
    does, so the Makefile reads the configuration test-all gets."""
    text = subprocess.run(["make", "-pq", *settings, "test-suite-readiness-database"],
                          cwd=root, capture_output=True, text=True,
                          env=gate_environment(stage)).stdout
    prerequisites = collections.defaultdict(list)
    recipes = collections.defaultdict(str)
    phony, ordered = set(), set()
    variables, values = {}, {}
    current = None
    for line in text.splitlines():
        variable = re.match(r"^(SUITE_[A-Z]+_GATES) :?= ?(.*)$", line)
        if variable:
            variables[variable.group(1)] = variable.group(2).split()
            current = None
            continue
        value = re.match(r"^([A-Z][A-Z0-9_]*) :?= ?(\S*)$", line)
        if value:
            values[value.group(1)] = value.group(2)
            current = None
            continue
        if line.startswith("\t"):
            if current:
                recipes[current] += line + "\n"
        elif line.startswith("#"):
            if current and "Phony target" in line:
                phony.add(current)
        elif not line.strip():
            current = None
        else:
            rule = re.match(r"^([^\s:#=]+):(?![:=])\s*(.*)$", line)
            if rule and not re.match(r"^\S+\s*[:+?]?=", rule.group(2)):
                current = rule.group(1)
                names = rule.group(2).replace("|", " ").split()
                if ".WAIT" in names:
                    ordered.add(current)
                prerequisites[current].extend(name for name in names if name != ".WAIT")
    prerequisites[".SUITE"] = variables
    prerequisites[".VALUES"] = values
    return prerequisites, recipes, phony, ordered


def expand_aggregates(gates, database):
    """A gate that only gathers other gates, with no recipe of its own and no
    order among them, runs as those gates, so they spread over the jobs."""
    prerequisites, recipes, phony, ordered = database
    serial = set(prerequisites.get(".NOTPARALLEL", ())) | ordered
    expanded = []

    def add(gate):
        parts = prerequisites.get(gate, ())
        if (parts and not recipes.get(gate) and gate not in serial
                and all(part.startswith(("test-", "check-")) for part in parts)):
            for part in dict.fromkeys(parts):
                add(part)
        elif gate not in expanded:
            expanded.append(gate)

    for gate in gates:
        add(gate)
    return expanded


STATS_SETTINGS = ("ENABLE_RUNTIME_STATS=1",)


def kept_setting(word, values):
    """A setting that leaves the configuration as it is: it passes the
    variable's own value on, or names the value the variable has."""
    name, _, value = word.partition("=")
    value = value.strip("'\"")
    if value in (f"$({name})", f"${{{name}}}") or (name == "BUILD" and value == "$(BUILD_CANON)"):
        return True
    have = values.get("BUILD_CANON" if name == "BUILD" else name)
    return have is not None and "$" not in value and value == have


def stats_goals(line, target, values=None):
    """The goals of a recipe line that runs make again: ("same", goals) when
    every make it runs keeps this configuration, ("stats", goals) when each
    only adds the runtime-stats build of it, or None when one builds another
    configuration.  A make that keeps the configuration but names its goals
    through variables makes files of it, and adds no goals to follow."""
    if "$(MAKE)" not in line or line.rstrip().endswith("\\"):
        return None
    values = values or {}
    if re.search(r"env\s+(-\S+\s+)*-u\s+(BUILD|MAKEFLAGS|CETTA_SUITE_STAGE)\b", line):
        return None  # the make chooses a configuration afresh
    kinds, goals = set(), []
    for command in line.split("$(MAKE)")[1:]:
        # the make command ends where its shell command does
        words = re.split(r";|&&|\|\|?|>|<", command, maxsplit=1)[0].split()
        if any(word in ("-n", "--dry-run", "--just-print", "--recon")
               or re.fullmatch(r"-[A-Za-z]*n[A-Za-z]*", word) for word in words):
            kinds.add("same")  # it prints commands and runs none
            continue
        settings = {word for word in words
                    if "=" in word and CONFIGURATION_SETTING.match(word)
                    and not kept_setting(word, values)}
        named = [word.replace("$@", target) for word in words
                 if "=" not in word and not word.startswith("-")
                 and not re.fullmatch(r"\$\([A-Z0-9_]+_CONFIGURATION_V1\)", word)]
        indirect = [goal for goal in named if "$" in goal]
        if settings == {"ENABLE_RUNTIME_STATS=1"} and not indirect:
            kinds.add("stats")
        elif not settings:
            kinds.add("same")
            named = [goal for goal in named if "$" not in goal]
        else:
            return None
        goals += named
    if len(kinds) != 1:
        return None
    return kinds.pop(), goals


def file_prerequisites(database, targets):
    """The files make needs before the recipes of these targets can run."""
    prerequisites, _, phony, _ = database
    return {name for target in targets
            for reached in closure(prerequisites, target) | {target}
            if is_gate(reached, phony)
            for name in prerequisites.get(reached, ()) if not is_gate(name, phony)}


def is_gate(name, phony):
    """A target that is a check rather than a file: declared phony, or named as
    a test or a check (some gates are not declared phony)."""
    return name in phony or name.startswith(("test-", "check-"))


def closure(prerequisites, target):
    seen, pending = set(), [target]
    while pending:
        for name in prerequisites.get(pending.pop(), ()):
            if name not in seen:
                seen.add(name)
                pending.append(name)
    return seen


def stage_gates(database):
    """Each stage's gates, in the Makefile's order.  A gate belongs to one stage,
    and a stage target gathers none: a gate made its prerequisite would run in
    any make of the target, outside the stages."""
    prerequisites, _, phony, _ = database
    for target in sorted(STAGE_TARGETS):
        if prerequisites.get(target):
            raise SystemExit(f"FAIL: {target} has prerequisites ({' '.join(prerequisites[target][:5])}); "
                             f"add a gate to its stage's SUITE_*_GATES instead")
    lists = prerequisites.get(".SUITE", {})
    stages, owner = {}, {}
    for stage in STAGES:
        gates = [name for name in dict.fromkeys(lists.get(STAGE_VARIABLES[stage], ()))
                 if is_gate(name, phony) and name not in STAGE_TARGETS]
        for gate in gates:
            if gate in owner:
                raise SystemExit(f"FAIL: {gate} is in both {owner[gate]} and {stage}")
            owner[gate] = stage
        stages[stage] = gates
    return stages


def last_results(path):
    """Each gate's latest result and time."""
    results = {}
    if path.exists():
        for line in path.read_text().splitlines():
            fields = line.split("\t")
            if len(fields) >= 5:
                results[fields[1]] = (fields[3], float(fields[4]))
    return results


def run_gate(root, state, stage, gate, jobs):
    log_path = state / "logs" / f"{gate}.log"
    started = time.monotonic()
    with log_path.open("w") as log:
        status = subprocess.run(["make", "-s", f"-j{jobs}", gate], cwd=root, stdout=log,
                                stderr=subprocess.STDOUT,
                                env=gate_environment(stage)).returncode
    seconds = time.monotonic() - started
    result = "pass" if status == 0 else "fail"
    with (state / "results.tsv").open("a") as results:
        results.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}\t{gate}\t{stage}\t{result}\t"
                      f"{seconds:.1f}\n")
    print(f"{result:4s} {seconds:7.1f}s  {gate}", flush=True)
    return gate, result


def made_goals(database, target, seen=None):
    """The goals the recipes under a target run make for in the runtime-stats
    build, following makes that keep this configuration, or None when one
    makes another configuration."""
    prerequisites, recipes, _, _ = database
    seen = set() if seen is None else seen
    if target in seen:
        return []
    seen.add(target)
    goals = []
    values = prerequisites.get(".VALUES", {})
    for name in closure(prerequisites, target) | {target}:
        # a recipe line continued with a backslash is one command
        for line in recipes.get(name, "").replace("\\\n", " ").splitlines():
            if "$(MAKE)" in line:
                found = stats_goals(line, name, values)
                if found is None:
                    return None
                kind, named = found
                if kind == "stats":
                    goals += named
                else:
                    for goal in named:
                        more = made_goals(database, goal, seen)
                        if more is None:
                            return None
                        goals += more
    return goals


def stats_runs(database, stats_database, gate):
    """The runtime-stats goals a gate makes, followed into the runtime-stats
    build itself, or None when anything on the way makes something else."""
    pending = made_goals(database, gate)
    if pending is None:
        return None
    goals = set()
    while pending:
        goal = pending.pop()
        if goal not in goals:
            goals.add(goal)
            more = made_goals(stats_database(), goal)
            if more is None:
                return None
            pending += more
    return sorted(goals)


def run_stage(root, state, stage, gates, database, stats_database, jobs, last, dry_run):
    prerequisites = database[0]
    if stage == "asymptotic":
        jobs = 1  # growth is measured in time and memory, which other runs disturb
    inside = set()
    for gate in gates:
        inside |= closure(prerequisites, gate)
    gates = [gate for gate in gates if gate not in inside]
    # last time's failures first, then the longest, so none starts last
    gates.sort(key=lambda gate: (last.get(gate, ("", 0.0))[0] != "fail",
                                 -last.get(gate, ("", 0.0))[1]))
    # A gate that makes another configuration runs alone.  A gate that only
    # makes its runtime-stats build runs with the others, once that build's
    # files are made: a make whose files are up to date only reads them.
    stats = {gate: stats_runs(database, stats_database, gate) for gate in gates}
    building = [gate for gate in gates if stats[gate] is None]
    others = [gate for gate in gates if stats[gate] is not None]
    files = sorted(file_prerequisites(database, others))
    stats_targets = sorted({goal for gate in others for goal in stats[gate]})
    stats_files = (sorted(file_prerequisites(stats_database(), stats_targets))
                   if stats_targets else [])
    print(f"STAGE {stage}: {len(gates)} gates, {len(building)} building other "
          f"configurations, {len(others)} at {jobs} at a time", flush=True)
    if dry_run:
        for gate in building + others:
            print(f"  {gate}")
        return [], len(gates)
    started = time.monotonic()
    for settings, needed, name in (((), files, "files"),
                                   (STATS_SETTINGS, stats_files, "stats-files")):
        if needed:
            with (state / "logs" / f"{stage}-{name}.log").open("w") as log:
                subprocess.run(["make", "-s", "-k", f"-j{jobs}", *settings, *needed],
                               cwd=root, stdout=log,
                               stderr=subprocess.STDOUT, env=gate_environment(stage))
    # The gates that build other configurations go one after another in one
    # lane, beside the others: the files those use are already made.
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        lane = pool.submit(lambda: [run_gate(root, state, stage, gate, max(1, jobs - 1))
                                    for gate in building])
        rest = list(pool.map(lambda gate: run_gate(root, state, stage, gate, 1), others))
        outcomes = lane.result() + rest
    failed = [gate for gate, result in outcomes if result == "fail"]
    print(f"STAGE {stage} {'FAIL' if failed else 'PASS'}: {len(outcomes)} gates, "
          f"{len(failed)} failed, {time.monotonic() - started:.0f}s"
          + (": " + " ".join(failed) if failed else ""), flush=True)
    return failed, len(outcomes)


def run_suite(args, root):
    jobs = args.jobs if args.jobs is not None else 3
    if jobs < 1:
        print("FAIL: --jobs must be positive", file=sys.stderr)
        return 2
    state = root / "runtime/main-readiness/suite"
    (state / "logs").mkdir(parents=True, exist_ok=True)
    if args.dry_run:
        return run_stages(args, root, state, jobs)
    with (state / "runner.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("FAIL: a suite run is already running in this checkout", file=sys.stderr)
            return 2
        return run_stages(args, root, state, jobs)


def select_gates(gates, targets, prerequisites, taken):
    """The gates of a stage that named targets select, and the targets that
    select them: a gate named or inside a named aggregate, and a target inside
    a gate, which runs as a gate of its own unless an earlier stage ran it."""
    chosen, matched, inside = [], set(), None
    for target in targets:
        if target in gates:
            found = [target]
        else:
            inner = closure(prerequisites, target)
            found = [gate for gate in gates if gate in inner]
            if not found and target not in taken:
                if inside is None:
                    inside = set().union(*(closure(prerequisites, gate) for gate in gates))
                if target in inside:
                    found = [target]
        if found:
            matched.add(target)
            chosen += [gate for gate in found if gate not in chosen]
    return chosen, matched


def run_stages(args, root, state, jobs):
    database = make_database(root)
    stats_cache = []

    def stats_database():
        if not stats_cache:
            stats_cache.append(make_database(root, STATS_SETTINGS))
        return stats_cache[0]
    stages = stage_gates(database)
    previous = last_results(state / "results.tsv")
    chosen = [args.stage] if args.stage else list(STAGES)
    selected, matched, taken = {}, set(), set()
    for stage in chosen:
        gates = expand_aggregates(stages[stage], database)
        if args.target:
            gates, found = select_gates(gates, args.target, database[0], taken)
            matched |= found
            taken |= set(gates)
        if args.failed:
            gates = [gate for gate in gates if previous.get(gate, ("",))[0] == "fail"]
        selected[stage] = gates
    unmatched = [target for target in args.target if target not in matched]
    if unmatched:
        where = f"the {args.stage} stage" if args.stage else "the suite"
        print(f"FAIL: no gate of {where} is, contains or runs {' '.join(unmatched)}",
              file=sys.stderr)
        return 2
    started = time.monotonic()
    ran = 0
    for stage in chosen:
        if not selected[stage]:
            continue
        failed, count = run_stage(root, state, stage, selected[stage], database,
                                  stats_database, jobs, previous, args.dry_run)
        ran += count
        if failed:
            print(f"SUITE FAIL at the {stage} stage, {time.monotonic() - started:.0f}s; "
                  f"logs in {(state / 'logs').relative_to(root)}")
            return 1
    if not args.dry_run:
        print(f"SUITE PASS: {', '.join(chosen)}, {ran} gates, "
              f"{time.monotonic() - started:.0f}s")
    return 0
