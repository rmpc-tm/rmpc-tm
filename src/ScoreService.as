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
    string mode; // author, gold, custom
    int64 score;
    int64 duration;
    int64 mapCount;
    int64 skippedCount;

    GameData(ChallengeMode m, bool c, int64 s, int64 d, int64 mc, int64 sc) {
        mode = ModeMedalName(m).ToLower();
        if (c) {
            mode = "custom";
        }
        score = s; duration = d; mapCount = mc; skippedCount = sc;
    }

    Json::Value Metadata() {
        Json::Value metadata = Json::Object();
        metadata["ver"] = Meta::ExecutingPlugin().Version;
        return metadata;
    }

    Json::Value AsJson() {      
        Json::Value bodyJson = Json::Object();
        bodyJson["game_mode"] = mode;
        bodyJson["score"] = score;
        bodyJson["maps_completed"] = mapCount;
        bodyJson["maps_skipped"] =  skippedCount;
        bodyJson["duration_ms"] =  duration;
        bodyJson["metadata"] =  Metadata();

        return bodyJson;
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
