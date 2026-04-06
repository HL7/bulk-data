# Project Notes

## Validation commands

- Do not run the full IG Publisher build (`./_genonce.sh`, `./_build.sh`, or equivalent publisher wrappers) from Codex in this repo. In this environment, sandbox and network restrictions cause those builds to fail noisily and produce low-signal results.
- `sushi` is the allowed local validation step for Codex work in this project.
- If publisher-level validation is needed, leave that step to the user outside the sandbox rather than running it from Codex.
