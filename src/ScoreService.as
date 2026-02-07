string ScoreApiHost = "";
const string AuthPath = "/rmpc/api/auth";
const string ScoresPath = "/rmpc/api/scores";

string SessionToken = "";


// https://openplanet.dev/docs/reference/auth
void AuthenticateAsync() {
    if (ScoreApiHost.Length == 0) {
        return;
    }

    auto token_task = Auth::GetToken();
    while (!token_task.Finished()) {
        yield();
    }

    string openplanetToken = token_task.Token();
    if (openplanetToken.Length == 0) {
        print("Failed to get Openplanet token");
        return;
    }

    Json::Value bodyJson = Json::Object();
    bodyJson["openplanet_token"] = openplanetToken;

    auto req = Net::HttpRequest(ScoreApiHost + AuthPath, Json::Write(bodyJson));
    req.Headers.Set("Content-Type", "application/json");
    req.Start();

    while (!req.Finished()) {
        yield();
    }

    if (req.ResponseCode() == 200) {
        auto response = Json::Parse(req.String());
        SessionToken = response.Get("session_token");
        print("Authentication successful");
    } else {
        print("Authentication failed: " + req.ResponseCode());
    }
}


class GameData {
    Json::Value data;

    GameData(
        ChallengeMode mode,
        bool custom,
        int64 score,
        int64 startTime,
        int64 duration,
        int64 completedMaps,
        int64 skippedMaps,
        dictionary medalStats,
        array<string> brokenMaps) {

        // author, gold, custom
        string gameMode = ModeMedalName(mode).ToLower();
        if (custom) {
            gameMode = "custom";
        }

        data = Json::Object();
        data["game_mode"] = gameMode;
        data["score"] = score;
        data["maps_completed"] = completedMaps;
        data["maps_skipped"] =  skippedMaps;
        data["duration_ms"] =  duration;

        Json::Value metadata = Json::Object();
        metadata["ver"] = Meta::ExecutingPlugin().Version;
        metadata["start"] = startTime;
        metadata["medals"] = medalStats;
        if (brokenMaps.Length > 0) metadata["broken_sample"] = SampleMaps(brokenMaps, 3);

        data["metadata"] =  metadata;
    }

    array<string> SampleMaps(array<string> maps, uint count) {
        if (maps.Length <= count) {
            return maps;
        }

        array<string> sample;
        for (uint i=0; i < count; i++) {
            sample.InsertLast(maps[Math::Rand(0, maps.Length - 1)]);
        }

        return sample;
    }

    Json::Value AsJson() {      
        return this.data;
    }
}


void SavePBAsync(ref@ gameData) {
    GameData@ data = cast<GameData>(gameData);

    if (SessionToken.Length == 0) {
        print("Not authenticated");
        return;
    }

    auto bodyJson = data.AsJson();

    auto req = Net::HttpRequest(ScoreApiHost + ScoresPath, Json::Write(bodyJson));
    req.Headers.Set("Content-Type", "application/json");
    req.Headers.Set("Authorization", "Bearer " + SessionToken);
    req.Start();

    while (!req.Finished()) {
        yield();
    }

    if (req.ResponseCode() == 200 || req.ResponseCode() == 201) {
        print("Score saved successfully");
    } else {
        print("Failed to save score: " + req.ResponseCode());
    }
}
