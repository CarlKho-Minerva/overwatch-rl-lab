# ---------------------------------------------------------------------------
# Calibration. Nothing about the island is hard-coded.
#   1. Floor height: a ray cast straight down through the map origin. If it hits
#      nothing, the host's standing position is used instead.
#   2. Edges: for each of +x, -x, +z, -z a binary search over downward rays finds
#      where the floor ends.
#   3. Speed: after the bots spawn, Tracer runs for a measured interval, which
#      gives her real run speed and how far she coasts after the throttle stops
#      (see arena.opy).
# calStage: 0 = measuring, 1 = geometry known, 2 = ready, -1 = failed (see calMsg)
# ---------------------------------------------------------------------------

macro onPlatform(p):
    abs(raycast(p + vect(0, 2, 0), p - vect(0, 2, 0), null, null, false).getHitPosition().y - floorY) < 0.3

def probeEdge():
    @Name "Calibration: find one edge (binary search on downward rays)"
    probeLo = 0
    probeHi = 4
    while onPlatform(isleCenter + probeDir * probeHi) and probeHi < 512:
        probeLo = probeHi
        probeHi *= 2
    for i in range(16):
        probeMid = (probeLo + probeHi) / 2
        if onPlatform(isleCenter + probeDir * probeMid):
            probeLo = probeMid
        else:
            probeHi = probeMid
    wait()

rule "Calibration: measure the island":
    # Skirmish has a 30 minute match clock. Freeze it so a long run is not cut off.
    pauseMatchTime()
    wait(1)
    isleCenter = raycast(vect(0, 60, 0), vect(0, -60, 0), null, null, false).getHitPosition()
    if isleCenter.y < -59:
        calMsg = "no floor under the map origin: stand on the island (host)"
        waitUntil(hostPlayer.hasSpawned() and hostPlayer.isOnGround(), 99999)
        wait(0.5)
        isleCenter = hostPlayer.getPosition()
    floorY = isleCenter.y
    probeDir = vect(1, 0, 0)
    probeEdge()
    edgeXMax = isleCenter.x + probeLo
    probeDir = vect(-1, 0, 0)
    probeEdge()
    edgeXMin = isleCenter.x - probeLo
    probeDir = vect(0, 0, 1)
    probeEdge()
    edgeZMax = isleCenter.z + probeLo
    probeDir = vect(0, 0, -1)
    probeEdge()
    edgeZMin = isleCenter.z - probeLo
    if edgeXMax - edgeXMin < 22 or edgeZMax - edgeZMin < 14 or edgeXMax - edgeXMin > 500:
        calStage = -1
        calMsg = "island measurement looks wrong (see calibration HUD). Is the map Workshop Island?"
        return
    layoutArena()
    calStage = 1
    calMsg = "spawning bots"
