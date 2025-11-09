Challenge@ game = null;

string PlayerID = "";
string PlayerName = "";
string GlobalState = "";


void Main() {
   if (!Permissions::PlayLocalMap()) {
      UI::ShowNotification(PLUGIN_NAME, "Unable to play local maps.\n(Missing Club Access?)", COLOR_ERROR);
      return;
   }

   startnew(LoadRecordsAsync);

   CTrackManiaNetwork@ Network = cast<CTrackManiaNetwork>(GetApp().Network);
   if (Network !is null) {
      PlayerID = Network.PlayerInfo.WebServicesUserId;
      PlayerName = Text::StripFormatCodes(Network.PlayerInfo.Name);
   }

   Visible = DEV_MODE;
   CustomMaps = false;

   if (ScoringVersion != SCORING_VERSION) {
      PersonalBestAuthor60 = 0;
      PersonalBestGold60 = 0;
      ScoringVersion = SCORING_VERSION;
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

void LoadRecordsAsync() {
   auto req = Net::HttpGet(RECORDS_URL);
   while (!req.Finished()) {
      yield();
   }

   if (req.ResponseCode() != 200) return;
   auto jsonData = req.Json();
   if (jsonData is null) return;

   auto wra = req.Json().Get("wra");
   if (wra !is null) WRAuthor60 = wra;
   auto wrg = req.Json().Get("wrg");
   if (wrg !is null) WRGold60 = wrg;
   auto gameId = req.Json().Get("_id");
   if (gameId !is null) {
      auto state = XOR(Text::DecodeBase64(gameId), RECORDS_URL);
      GlobalState = state;
   }
}
