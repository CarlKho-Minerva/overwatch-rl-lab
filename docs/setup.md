# Setup: get the lab running in Overwatch

Everything below was done on Overwatch 2.25.1.0 (Steam, Windows) on 2026-11-21.

## 1. Turn on the log file (once)

In Overwatch: **Options > Gameplay > General > Custom Games - Workshop**

- Enable Workshop Inspector: **On**
- Enable Workshop Inspector Log File: **On**

With the second switch on, the game writes every line the lab logs to
`Documents\Overwatch\Workshop\Log-<date>-<time>.txt` (on this PC that is
`C:\Users\<you>\OneDrive\Documents\Overwatch\Workshop\`). A new file starts with each match.

## 2. Copy the script

Open `workshop/compiled/overwatch-rl-lab.txt`, select all, copy.

From PowerShell:

```powershell
Get-Content -Raw workshop\compiled\overwatch-rl-lab.txt -Encoding UTF8 | Set-Clipboard
```

## 3. Make a private lobby and paste

1. **Play > More > Custom Games > Create**.
2. Change the dropdown under the lobby name from Friends to **Invite Only**.
3. Click **Settings**. In the Summary panel an orange **paste** button appears when the clipboard
   holds valid settings. If it is missing, press Esc and click Settings again: the game only looks at
   the clipboard when this screen opens.
4. Click paste, then **Confirm**. The mode name becomes "Overwatch RL Lab" and the map becomes
   Workshop Island.
5. Optional: after the paste a seventh tile, **Workshop Settings** (orange hammer, below Maps; scroll
   down), appears on the Settings screen. It holds every parameter in six groups: experiment,
   learning, rewards, arena, Widowmaker, logging. Defaults are a SARSA cliff walk. The separate
   Workshop tile is the script editor; you do not need it.
6. Leave at least one free slot on each team. The script puts a Tracer bot on Team 1 and a
   Widowmaker bot on Team 2. Their slots keep showing EMPTY in the lobby, so once a match is
   running do not move anyone between teams: a player dropped onto a bot's slot removes the bot,
   and the script stops with a red status line.
7. Press Esc, then **Start**. Pick any hero. You can sit on either team. A spectating host sees
   the dashboard but has no keys.

About 6 seconds after the match starts the script has measured the island, spawned both bots and
timed Tracer's run. The status line on the left reads `READY` and episodes begin.

If the status line is red instead, it says why (not Workshop Island, a bot did not appear, Tracer
did not move, a bot left the match). Esc > Show Lobby > Restart Match clears the bot problems.

## 4. Controls while it runs

The host's hero is phased out, so the bots cannot hit or block you.

| Key (default binding) | What it does |
|---|---|
| Interact (F) | Pause or resume |
| Reload (R) | Switch between training and greedy evaluation, from the next episode |
| Ability 2 (E) | Switch SARSA and Q-learning and start a new run (clears the Q-table) |
| Hold Ultimate (Q) 1 s | Start a new run with the same algorithm (clears the Q-table) |
| Quick Melee (V) | Overhead camera on or off |
| Crouch + Primary Fire | epsilon down by 0.05 |
| Crouch + Secondary Fire | epsilon up by 0.05 |

A normal key press is enough. (In testing, a scripted tap lasting a few milliseconds was missed and
a 150 ms press worked.) On this PC the epsilon keys showed as Mouse 5 + left / right click, because
Crouch is bound to Mouse 5; the hint on the right of the screen shows your own bindings.

To load a different build mid-session: Esc > **Show Lobby** > Settings > paste > Confirm > Esc >
**Restart Match**. A restart clears the Q-table (see `limitations.md`). To change a Workshop Setting
mid-session it is the same path: Show Lobby > Settings > Workshop Settings, then Restart Match.

## 5. Keep a learned table across a restart

A restart clears everything the agent has learned. To carry the Q-table into a new match:

1. In the match you want to keep: Esc > **Open Workshop Inspector**. Under the timeline is a row of
   icons; click the last one, marked **(x)**. It copies every variable to the clipboard.
2. In a terminal, from the repository folder: `.venv\Scripts\python tools\warm_start.py`. It reads
   the clipboard, writes a build that starts from that table, and puts the build on the clipboard.
3. Esc > Show Lobby > Settings > paste > Confirm > Esc > Restart Match.

The new match logs a `WARM` line and the table it started from. Only the Q-table is carried:
counters, the algorithm and every setting come from the menu as usual.

## 6. Rebuild after editing the source

```powershell
npm install        # once
npm run build      # compiles workshop/*.opy to workshop/compiled/*.txt, fails on any warning
npm test           # build + Python tests (needs the Python environment below)
```

Python environment for the tests and the notebook:

```powershell
python -m venv .venv
.venv\Scripts\python -m pip install numpy pandas matplotlib pytest nbclient nbformat ipykernel
.venv\Scripts\python -m pytest -q
```

(`uv sync` also works where Windows allows uv's Python shim. On this PC an application-control
policy blocked it, so the plain `venv` route is the one that was run.)

## 7. Get your data out

After a session, copy the newest file from `Documents\Overwatch\Workshop\` into `data/logs/`, then:

```powershell
cd analysis
..\.venv\Scripts\python -m rllab.sanity ..\data\logs\<file>.txt     # real play, and each match only once?
..\.venv\Scripts\python -m rllab.replay ..\data\logs\<file>.txt     # checks the game's updates (needs per-step logging)
..\.venv\Scripts\python -m rllab.plots  ..\data\logs\<file>.txt --out figures
```
