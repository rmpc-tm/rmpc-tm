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