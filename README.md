TerraBlocks Godot v1.50
=======================

Target engine
-------------
- Godot 4.7
- Portrait viewport: 540x960
- GL Compatibility / Web-friendly

v1.50: Web/Safari BGM start fix
-------------------------------
- Fixed the v1.44-v1.47 BGM regression without changing gameplay or UI.
- Web builds no longer call BGM `play()` during boot.
- On Web, BGM explicitly uses Godot Sample/WebAudio playback and starts directly from the first genuine mouse/touch press.
- The BGM WAV is loop-enabled and loops internally after that single start; TerraBlocks does not restart it every ~6 seconds.
- Removed the `finished -> play()` fallback that could recreate the repeated-play pattern we were avoiding on iOS Safari.
- If Safari suspends/stops BGM after a tab/app transition, the next genuine user gesture resumes it safely.
- Native/desktop builds still start BGM normally at startup.
- Turning BGM ON from Settings starts it immediately because that toggle tap itself is a valid user gesture.
- Corrected project/version metadata to 1.48.

Unchanged
---------
- v1.47 background transparency and Settings page.
- Hammer / Rotate-Mirror / Reset mechanics.
- Scoring, combos, Stats, save/continue, world-rank client, Test Mode diagnostics.
- Low-processor / Safari thermal optimizations.


## v1.50 BGM fix
Uses a scene-level AudioStreamPlayer for BGM, matching the configuration that successfully produced audio during testing.


## v1.50 BGM stability
- Keeps the proven scene-level BGM player.
- Forces AudioStreamWAV loop mode at runtime.
- Restarts BGM on the finished signal.
- Adds a 1-second watchdog that recovers unexpected playback stops.
- Web watchdog only activates after the first user gesture.


## v1.50 parser hotfix
- Removed an invalid `AudioStream is AudioStreamWAV` static type test that Godot 4.7 rejects.
- Keeps the scene-level BGM player, finished-signal recovery, and 1-second watchdog.
