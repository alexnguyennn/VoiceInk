# VoiceInk local port notes

- Read `.opencode/skills/voiceink-upgrade-port/SKILL.md` and its `assets/port-runs.md` before syncing local build/install changes onto another upstream tag. The log records why the v2.1 port kept upstream `LOCAL_BUILD` licensed behavior instead of the prior 999-day trial override.
- Original checkout's v2.13 uncommitted port was preserved before switching to `feature/custom-build-update-v2.1` as git stash commit `110007fe682838acbaf7c789bb778305ed065943`. Do not drop it until the archived changes are no longer needed.
