Challenge@ game = null;

void Main() {
   if (!Permissions::PlayLocalMap()) {
      UI::ShowNotification(PLUGIN_NAME, "Unable to play local maps.\n(Missing Club Access?)", COLOR_ERROR);
      return;
   }
   Visible = false;
   CustomMaps = false;

   if (ScoringVersion != SCORING_VERSION) {
      PersonalBestAuthor60 = 0;
      PersonalBestGold60 = 0;
   }

   int64 lastDeltaAt = 0;
   while (true) {
      if (game !is null) {
         auto now = Time::Now;
         auto delta = (lastDeltaAt == 0) ? 0 : now - lastDeltaAt;
         lastDeltaAt = now;

         game.Step(delta);
      }
      yield();
   }
}

void RenderMenu() {
   if (UI::MenuItem(PLUGIN_NAME_WITH_ICON, "", Visible)) {
      Visible = !Visible;
      if (!Visible) {
         Reset();
      }
   }
}

void StartNewGame(ChallengeMode mode, bool custom) {
   @game = Challenge(mode, custom);
   game.Start();
}

void Reset() {
   @game = null;
}
