# Calibration: how the script finds the island

No coordinate of Workshop Island is written into the script. Each match measures the map again.

## What the script does at match start

1. **Floor.** It casts a ray straight down through the map origin, from 60 m above to 60 m below
   (the Workshop's ray cast, which reports where a line first hits the world). The hit height is the
   floor. If the ray hits nothing, the status line asks the host to stand on the island and the
   host's position is used instead.
2. **Edges.** For each of the four directions (+x, -x, +z, -z) it does a binary search: it casts
   short downward rays at growing distances from the centre until one misses the floor, then halves
   the gap 16 times. The result is the edge position to well under a centimetre.
3. **Sanity check.** If the island comes out narrower than 22 m, shallower than 14 m or wider than
   500 m, the script stops with a red status line instead of running on a wrong map.
4. **Grid.** 12 columns along the -z edge, centred on x, and 4 rows going inland. The first row
   starts "gap between grid and island edge" (default 0.5 m) in from the edge.
5. **Tracer's speed.** After the bots spawn, Tracer runs along the grid for 0.8 s between two
   timestamps. Distance over time is her run speed. When the throttle stops, how far she still
   slides is the coast distance. A speed under 1 m/s stops the script ("Tracer did not move under
   throttle control").

## What it measured (Overwatch 2.25.1.0, 2026-11-21, three matches)

| Quantity | Value |
|---|---|
| Island, x | -20 to 20 m |
| Island, z | -20 to 20 m |
| Floor height | 0 |
| Cell size used | 2 m |
| Tracer run speed at 100 % | 5.98 m/s |
| Coast distance after the throttle stops | 0.25 m |
| Fixed-duration move length (cell / speed) | 0.33 s |

In words: the island is a 40 m square centred on the origin, and Tracer covers one 2 m cell in a
third of a second.

These values are printed on the calibration HUD (left side, grey) and written to the log as the
`CAL` line at the start of every run, so each data file carries its own measurement.

## Checking it by hand

The calibration HUD also shows `HOST AT (x, y, z)`. Turn the overhead camera off (Quick Melee),
walk to an edge and compare your x or z with the HUD's island line. Standing at the lip of the
-z edge you should read z close to -20.

## Layout that follows from the measurement

```
                 -z  (the real edge: the red line; beyond it is the drop)
   col:  0    1    2    3    4    5    6    7    8    9   10   11
row 0  [ S ][   ][   ][   ][   ][   ][   ][   ][   ][   ][   ][ G ]
row 1  [   ][   ][   ][   ][   ][   ][   ][   ][   ][   ][   ][   ]
row 2  [   ][   ][   ][   ][   ][   ][   ][   ][   ][   ][   ][   ]
row 3  [   ][   ][   ][   ][   ][   ][   ][   ][   ][   ][   ][   ]
                 +z  (inland; Widowmaker stands 6 m behind row 3)
  -x  <--------------------------------------------------------->  +x
```

State index = row x 12 + column. Start is state 0, goal is state 11.
