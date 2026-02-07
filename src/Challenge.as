enum ChallengeState {
    Unknown,
    WaitingForMap,
    InMap,
}


class Challenge {
    // config
    int64 startedAt = 0;
    int64 finishedAt = 0;
    ChallengeMode _mode;
    bool _custom;

    // game status
    bool isRunning = false;
    bool isPaused = false;
    bool isFinished = false;
    Map@ currentMap = null;
    ChallengeState state = ChallengeState::Unknown;

    // global counters
    int64 _timer = 0;
    int64 get_timer() { return _timer; }
    int64 _score = 0;
    int64 get_score() { return _score; }
    int64 totalGameTime = 0;

    // stats
    array<Medals> finishedMaps;
    array<string> brokenMaps;

    Challenge() {};
    Challenge(ChallengeMode gameMode, bool custom) {
        _mode = gameMode;
        _custom = custom;
    }

    // Start should be only called once.
    void Start() {
        startedAt = Time::Stamp;
        _timer = ModeTimer(_mode) - 1; // sacrifice 1ms for less digits
        print("Starting new game: " + _mode + " (" + clock(_timer) + ")");
        isRunning = true;

        // Set current map, if any, to prevent detecting it before our map loads.
        auto map = GetCurrentMap();
        if (map !is null) {
            @currentMap = Map(map.MapInfo, 1, 1, 1, 1);
        }

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
        if (currentMap !is null) {
            currentMap.timeSpent += delta;
        }

        // Detect and validate finish, process it in the same frame.
        bool validFinish = ValidateFinish();
        if (validFinish && currentMap.EarnedMedal() >= ModeMedal(_mode) && !currentMap.done) {
            auto score = currentMap.Score(ModeMedal(_mode));
            print("Completed map " + currentMap.Details() + ", scoring " + clock(score));
            _score += score;
            currentMap.done = true;
            ShowLastScore(score); // UI
            SkipToNextMap();
        }

        DetectMapChange();
    }

    void SkipToNextMap() {
        if (currentMap is null) {
            return;
        }
        finishedMaps.InsertLast(currentMap.EarnedMedal());

        auto cost = currentMap.SkipCost(ModeMedal(_mode));
        print("Skipped map " + currentMap.Details() + ", with a cost " + clock(cost));
        if (ReduceTimer(cost)) {
            FinishGame();
        } else {
            SwitchMap();
        }

        if (cost > 0) ShowLastSkip(-cost); // UI
    }

    // ValidateFinish detects map finish and updates finish time if PB, returns true if finish is detected.
    bool warnOnce = false;
    bool ValidateFinish() {
        if (currentMap is null) {
            return false;
        }

        auto finishTime = GetFinishTime();
        if (finishTime >= 0 && finishTime != currentMap.lastFinishTime) {
            if (!IsMapValid()) {
                if (!warnOnce) {
                    UI::ShowNotification(PLUGIN_NAME, "Invalid map detected, load correct map or reset\n" + currentMap.name, COLOR_ERROR);
                    warnOnce = true;
                }
                return false;
            }
            if (finishTime < currentMap.pbFinishTime || currentMap.pbFinishTime < 0) {
                currentMap.pbFinishTime = finishTime;
            }      
            currentMap.lastFinishTime = finishTime;

            print("Finished map " + currentMap.Details() + " with time " + clock(currentMap.lastFinishTime) + " ("+  MedalName(currentMap.EarnedMedal()) +")");
            warnOnce = false;
            return true;
        }
        return false;
    }

    // IsMapValid is used for finish validation - returning false if the finish is not expected.
    bool IsMapValid() {
        if (state != ChallengeState::InMap) {
            return false;
        }
        if (currentMap is null) {
            return false;
        }

        auto map = GetCurrentMap();
        if (map !is null && map.MapInfo.MapUid != currentMap.uid) {
            return false;
        }

        return true;
    }

    // DetectMapChange will replace current map with a different map.
    void DetectMapChange() {
        if (state != ChallengeState::WaitingForMap) {
            return;
        }
        auto map = GetCurrentMap();
        if(map !is null) {
            if (currentMap is null || currentMap.uid != map.MapInfo.MapUid) {
                @currentMap = Map(map.MapInfo,
                                map.TMObjective_AuthorTime,
                                map.TMObjective_GoldTime,
                                map.TMObjective_SilverTime,
                                map.TMObjective_BronzeTime
                            );
                state = ChallengeState::InMap;
                print("Changed current map to: " + currentMap.Details());
            }
        }
    }

    void FinishGame() {
        isRunning = false;
        isFinished = true;
        finishedAt = Time::Now;
        @currentMap = null;
        if (!_custom && score > PersonalBest(_mode)) {
            SavePersonalBest(_mode, _score);
        }

        // Save online score
        GameData@ scoreData = GameData(
            _mode,
            _custom,
            score,
            startedAt,
            totalGameTime,
            FinishedCount(),
            SkippedCount(),
            MedalStats(),
            brokenMaps);
        startnew(SavePBAsync, scoreData);
    }

    // ReduceTimer reduces the main game timer by amount, returning true when 0 is reached.
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
        state = ChallengeState::WaitingForMap;
        MXRandom::LoadRandomMap(_custom);
    }

    /* Controls */
    void TogglePause() {
        isPaused = !isPaused;
    }

    void SkipBrokenMap() {
        if (state == ChallengeState::InMap) {
            _timer += CurrentTimeSpent();
            finishedMaps.InsertLast(Medals::Broken);
            brokenMaps.InsertLast(currentMap.uid);
        }

        SwitchMap();
    }

    /* UX Helpers */
    bool IsInProgress() {
        return isRunning;
    }

    bool IsFinished() {
        return isFinished;
    }

    bool IsPaused() {
        return isPaused;
    }

    bool CustomFiltersEnabled() {
        return _custom;
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

    Medals TargetMedal() {
        return ModeMedal(_mode);
    }

    int MedalCount(Medals medal) {
        int count = 0;
        for (uint i=0; i < finishedMaps.Length; i++) {
            if (finishedMaps[i] == medal) {
                count++;
            }
        }
        
        return count;
    }

    // MedalStats returns a dictionary of medal counts from finished maps.
    dictionary@ MedalStats() {
        dictionary stats;
        for (uint i = 0; i < finishedMaps.Length; i++) {
            auto key = MedalName(finishedMaps[i]).ToLower();
            if (stats.Exists(key)) {
                stats[key] = int(stats[key]) + 1;
            } else {
                stats[key] = 1;
            }
        }
        return stats;
    }

    // MapCount includes count of all maps except broken.
    int MapCount() {
        int count = 0;
        for (uint i=0; i < finishedMaps.Length; i++) {
            if (finishedMaps[i] > Medals::Broken) {
                count++;
            }
        }
        
        return count;
    }

    // FinishedCount includes all maps that achieved target medal (or above)
    int FinishedCount() {
        int count = 0;
        for (uint i=0; i < finishedMaps.Length; i++) {
            if (finishedMaps[i] >= TargetMedal()) {
                count++;
            }
        }
        
        return count;
    }

    // SkippedCount includes all maps that did not achieve target medal (or above), not including broken maps.
    int SkippedCount() {
        int count = 0;
        for (uint i=0; i < finishedMaps.Length; i++) {
            if (finishedMaps[i] < TargetMedal() && finishedMaps[i] != Medals::Broken) {
                count++;
            }
        }
        
        return count;
    }

    array<Medals> GetAllMedals() {
        return finishedMaps;
    }

    int PossibleScoreMax() {
        if (currentMap is null) return 0;
        return currentMap.CalculateScore(currentMap.MedalTime(ModeMedal(_mode)), ModeMedal(_mode));
    }

    int PossibleScoreMin() {
        if (currentMap is null) return 0;
        return currentMap.CalculateScore(100, ModeMedal(_mode));
    }

    Medals CurrentMedal() {
        if (currentMap is null) return Medals::None;
        return currentMap.EarnedMedal();
    }

    ChallengeMode Mode() {
        return _mode;
    }

    string CurrentMapName() {
        if (currentMap is null) return "";
        return currentMap.name;
    }
}
