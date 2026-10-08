# Hermes config backup

Version-controlled copy of my [Hermes Agent](https://github.com/NousResearch/hermes-agent) setup.

`hermes/` mirrors these parts of `%LOCALAPPDATA%\hermes`:

- `config.yaml`, `SOUL.md`
- `skills/`, `hooks/`, `memories/`, `plugins/`

API keys (`.env`), login tokens (`auth.json`), databases, logs and sessions are **not** synced.

## Sync

```powershell
.\sync.ps1                      # copy, commit, push
.\sync.ps1 -Message "Add skill"  # custom commit message
```

## Restore on a new machine

Install Hermes, then copy the contents of `hermes/` into `%LOCALAPPDATA%\hermes` and re-add your keys with `hermes setup tools`.
