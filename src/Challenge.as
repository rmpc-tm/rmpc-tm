
class Challenge {
    // config
    int64 startedAt = 0;
    ChallengeMode _mode;

    // game status
    bool isRunning = false;
    bool isPaused = false;
    bool isFinished = false;
    Map@ currentMap = null;

    // global counters
    int64 _timer = 0;
    int64 get_timer() { return _timer; }
    int64 _score = 0;
    int64 get_score() { return _score; }
    int64 totalGameTime = 0;

    // map timers
    int64 mapTimer = 0;

    // stats
    

    Challenge() {};
    Challenge(ChallengeMode gameMode) {
        _mode = gameMode;
    }

    // Start shuld be only called once.
    void Start() {
        startedAt = Time::Now;
        _timer = ModeTimer(_mode) - 1; // sacrifice 1ms for less digits
        print("Starting new game: " + _mode + " (" + _timer + ")");
        isRunning = true;
        SwitchMap();
    }

    // Main challenge loop to be called each tick.
    void Step(int64 delta) {
        if (!isRunning) return;
        if (isPaused) return;

        // menu, etc...
        if (IsAutoPaused()) return;

        // TODO - force skip?
        IsMapValid();

        // tick
        if (ReduceTimer(delta)) {
            FinishGame();
        }
        totalGameTime += delta;
        if (currentMap !is null) {
            currentMap.timeSpent += delta;
        }

        ValidateFinish();

        if (currentMap !is null && currentMap.EarnedMedal() >= ModeMedal(_mode) && !currentMap.done) {
            auto score = currentMap.Score(ModeMedal(_mode));
            print("Got " + ModeMedalName(_mode) + " at " + currentMap.Details() + ", scoring " + clock(score));
            _score += score;
            currentMap.done = true;
            ShowLastScore(score); // UI
            SkipToNextMap();
        }

        DetectMapChange();
    }

    void SkipToNextMap() {
        auto cost = currentMap.SkipCost(ModeMedal(_mode));
        // TODO save finished map stats
        if (ReduceTimer(cost)) {
            FinishGame();
        } else {
            SwitchMap();
        }

        if (cost > 0) ShowLastSkip(-cost); // UI
    }

    void ValidateFinish() {
        auto finishTime = GetFinishTime();
        if (finishTime >= 0 && finishTime != currentMap.lastFinishTime) {
            if (finishTime < currentMap.pbFinishTime || currentMap.pbFinishTime < 0) {
                currentMap.pbFinishTime = finishTime;
            }      
            currentMap.lastFinishTime = finishTime;

            print("Finished map " + currentMap.Details() + " with time " + clock(currentMap.lastFinishTime) + " ("+  MedalName(currentMap.EarnedMedal()) +")");
        }
    }

    bool invalidOnce = false;
    bool IsMapValid() {
        auto app = cast<CTrackMania>(GetApp());
        auto map = app.RootMap;

        if (currentMap is null || map is null) {
            return true;
        }

        if(currentMap.uid != map.MapInfo.MapUid) {
            if (!invalidOnce) {
                print("Invalid map detected:" + currentMap.uid + " != " + map.MapInfo.MapUid);
                invalidOnce = true;
            }
            return false;
        }

        return true;
    }

    void DetectMapChange() {
        auto app = cast<CTrackMania>(GetApp());
        auto map = app.RootMap;
        if(map !is null) {
            if (currentMap is null || currentMap.uid != map.MapInfo.MapUid) {
                @currentMap = Map(map.MapInfo,
                                map.TMObjective_AuthorTime,
                                map.TMObjective_GoldTime,
                                map.TMObjective_SilverTime,
                                map.TMObjective_BronzeTime
                            );
                print("Changed current map to: " + currentMap.Details());
                print(Text::StripFormatCodes(map.MapInfo.Name));
                print(Text::StripFormatCodes(map.MapInfo.NameForUi));
                print(Text::StripFormatCodes(map.MapName));
                print(map.IdName);

                print(clock(map.TMObjective_AuthorTime));
                print(clock(map.TMObjective_GoldTime));
                print(clock(map.TMObjective_SilverTime));
                print(clock(map.TMObjective_BronzeTime));

                print(map.MapInfo.MapUid);
            }
        }
    }

    void FinishGame() {
        isRunning = false;
        isFinished = true;
        if (_score > PersonalBest(_mode)) {
            SavePersonalBest(_mode, _score);
        }
    }

    // ReduceTimer reduces the main game timer by amount, returing true when 0 is reached.
    bool ReduceTimer(int64 amount) {
        _timer -= amount;
        if (_timer <= 0) {
            _timer = 0;
            return true;
        } else {
            return false;
        }
    }

    void SwitchMap() {
        MXRandom::LoadRandomMap(false);
    }

    /* Controlls */
    void TogglePause() {
        isPaused = !isPaused;
    }

    void SkipBrokenMap() {
        _timer += CurrentTimeSpent();
        SwitchMap();
    }

    /* UX Helpers */
    bool IsInProgress() {
        return isRunning; /// ?
    }

    bool IsFinished() {
        return isFinished;
    }

    bool IsPaused() {
        return isPaused;
    }

    bool HasMedal(Medals medal) {
        if (currentMap is null) {
            return false;
        }
        return currentMap.HasMedal(medal);
    }

    int64 CurrentSkipPenalty() {
        if (currentMap is null) {
            return ONE_HOUR;
        }
        return -currentMap.SkipCost(ModeMedal(_mode));
    }

    int64 CurrentTimeSpent() {
        if (currentMap is null) {
            return 0;
        }
        return currentMap.TimeSpent();
    }

    int64 TotalTimeSpent() {
        return totalGameTime;
    }

}