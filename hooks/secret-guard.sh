#!/usr/bin/env bash
# Hook: UserPromptSubmit. Blocks a prompt holding a credential before the model
# sees it, so it never reaches a transcript or anything built from one.
# Patterns match light-labs' claude_results.SECRETS; keep the two in step.
# Exit 2 drops the prompt and shows the message to the user.
#
# Not covered: `!` commands, which skip this hook. Store secrets with
# `security add-generic-password -U -s <service> -a <account> -w` and no value,
# which prompts for it.

input=$(cat)

python3 -I -c '
import json, re, sys
prompt = json.loads(sys.argv[1]).get("prompt", "")
SECRETS = [
    ("keychain password", r"add-generic-password[^\n]{0,200}?\s-w\s+(?:\x27[^\x27\[$][^\x27]*\x27|\"[^\"\[$][^\"]*\"|[^\s\x27\"\\\[$][^\s\x27\"\\]*)"),
    ("Telegram bot token", r"\b[0-9]{8,10}:AA[A-Za-z0-9_-]{30,}"),
    ("Anthropic key", r"sk-ant-[A-Za-z0-9_-]{20,}"),
    ("GitHub token", r"\bgh[pousr]_[A-Za-z0-9]{30,}|\bgithub_pat_[A-Za-z0-9_]{40,}"),
    ("AWS key", r"\bAKIA[0-9A-Z]{16}\b"),
    ("Google client secret", r"GOCSPX-[A-Za-z0-9_-]{20,}"),
    ("48-hex token", r"\b[0-9a-f]{48}\b"),
]
found = [kind for kind, p in SECRETS if re.search(p, prompt)]
if found:
    print(f"[secret-guard] Prompt blocked ({found[0]}). Store it with "
          "`security add-generic-password -U -s <service> -a <account> -w` (no value; it prompts), "
          "then refer to the service name.", file=sys.stderr)
    sys.exit(2)
' "$input"
