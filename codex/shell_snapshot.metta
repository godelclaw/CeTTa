; Rust-faithful shell-snapshot pure helper slice.
;
; This ports the pure helper surface from:
; - openai-codex/codex-rs/core/src/shell_snapshot.rs
;
; Covered in this increment:
; - snapshot constants and shell-type discriminants
; - shell snapshot script templates for zsh, bash, sh, and PowerShell
; - snapshot-output preamble stripping
; - snapshot filename session-id parsing, including legacy generation suffixes
;
; Required slice-local deviations from Rust, documented for audit:
; - Rust creates, validates, renames, cleans up, and drops snapshot files through
;   async tokio filesystem/process APIs. This CeTTa slice ports only the pure
;   functions so later runtime work can call the same script/parser logic.
; - Rust returns anyhow::Result/String Option values. This slice exposes the
;   same visible success/error/absence behavior through explicit result
;   constructors and CodexAbsent.

!(import! &self str)

(= (codex:shell-type-zsh)
   "Zsh")

(= (codex:shell-type-bash)
   "Bash")

(= (codex:shell-type-sh)
   "Sh")

(= (codex:shell-type-powershell)
   "PowerShell")

(= (codex:shell-type-cmd)
   "Cmd")

(= (codex:shell-snapshot-dir)
   "shell_snapshots")

(= (codex:shell-snapshot-timeout-secs)
   10)

(= (codex:shell-snapshot-retention-secs)
   259200)

(= (codex:shell-snapshot-excluded-export-vars)
   ("PWD" "OLDPWD"))

(= (codex:shell-snapshot-excluded-exports-regex)
   "PWD|OLDPWD")

(= (codex:shell-snapshot-preamble-marker)
   "# Snapshot file")

(= (codex:shell-snapshot-ok $value)
   (CodexShellSnapshotOk $value))

(= (codex:shell-snapshot-err $message)
   (CodexShellSnapshotErr $message))

(= (codex:shell-snapshot-result-value (CodexShellSnapshotOk $value))
   $value)

(= (codex:shell-snapshot-result-error (CodexShellSnapshotErr $message))
   $message)

(= (codex:shell-snapshot-extension $shell-type)
   (if (== $shell-type (codex:shell-type-powershell))
       "ps1"
       "sh"))

(= (codex:is-shell-snapshot-write-supported $shell-type)
   (if (== $shell-type (codex:shell-type-powershell))
       False
       (if (== $shell-type (codex:shell-type-cmd))
           False
           True)))

(= (codex:strip-shell-snapshot-preamble $snapshot)
   (let $marker (codex:shell-snapshot-preamble-marker)
     (let $start (str-find $snapshot $marker)
       (if (== $start Empty)
           (codex:shell-snapshot-err
             (str-concat "Snapshot output missing marker " $marker))
           (codex:shell-snapshot-ok
             (str-slice $snapshot $start (str-length $snapshot)))))))

(= (codex:shell-snapshot-parts-last ($only))
   $only)

(= (codex:shell-snapshot-parts-last $parts)
   (let ($head $tail) (decons-atom $parts)
     (codex:shell-snapshot-parts-last $tail)))

(= (codex:shell-snapshot-parts-init ($only))
   ())

(= (codex:shell-snapshot-parts-init $parts)
   (let ($head $tail) (decons-atom $parts)
     (let $rest (eval (codex:shell-snapshot-parts-init $tail))
       (cons-atom $head $rest))))

(= (codex:shell-snapshot-stem-session-id $stem)
   (let $parts (str-split "." $stem)
     (car-atom $parts)))

(= (codex:shell-snapshot-session-id-from-file-name $file-name)
   (let $parts (str-split "." $file-name)
     (if (== (size-atom $parts) 1)
         CodexAbsent
         (let $extension (codex:shell-snapshot-parts-last $parts)
           (let $stem (str-join "." (codex:shell-snapshot-parts-init $parts))
             (if (== $extension "sh")
                 (codex:shell-snapshot-stem-session-id $stem)
                 (if (== $extension "ps1")
                     (codex:shell-snapshot-stem-session-id $stem)
                     (if (str-starts-with? $extension "tmp-")
                         $stem
                         CodexAbsent))))))))

(= (codex:zsh-snapshot-script)
   "if [[ -n \"$ZDOTDIR\" ]]; then
  rc=\"$ZDOTDIR/.zshrc\"
else
  rc=\"$HOME/.zshrc\"
fi
[[ -r \"$rc\" ]] && . \"$rc\"
print '# Snapshot file'
print '# Unset all aliases to avoid conflicts with functions'
print 'unalias -a 2>/dev/null || true'
print '# Functions'
functions
print ''
setopt_count=$(setopt | wc -l | tr -d ' ')
print \"# setopts $setopt_count\"
setopt | sed 's/^/setopt /'
print ''
alias_count=$(alias -L | wc -l | tr -d ' ')
print \"# aliases $alias_count\"
alias -L
print ''
export_lines=$(export -p | awk '
/^(export|declare -x|typeset -x) / {
  line=$0
  name=line
  sub(/^(export|declare -x|typeset -x) /, \"\", name)
  sub(/=.*/, \"\", name)
  if (name ~ /^(PWD|OLDPWD)$/) {
    next
  }
  if (name ~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
    print line
  }
}')
export_count=$(printf '%s\n' \"$export_lines\" | sed '/^$/d' | wc -l | tr -d ' ')
print \"# exports $export_count\"
if [[ -n \"$export_lines\" ]]; then
  print -r -- \"$export_lines\"
fi
")

(= (codex:bash-snapshot-script)
   "if [ -z \"$BASH_ENV\" ] && [ -r \"$HOME/.bashrc\" ]; then
  . \"$HOME/.bashrc\"
fi
echo '# Snapshot file'
echo '# Unset all aliases to avoid conflicts with functions'
unalias -a 2>/dev/null || true
echo '# Functions'
declare -f
echo ''
bash_opts=$(set -o | awk '$2==\"on\"{print $1}')
bash_opt_count=$(printf '%s\n' \"$bash_opts\" | sed '/^$/d' | wc -l | tr -d ' ')
echo \"# setopts $bash_opt_count\"
if [ -n \"$bash_opts\" ]; then
  printf 'set -o %s\n' $bash_opts
fi
echo ''
alias_count=$(alias -p | wc -l | tr -d ' ')
echo \"# aliases $alias_count\"
alias -p
echo ''
export_lines=$(
  while IFS= read -r name; do
    if [[ \"$name\" =~ ^(PWD|OLDPWD)$ ]]; then
      continue
    fi
    if [[ ! \"$name\" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
      continue
    fi
    declare -xp \"$name\" 2>/dev/null || true
  done < <(compgen -e)
)
export_count=$(printf '%s\n' \"$export_lines\" | sed '/^$/d' | wc -l | tr -d ' ')
echo \"# exports $export_count\"
if [ -n \"$export_lines\" ]; then
  printf '%s\n' \"$export_lines\"
fi
")

(= (codex:sh-snapshot-script)
   "if [ -n \"$ENV\" ] && [ -r \"$ENV\" ]; then
  . \"$ENV\"
fi
echo '# Snapshot file'
echo '# Unset all aliases to avoid conflicts with functions'
unalias -a 2>/dev/null || true
echo '# Functions'
if command -v typeset >/dev/null 2>&1; then
  typeset -f
elif command -v declare >/dev/null 2>&1; then
  declare -f
fi
echo ''
if set -o >/dev/null 2>&1; then
  sh_opts=$(set -o | awk '$2==\"on\"{print $1}')
  sh_opt_count=$(printf '%s\n' \"$sh_opts\" | sed '/^$/d' | wc -l | tr -d ' ')
  echo \"# setopts $sh_opt_count\"
  if [ -n \"$sh_opts\" ]; then
    printf 'set -o %s\n' $sh_opts
  fi
else
  echo '# setopts 0'
fi
echo ''
if alias >/dev/null 2>&1; then
  alias_count=$(alias | wc -l | tr -d ' ')
  echo \"# aliases $alias_count\"
  alias
  echo ''
else
  echo '# aliases 0'
fi
if export -p >/dev/null 2>&1; then
  export_lines=$(export -p | awk '
/^(export|declare -x|typeset -x) / {
  line=$0
  name=line
  sub(/^(export|declare -x|typeset -x) /, \"\", name)
  sub(/=.*/, \"\", name)
  if (name ~ /^(PWD|OLDPWD)$/) {
    next
  }
  if (name ~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
    print line
  }
}')
  export_count=$(printf '%s\n' \"$export_lines\" | sed '/^$/d' | wc -l | tr -d ' ')
  echo \"# exports $export_count\"
  if [ -n \"$export_lines\" ]; then
    printf '%s\n' \"$export_lines\"
  fi
else
  export_count=$(env | sort | awk -F= '$1 ~ /^[A-Za-z_][A-Za-z0-9_]*$/ { count++ } END { print count }')
  echo \"# exports $export_count\"
  env | sort | while IFS='=' read -r key value; do
    case \"$key\" in
      \"\"|[0-9]*|*[!A-Za-z0-9_]*|PWD|OLDPWD) continue ;;
    esac
    escaped=$(printf \"%s\" \"$value\" | sed \"s/'/'\\\"'\\\"'/g\")
    printf \"export %s='%s'\n\" \"$key\" \"$escaped\"
  done
fi
")

(= (codex:powershell-snapshot-script)
   "$ErrorActionPreference = 'Stop'
Write-Output '# Snapshot file'
Write-Output '# Unset all aliases to avoid conflicts with functions'
Write-Output 'Remove-Item Alias:* -ErrorAction SilentlyContinue'
Write-Output '# Functions'
Get-ChildItem Function: | ForEach-Object {
    \"function {0} {{`n{1}`n}}\" -f $_.Name, $_.Definition
}
Write-Output ''
$aliases = Get-Alias
Write-Output (\"# aliases \" + $aliases.Count)
$aliases | ForEach-Object {
    \"Set-Alias -Name {0} -Value {1}\" -f $_.Name, $_.Definition
}
Write-Output ''
$envVars = Get-ChildItem Env:
Write-Output (\"# exports \" + $envVars.Count)
$envVars | ForEach-Object {
    $escaped = $_.Value -replace \"'\", \"''\"
    \"`$env:{0}='{1}'\" -f $_.Name, $escaped
}
")

(= (codex:shell-snapshot-script $shell-type)
   (if (== $shell-type (codex:shell-type-zsh))
       (codex:zsh-snapshot-script)
       (if (== $shell-type (codex:shell-type-bash))
           (codex:bash-snapshot-script)
           (if (== $shell-type (codex:shell-type-sh))
               (codex:sh-snapshot-script)
               (if (== $shell-type (codex:shell-type-powershell))
                   (codex:powershell-snapshot-script)
                   CodexAbsent)))))
