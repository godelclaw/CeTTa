#!/usr/bin/env python3
"""Conversation encoding grows linearly with the conversation.

Each protocol's conversation is built newest first and put in order once,
so encoding n, 4n and 16n messages takes about 4x per step. An encoder
that walks or copies the conversation built so far for each message takes
about 16x per step. Three shapes are timed in PeTTa, the dialect agents
run: an agent's working conversation (a question, a reply with two tool
calls, their two results), one reply with n tool calls answered by n
consecutive tool results (one Anthropic turn), and n leading system
messages. The negative control appends each message's items to the end of
the items so far, as the Responses encoder once did; the check must reject
it. Times are the fastest of three in-process encodes, so process start,
library import and page faults do not count."""
import json
import os
import re
import subprocess
import sys
import tempfile

SIZES = (100, 400, 1600)
CONTROL_SIZES = (100, 400)
LINEAR_STEP = 8.0   # a 4x step: linear is about 4, quadratic about 16
REPEATS = 3


def agent(n):
    messages, i = [{"role": "system", "content": "fixture"}], 0
    while len(messages) < n:
        phase, i = i % 4, i + 1
        if phase == 0:
            messages.append({"role": "user", "content": f"question {i} λ"})
        elif phase == 1:
            messages.append({"role": "assistant", "content": f"reply {i}", "tool_calls": [
                {"id": f"c{i}a", "type": "function", "function": {"name": "f", "arguments": "{\"x\":1}"}},
                {"id": f"c{i}b", "type": "function", "function": {"name": "g", "arguments": "{}"}}]})
        else:
            suffix = "a" if phase == 2 else "b"
            messages.append({"role": "tool", "tool_call_id": f"c{i - phase + 1}{suffix}",
                             "content": f"result {i}"})
    return messages[:n]


def results(n):
    calls = [{"id": f"c{k}", "type": "function", "function": {"name": "f", "arguments": "{}"}}
             for k in range(n - 2)]
    return ([{"role": "user", "content": "go"}, {"role": "assistant", "content": "", "tool_calls": calls}]
            + [{"role": "tool", "tool_call_id": f"c{k}", "content": f"r{k}"} for k in range(n - 2)])


def system(n):
    return [{"role": "system", "content": f"rule {k}"} for k in range(n - 1)] + [
        {"role": "user", "content": "go"}]


SHAPES = {"agent": agent, "results": results, "system": system}


def anthropic_turns(messages):
    """Adjacent messages of one Anthropic role (a tool result is a user's) are one turn."""
    roles = ["user" if m["role"] == "tool" else m["role"] for m in messages if m["role"] != "system"]
    return sum(1 for k, role in enumerate(roles) if k == 0 or roles[k - 1] != role)


def response_items(messages):
    return sum((1 if m.get("content") else 0) + len(m.get("tool_calls", ())) if m["role"] != "tool" else 1
               for m in messages if m["role"] != "system")


def expected(protocol, shape, n):
    messages = SHAPES[shape](n)
    return anthropic_turns(messages) if protocol == "anthropic" else response_items(messages)


CONTROL = """
(= (control:items $messages $items)
   (if (== $messages ()) $items
     (let* (($head (car-atom $messages)) ($tail (cdr-atom $messages))
            ($new (llm:v1:response-message $head (JsonString "merge-system-developer")))
            ($next (llm:v1:append $items $new)))
       (control:items $tail $next))))
(= (control:run $text)
   (let* (($request (llm:v1:parse $text)) ($json (llm:v1:get $request "messages"))
          ($messages (llm:v1:array $json)) ($items (control:items $messages ())))
     (size-atom $items)))
"""


def program(library, protocol, text, control):
    key = "messages" if protocol == "anthropic" else "input"
    timed = "(control:run $t)" if control else f'(llm:v1:encode "{protocol}" $t)'
    shown = ("$o" if control else
             "(case $o (((llm:v1:ok (llm:v1:encoded $p $b)) (let* (($w (llm:v1:parse $b))"
             f' ($k (llm:v1:get $w "{key}")) ($a (llm:v1:array $k))) (size-atom $a)))'
             " ((llm:v1:error $c) $c)))")
    body = (f'!(import! &self "{library}")\n!(import! &self (library system))\n'
            + (CONTROL if control else "") +
            f"(= (growth:time $t) (let* (($s (system:monotonic-ns)) ($o {timed}) ($e (system:monotonic-ns))"
            f" ($d (- $e $s)) ($r {shown})) (growth:sample $d $r)))\n")
    return body + "".join(f"!(let $t {json.dumps(text)} (growth:time $t))\n" for _ in range(REPEATS))


def measure(binary, library, directory, protocol, shape, n, control=False):
    request = {"model": "m", "max_tokens": 64, "messages": SHAPES[shape](n),
               "role_policy": "merge-system-developer"}
    path = os.path.join(directory, f"{protocol}-{shape}-{n}.metta")
    with open(path, "w") as handle:
        handle.write(program(library, protocol, json.dumps(request), control))
    proc = subprocess.run([binary, "--lang", "petta", path], capture_output=True, text=True, timeout=900)
    samples = re.findall(r"\(growth:sample (\d+) ([^()\s]+)\)", proc.stdout)
    if proc.returncode != 0 or len(samples) != REPEATS:
        sys.exit(f"FAIL: {protocol} {shape} at {n}: no samples\n{proc.stdout[-400:]}{proc.stderr[-400:]}")
    return min(int(ns) for ns, _ in samples), samples[0][1]


def turns(shown):
    return int(shown) if shown.isdigit() else None


def steps(values):
    return [larger / smaller for smaller, larger in zip(values, values[1:])]


def main():
    binary = os.path.abspath(sys.argv[1])
    root = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    library = sys.argv[2] if len(sys.argv) > 2 else os.path.join(root, "lib", "petta", "llm.metta")
    worst = 0.0
    with tempfile.TemporaryDirectory(prefix="llm-growth-") as directory:
        for protocol in ("responses", "anthropic"):
            for shape in SHAPES:
                times = []
                for n in SIZES:
                    elapsed, shown = measure(binary, library, directory, protocol, shape, n)
                    count = turns(shown)
                    if count != expected(protocol, shape, n):
                        sys.exit(f"FAIL: {protocol} {shape} at {n} encoded {count} turns ({shown[:120]})")
                    times.append(elapsed)
                ratios = steps(times)
                worst = max(worst, *ratios)
                print(f"{protocol} {shape}: " + " ".join(f"{t / 1e6:.1f}ms" for t in times)
                      + "  steps " + " ".join(f"{r:.2f}" for r in ratios))
                if max(ratios) > LINEAR_STEP:
                    sys.exit(f"FAIL: {protocol} {shape} grows faster than linear")
        control = [measure(binary, library, directory, "responses", "agent", n, control=True)[0]
                   for n in CONTROL_SIZES]
        ratio = steps(control)[0]
        print(f"control (append per message): " + " ".join(f"{t / 1e6:.1f}ms" for t in control)
              + f"  step {ratio:.2f}")
        if ratio <= LINEAR_STEP:
            sys.exit("FAIL: the check accepted the quadratic control")
    print(f"(LlmConversationGrowthV1Summary {len(SHAPES) * 2} {worst:.2f})")


if __name__ == "__main__":
    main()
