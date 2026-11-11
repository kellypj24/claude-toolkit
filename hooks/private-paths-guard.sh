#!/usr/bin/env bash
# Hook: PreToolUse (Bash). Blocks a shell command that names a private folder, runs
# inside one, or matches a listed command, so its output never enters the session.
#
# Config: ~/.claude/private-paths, one entry per line, `#` comments:
#   ~/.some-private-folder          a folder (also matched as $HOME/..., /Users/.../...)
#   cmd:tool\s+dump                 a Python regex over the command
# No config file: the hook does nothing.
#
# Pair each folder with `permissions.deny` rules (`Read(~/folder/**)`,
# `Edit(~/folder/**)`) for the file tools. A speed bump for an honest session, not a
# sandbox: a script that builds the path at run time gets past it. `!` commands skip it.
# Exit 2 blocks the call and shows the message to the model.

input=$(cat)
config="${PRIVATE_PATHS_FILE:-$HOME/.claude/private-paths}"
[ -f "$config" ] || exit 0

# shellcheck disable=SC2016
python3 -I -c '
import json, os, re, sys

data = json.loads(sys.argv[1])
cmd = (data.get("tool_input") or {}).get("command") or ""
cwd = data.get("cwd") or ""
home = os.path.expanduser("~")

def block(why):
    print(f"[private-paths-guard] Blocked: {why}. It is listed in ~/.claude/private-paths; "
          "its contents stay out of this session. Ask the user to run it themselves.",
          file=sys.stderr)
    sys.exit(2)

for line in open(sys.argv[2]):
    entry = line.split("#", 1)[0].strip()
    if not entry:
        continue
    if entry.startswith("cmd:"):
        if re.search(entry[4:], cmd):
            block("this command prints private data")
        continue
    path = os.path.abspath(os.path.expanduser(entry))
    real = os.path.realpath(path)
    spellings = {path, real}
    for p in (path, real):
        if p.startswith(home + os.sep):
            rest = p[len(home):]
            spellings |= {"~" + rest, "$HOME" + rest, "${HOME}" + rest}
    for s in spellings:
        if re.search(re.escape(s) + r"(?![\w.-])", cmd):
            block(f"the command names {entry}")
    here = os.path.realpath(cwd) if cwd else ""
    if here and (here == real or here.startswith(real + os.sep)):
        block(f"the working directory is inside {entry}")
' "$input" "$config"
