const string entries_url = "https://api.simpleboards.dev/api/entries";
const string xHeader = "x-api-key";
const string k = "k"; const string i = "i";

void SavePBAsync(int64 score) {
    if (GlobalState.Length == 0 || game is null) return;

    auto playerId = PlayerID;
    if (game.Mode() == ChallengeMode::Gold60) {
        score = score / 1000;
        playerId = playerId + "-gold";
    }
    
    Json::Value bodyJson = Json::Object();
    bodyJson["leaderboardId"] = XOR(Text::DecodeBase64(Json::Parse(GlobalState).Get(i)), i);
    bodyJson["playerId"] = playerId;
    bodyJson["playerDisplayName"] = PlayerName;
    bodyJson["metadata"] = Meta::ExecutingPlugin().Version;
    bodyJson["score"] = score;

    auto req = Net::HttpRequest(entries_url, Json::Write(bodyJson));
    req.Headers.Set(xHeader, XOR(Text::DecodeBase64(Json::Parse(GlobalState).Get(k)), k));
    req.Start();
    while (!req.Finished()) {
        yield();
    }
}
