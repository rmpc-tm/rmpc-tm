enum ChallengeModes {
    Author60,
    Gold60
}

int64 ModeTimer(ChallengeModes mode) {
    switch(mode) {
        case ChallengeModes::Author60:
            return ONE_HOUR;
        case ChallengeModes::Gold60:
            return ONE_HOUR;
    }
}


class Challenge {
    // config
    int64 startedAt = 0;
    ChallengeModes mode;

    // game status
    bool isRunning = false;
    bool isPaused = false;
    bool isFinished = false;
    bool isLoading = false;

    // global counters
    int64 timer = 0;
    int64 score = 0;
    int64 totalGameTime = 0;

    // map timers
    int64 mapTimer = 0;

    // stats

    

    Challenge() {};
    Challenge(ChallengeModes gameMode) {
        mode = gameMode;
    }

    void Start() {
        startedAt = Time::Now;
        timer = ModeTimer(mode) - 1; // sacrifice 1ms for less digits
        print("Starting new game: " + mode + " (" + timer + ")");
        SwitchMap();
    }


    // Main challenge loop to be called each tick.
    void Step(int64 delta) {
        if (!isRunning) return;
        if (isPaused) return;

        // menu, etc...
        if (IsAutoPaused()) return;

        // tick
        if (ReduceTimer(delta)) {
            FinishGame();
        }
        totalGameTime += delta;

        // detect map change
    }

    void DetectMapChange() {
        if (!isLoading) {
            return;
        }
        auto app = cast<CTrackMania>(GetApp());
        auto map = app.RootMap;
        if(map !is null) {
            if (currentMap is null || currentMap.uid != map.MapInfo.MapUid) {
                currentMap = MapInfo(map.MapInfo.Name,
                                    map.MapInfo.MapUid,
                                    map.TMObjective_AuthorTime,
                                    map.TMObjective_GoldTime,
                                    map.TMObjective_SilverTime,
                                    map.TMObjective_BronzeTime
                            );
                print("Changing current map to: " + currentMap.Details());
            }
        }
    }

    // ReduceTimer reduces the main game timer by amount, returing true when 0 is reached.
    bool ReduceTimer(int64 amount) {
        timer -= amount;
        if (timer <= 0) {
            timer = 0;
            return true;
        } else {
            return false;
        }
    }

    void SwitchMap() {
        isLoading = true;
        MXRandom::LoadRandomMap(false);
    }
}