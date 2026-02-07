
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
        name = Text::StripFormatCodes(info.Name);
        uid = info.MapUid;
        medals[Medals::Author] = at;
        medals[Medals::Gold] = gold;
        medals[Medals::Silver] = silver;
        medals[Medals::Bronze] = bronze;
        medals[Medals::None] = 0;
    }

    string Details() {
        return name + " [" + uid + "] AT=" + clock(medals[Medals::Author]);
    }

    bool HasFinished() {
        return pbFinishTime >= 0;
    }

    bool HasMedal(Medals medal) {
        return HasFinished() && EarnedMedal() >= medal;
    }

    int MedalTime(Medals medal) {
        return medals[medal];
    }

    int64 CalculateScore(int64 time, Medals medal) {
        const int64 target = Math::Min(medals[medal], MAX_MAP_LENGTH);
        const int64 finishTime = Math::Min(time, target);
        const auto cap = Math::Min((finishTime + target), finishTime + 60 * ONE_SECOND) / 2.0f;

        // cap gains on super-quick maps (relative to goal)
        const auto scoreGradient = 0.5f;
        auto score = cap + (target - cap) * Math::Pow(float(finishTime) / float(target), scoreGradient);

        // bonus so it's worth to play very short maps
        const auto bonusScale = 1.5f * ONE_SECOND;
        const auto bonusGradient = 0.4f;
        auto bonus = bonusScale * Math::Pow(MAX_MAP_LENGTH / target, bonusGradient) + 3 * ONE_SECOND;

        return int64(score + bonus);
    }

    int64 Score(Medals medal) {
        int64 scoredTime = pbFinishTime;
        // score adjustement for gold mode if author time is beaten
        if (medal == Medals::Gold && pbFinishTime < medals[Medals::Author]) {
            scoredTime = medals[Medals::Gold] - (medals[Medals::Author] - pbFinishTime);
        }
        return CalculateScore(scoredTime, medal);
    }

    Medals EarnedMedal() {
        if (pbFinishTime < 0) {
            return Medals::Unfinished;
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

    int64 TimeSpent() {
        return timeSpent;
    }

    /* Skip Cost Magic */
    int64 xCost(int64 time, int64 target, int64 min, int64 max) {
        auto k = 0.5f;
        auto ratio = Math::Max(time / target, 1.0f);
        return min + (max - min) * int64(1 - Math::Exp(-k * (ratio - 1)));
    }

    int64 normalize(Medals medal) {
        return (medals[medal] / 6) + 30 * ONE_SECOND;
    }

    int64 SkipCost(Medals goal) {
        if (medals[goal] > MAX_MAP_LENGTH) {
            return 0; // too long, free skip
        }

        auto earnedMedal = EarnedMedal();
        if (earnedMedal >= goal) {
            return 0; // goal achieved
        }

        int64 extra = goal == Medals::Author ? normalize(Medals::Author) : 0;
        extra += 15 * ONE_SECOND;

        auto unfinishedCost = medals[goal] + 3 * normalize(goal) + 3 * extra;
        if (earnedMedal == Medals::Unfinished) {
            return unfinishedCost;
        }

        int64 tNone = 3 * normalize(goal) + extra;
        if (earnedMedal == Medals::None) {
            return xCost(pbFinishTime, medals[goal], tNone, int64(unfinishedCost * 0.9f) - 5 * ONE_SECOND);
        }

        int64 missing = pbFinishTime - medals[goal];
        // thresholds
        int64 tBronze = missing + 2 * normalize(goal) + extra;
        int64 tSilver = missing + 1 * normalize(goal) + extra;
        int64 tGold = missing + extra;

        if (earnedMedal == Medals::Bronze) {
            return xCost(pbFinishTime, medals[goal], tSilver, int64(Math::Min(tNone, tBronze) * 0.9f) - 5 * ONE_SECOND);
        }
        if (earnedMedal == Medals::Silver) {
            return xCost(pbFinishTime, medals[goal], tGold, int64(tSilver * 0.9f) - 5 * ONE_SECOND);
        }

        return missing; // Gold skip for Author
    }
}
