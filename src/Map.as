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
        int64 scoredTime = pbFinishTime;
        if (medal == Medals::Gold && pbFinishTime < medals[Medals::Author]) {
            scoredTime = medals[Medals::Gold] - (medals[Medals::Author] - pbFinishTime);
        }
        return _calculateScore(scoredTime, medal);
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

    // helper for skipping costs
    int64 magic(Medals medal) {
        int64 trimmed = Math::Min(medals[medal], MAX_MAP_LENGTH / 2);
        return (trimmed / 2) + 22 * ONE_SECOND;
    }

    int64 SkipCost(Medals goal) {
        if (medals[goal] > MAX_MAP_LENGTH) {
            return 0; // too long, free skip
        }

        auto earnedMedal = EarnedMedal();
        if (earnedMedal >= goal) {
            return 0; // goal achieved
        }

        int64 missing = medals[goal];
        int64 extra = goal == Medals::Author ? magic(Medals::Author) : 0;

        // unfinished
        if (pbFinishTime < 0) {
            return missing + Math::Max(magic(Medals::Bronze), ONE_MINUTE) + 3 * magic(Medals::Bronze) + extra;
        }

        missing = Math::Min(pbFinishTime - medals[goal], medals[goal]);

        if (earnedMedal == Medals::None) {
            return missing + magic(Medals::Gold) + magic(Medals::Silver) + magic(Medals::Bronze) + extra;
        }

        /* Medals */
        if (earnedMedal == Medals::Bronze) {
            return missing + magic(Medals::Gold) + magic(Medals::Silver) + extra;
        }
        if (earnedMedal == Medals::Silver) {
            return missing + magic(Medals::Gold) + extra;
        }

        return missing; // Gold skip for Author
    }

    int64 TimeSpent() {
        return timeSpent;
    }
}