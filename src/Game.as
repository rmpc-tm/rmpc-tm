
bool isRunning = false;
bool isPaused = false;

int64 gameStartedAt = 0;
int64 gameFinishedAt = 0;

int64 gameTimerMs = 0;
int64 scoreTimerMs = 0;

int64 gameMapCount = 0;
int64 gameSkipCount = 0;

int64 totalTimeSpent = 0;

MapInfo currentMap;

class MapInfo {
   string name;
   string uid;
   array<int> medals(5, 0);

   int timeSpent = 0;
   int pbFinishTime = -1;
   int lastFinishTime = -1;

   bool done;

   MapInfo() {};
   MapInfo(const string mapName, const string mapUid, uint at, uint gold, uint silver, uint bronze) {
      name = mapName;
      uid = mapUid;
      medals[Medals::Author] = at;
      medals[Medals::Gold] = gold;
      medals[Medals::Silver] = silver;
      medals[Medals::Bronze] = bronze;
      medals[Medals::None] = 0;

      timeSpent = 0;

      pbFinishTime = -1;
      lastFinishTime = -1;

      done = false;
   }

   string Details() {
      return name + " (" + uid + ") AT=" + clock(medals[Medals::Author]);
   }

   bool HasAT() {
      return pbFinishTime >= 0 && pbFinishTime <= medals[Medals::Author];
   }

   bool HasFinished() {
      return pbFinishTime >= 0;
   }

   bool HasMedal(Medals medal) {
      return HasFinished() && EarnedMedal() >= medal;
   }

    int64 CalculateScore(int64 time) {
        return Math::Min((time + medals[Medals::Author]) / 2, MAX_MAP_LENGTH);
    }

   int64 Score() {
      return CalculateScore(pbFinishTime);
   }

   Medals EarnedMedal() {
     if (pbFinishTime < 0) {
         return Medals::None;
      }

      if (pbFinishTime <= medals[Medals::Author]) {
         return Medals::Author;
      }
      if (pbFinishTime <= medals[Medals::Gold]) {
         return Medals::Gold;
      }
      if (pbFinishTime <= medals[Medals::Silver]) {
         return Medals::Silver;
      }
      if (pbFinishTime <= medals[Medals::Bronze]) {
         return Medals::Bronze;
      }
      
      return Medals::None;
   }

   int64 SkipCost() {
      if (medals[Medals::Author] > 3 * ONE_MINUTE) {
         // too long
         return 0;
      }

      if (pbFinishTime < 0) {
         // not finished
         return Math::Max(medals[Medals::Bronze], MAX_MAP_LENGTH) + 3 * Math::Min(medals[Medals::Bronze], MAX_MAP_LENGTH);
      }

      auto medal = EarnedMedal();
      if (medal == Medals::None) {
         return Math::Min(
            medals[Medals::Author] + medals[Medals::Gold] + medals[Medals::Silver] + medals[Medals::Bronze] + Math::Max(medals[Medals::Bronze], ONE_MINUTE),
            5 * MAX_MAP_LENGTH
         );
      }
      if (medal == Medals::Bronze) {
         return Math::Min(
            medals[Medals::Author] + medals[Medals::Gold] + medals[Medals::Silver] + Math::Max(medals[Medals::Silver], ONE_MINUTE),
            4 * MAX_MAP_LENGTH
         );
      }
      if (medal == Medals::Silver) {
         return Math::Min(
            medals[Medals::Author] + medals[Medals::Gold] + Math::Max(medals[Medals::Gold], ONE_MINUTE),
            3 * MAX_MAP_LENGTH
         );
      }
      if (medal == Medals::Gold) {
         return 0;
      }

      return 0; // AT, huh?
   }

   int64 TimeSpent() {
      return timeSpent;
   }
}

void Run(int64 timeDelta) {
   if (!isRunning) return;
   if (isPaused) return;

   if (IsAutoPaused()) return;
   
   if (ReduceTimer(timeDelta)) {
      FinishGame();
   }

   totalTimeSpent += timeDelta;

   // change map if needed
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
      currentMap.timeSpent += timeDelta;
   }

   // detect map finished
   auto finishTime = GetFinishTime();
   if (finishTime >= 0 && finishTime != currentMap.lastFinishTime) {
      if (finishTime < currentMap.pbFinishTime || currentMap.pbFinishTime < 0) {
         currentMap.pbFinishTime = finishTime;
      }      
      currentMap.lastFinishTime = finishTime;

      print("Finished map " + currentMap.Details() + " with time " + clock(currentMap.lastFinishTime) + " ("+  MedalName(currentMap.EarnedMedal()) +")");
   }

   if (currentMap.HasAT() && !currentMap.done) {
      print("Got AT at " + currentMap.Details() + ", scoring " + clock(currentMap.Score()));
      IncreaseScoreTimer(currentMap.Score());
      currentMap.done = true;
      SkipToNextMap();
   }
}

// source: MXRandom
int GetFinishTime() {
    auto app = cast<CTrackMania>(GetApp());
    auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
    auto script = cast<CSmArenaRulesMode>(app.PlaygroundScript);

    int finishTime = -1;

    if (playground !is null && script !is null && playground.GameTerminals.Length > 0) {
        auto terminal = playground.GameTerminals[0];
        auto player = cast<CSmPlayer>(terminal.ControlledPlayer);
        if (player !is null) {
            auto seq = terminal.UISequence_Current;
            if (seq == SGamePlaygroundUIConfig::EUISequence::Finish || seq == SGamePlaygroundUIConfig::EUISequence::UIInteraction) {
                CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);
                auto ghost = script.Ghost_RetrieveFromPlayer(playerScriptAPI);
                if (ghost !is null) {
                    if (ghost.Result.Time > 0 && ghost.Result.Time < uint(-1)) {
                        finishTime = ghost.Result.Time;
                    }
                    script.DataFileMgr.Ghost_Release(ghost.Id);
                }
            }
        }
    }

    return finishTime;
}

void StartNewGame(int64 timer, const string mode) {
   timer = timer - 1; // prevent extra digit FIXME
   print("Starting new game : " + timer + " " + mode);
   isRunning = true;
   isPaused = false;
   gameTimerMs = timer;
   scoreTimerMs = 0;
   totalTimeSpent = 0;
   gameMapCount = 0;
   gameSkipCount = 0;
   gameStartedAt = Time::Now;
   gameFinishedAt = 0;
   SelectNextMap();
}

void SelectNextMap() {
   MXRandom::LoadRandomMap(false);
}

void FreeSkip() {
   print("Using free skip on " + currentMap.Details());
   SelectNextMap();
}

void SkipToNextMap() {
   gameMapCount++;
   gameSkipCount++;
   if (ReduceTimer(currentMap.SkipCost())) {
      FinishGame();
   } else {
        SelectNextMap();
   }
}

// ReduceTimer reduces game timer by specified amount and returns true if 0 was reached
bool ReduceTimer(int64 amount) {
   gameTimerMs -= amount;
   if (gameTimerMs <= 0) {
      gameTimerMs = 0;
      return true;
   } else {
      return false;
   }
}

void IncreaseScoreTimer(int64 ms) {
   scoreTimerMs += ms;
   ShowLastScore(ms);
}

void StorePersonalBest(int64 score) {
   if (score > PersonalBest) {
      PersonalBest = score;
   }
}

void TogglePause() {
   isPaused = !isPaused;
}

void Stop() {
   isRunning = false;
   isPaused = false;
   gameStartedAt = 0;
}

void Reset() {
    Stop();
    gameFinishedAt = 0;
}

void FinishGame() {
    gameFinishedAt = Time::Now;
   StorePersonalBest(scoreTimerMs);
   Stop();
}

bool HasMedal(Medals medal) {
   return currentMap.HasMedal(medal);
}

int64 CurrentSkipPenalty() {
   return -currentMap.SkipCost();
}

int64 CurrentTimeSpent() {
   return currentMap.TimeSpent();
}

int64 TotalTimeSpent() {
   return totalTimeSpent;
}

int64 CurrentMapCount() {
   return gameMapCount;
}

int64 CurrentMapsSkipped() {
    return gameSkipCount;
}

string MapName() {
    return currentMap.name;
}

bool GameInProgress() {
    return isRunning && gameStartedAt > 0;
}
bool GameFinished() {
    return gameFinishedAt > 0;
}