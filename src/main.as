
Challenge@ game = null;

void Main() {
   if (!Permissions::PlayLocalMap()) {
      UI::ShowNotification(PLUGIN_NAME, "Unable to play local maps.\n(Missing Club Access?)", COLOR_ERROR);
      return;
   }
   print("Starting: " + PLUGIN_NAME + "...");
   Visible = false;

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
         @game = null;
      }
   }
}

void StartNewGame(ChallengeMode mode) {
   @game = Challenge(mode);
   game.Start();
}

void Reset() {
   @game = null;
}
