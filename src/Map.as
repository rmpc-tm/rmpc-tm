class Map {
    string name;
    string uid;
    array<int> medals(5, 0);

    int timeSpent = 0;
    int pbFinishTime = -1;
    int lastFinishTime = -1;

    bool done = false;

    Map() {};
    Map(CGameCtnChallengeInfo@ info, uint at, uint gold, uint silver, uint bronze) {
        name = info.Name;
        uid = info.MapUid;
        medals[Medals::Author] = at;
        medals[Medals::Gold] = gold;
        medals[Medals::Silver] = silver;
        medals[Medals::Bronze] = bronze;
        medals[Medals::None] = 0;
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

    int64 _calculateScore(int64 time, Medals medal) {
        const auto target = Math::Min(medals[medal], MAX_MAP_LENGTH);
        const auto finishTime = Math::Min(time, target);
        const auto cap = (time + target) / 2.0f;
        const auto gradient = 2.0f;

        return int64(cap + (target - cap) * Math::Pow(float(finishTime) / float(target), gradient));
    }

   int64 Score(Medals medal) {
      return _calculateScore(pbFinishTime, medal);
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

    int64 SkipCost(Medals goal) {
        if (medals[goal] > MAX_MAP_LENGTH) {
            return 0; // too long
        }

        auto earnedMedal = EarnedMedal();
        if (earnedMedal >= goal) {
            return 0; // goal achieved
        }

        int64 extra = goal == Medals::Author ? medals[Medals::Author] : 0;
        int64 midpoint = (medals[goal] + medals[Medals::Bronze]) / 2;

        // unfinished
        if (pbFinishTime < 0) {
            return extra + Math::Max(medals[Medals::Bronze], ONE_MINUTE) + 3 * Math::Min(midpoint, MAX_MAP_LENGTH);
        }

        extra += Math::Max(0, medals[earnedMedal+1] - pbFinishTime);

        if (earnedMedal == Medals::None) {
            return Math::Min(
                extra + medals[Medals::Gold] + medals[Medals::Silver] + medals[Medals::Bronze] + Math::Max(medals[Medals::Bronze], ONE_MINUTE),
                4 * MAX_MAP_LENGTH + extra
            );
        }

        /* Medals */
        if (earnedMedal == Medals::Bronze) {
            return Math::Min(
                extra + medals[Medals::Gold] + medals[Medals::Silver] + Math::Max(medals[Medals::Silver], ONE_MINUTE),
                3 * MAX_MAP_LENGTH + extra
            );
        }
        if (earnedMedal == Medals::Silver) {
            return Math::Min(
                extra + medals[Medals::Gold] + Math::Max(medals[Medals::Gold], ONE_MINUTE),
                2 * MAX_MAP_LENGTH + extra
            );
        }

        return 0; // Free Gold skip for Author
    }

   int64 TimeSpent() {
      return timeSpent;
   }
}