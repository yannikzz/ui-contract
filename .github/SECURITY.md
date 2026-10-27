# Security

## Reporting a vulnerability

Please **do not open a public issue.** Report it privately through GitHub instead:
[report a vulnerability](https://github.com/yannikzz/ui-contract/security/advisories/new).

Two people maintain this project in their spare time. We will reply as soon as we can and work out the fix and its disclosure with you inside the advisory.

## What counts

ui-contract is mostly prose, but some of it runs, and some of it runs in your project rather than ours:

- `install.sh` — the README pipes it straight into `sh`.
- The script and component templates the skills copy into your project (the `assets/` folders inside `skills/`), such as the audit and colour-check scripts.
- Skill instructions that would lead an agent to run a command you did not ask for, write outside your project, or send data anywhere.

## Supported versions

Both install paths — the plugin marketplace and `install.sh` — install from `main`, so a fix lands on `main` and ships in the next release. Older releases are not patched.
