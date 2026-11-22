# Limitations

What the platform does not allow, and what this version does not do.

## From the Workshop itself

- **No faster than real time.** "Set Slow Motion" accepts 10 to 100 % only (its own description:
  "Only rates up to 100% are allowed"). One step takes about 0.45 s, so a 12-step episode takes
  about 6 s and an early, wandering episode up to 45 s. The "Tracer move speed percent" setting
  (up to 200 %) shortens each step; it also changes the physics you are studying, so log it (the
  RUN line does).
- **No seed.** Random numbers cannot be seeded or read back. Runs repeat in distribution, not draw
  for draw.
- **Two decimals.** The Workshop prints numbers rounded to 0.01. Hyperparameters are logged times
  1000 to get around it; Q-values in the log are rounded.
- **Nothing survives a match restart by itself.** Global variables, the Q-table included, are
  cleared when the match restarts or the lobby closes. Within a match the table persists across
  episodes and across training / evaluation switches. To carry a table into a new match, use
  `tools/warm_start.py` (see `setup.md`): it turns the Workshop Inspector's own export into a build
  that starts from that table. Only the Q-table is carried; counters start again.
- **Match clock.** Skirmish has a 30 minute clock. The script pauses it at match start; it stayed at
  29:59 through every session, the longest of them over an hour (see `verification.md`). A custom
  game still ends when Blizzard's servers close an old lobby (OverPy's compiler cites 16200 s, 4.5
  hours, as the longest a custom game lasts).
- **Arrays hold 1000 items.** That caps the Q-table at 192 states by 5 actions.
- **Server load.** A script that works too hard for too long is shut down by the server. This one
  waits during every move and was never shut down, per-step logging included. If the game ever
  reports a script shutdown, turn off per-step logging first.
- **Workshop text is version-bound.** The compiled text was imported on 2.25.1.0. A later patch can
  rename an action or a setting; recompile with a current OverPy.
- **Bot slots look empty in the lobby.** The Tracer bot sits on Team 1 and the Widowmaker bot on
  Team 2, but the lobby screen shows those slots as EMPTY. Moving a player onto one removes the bot.
  The script checks for this before and after every step and stops with a red status line and a
  `FAIL,botlost` log entry; restart the match to continue. Do not rearrange teams mid-match.
- **A bot can fail to appear.** On 2026-11-21 the Tracer bot did not spawn in two matches in a row
  (Widowmaker did), then spawned at once in every later match. The cause was not found; game speed,
  cell size and a restart after slow motion were each ruled out in the game. The script now tries up
  to five times, a second apart, and says so in red if it still has no bot. Restarting the match
  cleared it both times.
- **A spectating host has no keys.** The lab runs and the dashboard shows, but pause, train/eval,
  algorithm switch, new run and the camera toggle need a hero, so the key hints are blank. Sit on
  either team to use them.

## In this version

- **Timeouts are treated as terminal.** Strictly, a time limit is a truncation and the update
  should still bootstrap from the next state. Here the timeout gets its own penalty and no
  bootstrap, as the brief asked. With the default 100-step limit this rarely matters after the
  first few episodes; Lab 04 looks at what it does.
- **Greedy evaluation can loop.** With learning frozen, a table that is not settled can hold two
  cells whose best moves point at each other, and Tracer paces between them until the step limit.
  Seen in SARSA runs after 115 training episodes at alpha 0.5. It is a property of the learned
  table, not of the evaluation code; more training or a lower alpha removes it.
- **The policy arrows show one context.** The floor arrows show the greedy action for "healthy,
  Blink ready". The half-health and no-Blink halves of the table are in the log's Q lines only.
- **Arrows assume the overhead camera.** Up means toward the edge. From the ground they are
  billboards and the directions do not line up.
- **Blink past the goal counts as the goal.** A Blink that carries Tracer beyond column 11 in row 0
  is clamped to the goal cell.
- **Widowmaker has no cover to shoot around.** Workshop Island is flat. The threat is a range ring
  and a shot clock, not line of sight.
- **Log files buffer, and split when the host moves.** Overwatch writes the log in chunks, so the
  last few seconds can be missing if you read it live. When the host changes team or goes to
  spectate, the game starts a new file and writes the whole match so far into it again; keep only
  the last file of a match. `python -m rllab.sanity` flags a match that is in your data twice.
- **A fall is not a kill.** A fall is detected by height before the game kills Tracer, so the kill
  feed stays empty for falls. "Killed" means Widowmaker's damage killed her.

See `verification.md` for what has and has not been run in the game.
