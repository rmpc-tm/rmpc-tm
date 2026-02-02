Challenge@ game = null;

string PlayerID = "";
string PlayerName = "";
string GlobalState = "";


void Main() {
   if (!Permissions::PlayLocalMap()) {
      UI::ShowNotification(PLUGIN_NAME, "Unable to play local maps.\n(Missing Club Access?)", COLOR_ERROR);
      return;
   }

   startnew(LoadConfigAsync);

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
      auto now = Time::Now;
      auto delta = (lastDeltaAt == 0) ? 0 : now - lastDeltaAt;
      lastDeltaAt = now;
      if (game !is null) {
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

void LoadConfigAsync() {
   auto req = Net::HttpGet(OPENPLANET_CONFIG_URL);
   while (!req.Finished()) {
      yield();
   }

   if (req.ResponseCode() != 200) return;
   auto jsonData = req.Json();
   if (jsonData is null) return;

   auto scoreHost = req.Json().Get("score_api_host");
   if (scoreHost is null) {
      print("Could not load score service host");
      return;
   }

   ScoreApiHost = scoreHost;

   LoadWorldRecordsAsync();
   AuthenticateAsync();
}

void LoadWorldRecordsAsync() {
   if (ScoreApiHost.Length == 0) return;

   auto req = Net::HttpGet(ScoreApiHost + WORLD_RECORDS_PATH);
   while (!req.Finished()) {
      yield();
   }

   if (req.ResponseCode() != 200) return;
   auto jsonData = req.Json();
   if (jsonData is null) return;

   auto authorData = jsonData.Get("author");
   if (authorData !is null) {
      WRAuthor60 = WorldRecord(
         int64(authorData.Get("score")),
         string(authorData.Get("player_name"))
      );
   }

   auto goldData = jsonData.Get("gold");
   if (goldData !is null) {
      WRGold60 = WorldRecord(
         int64(goldData.Get("score")),
         string(goldData.Get("player_name"))
      );
   }
}
