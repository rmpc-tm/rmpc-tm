const string entries_url = "https://api.simpleboards.dev/api/entries";
const string xHeader = "x-api-key";
const string k = "k"; const string i = "i";

void SavePBAsync(int64 score) {
    if (GlobalState.Length == 0 || game is null) return;
    if (PlayerID.Length == 0) return;

    auto playerId = PlayerID;
    auto metadata = "version=" + Meta::ExecutingPlugin().Version;
    if (game.Mode() == ChallengeMode::Gold60) {
        score = score / 1000;
        playerId = playerId + "-gold";
        metadata += ",mode=gold";
    } else if (game.Mode() == ChallengeMode::Author60) {
        metadata += ",mode=author";
    } else {
        return;
    }
    
    Json::Value bodyJson = Json::Object();
    bodyJson["leaderboardId"] = XOR(Text::DecodeBase64(Json::Parse(GlobalState).Get(i)), i);
    bodyJson["playerId"] = playerId;
    bodyJson["playerDisplayName"] = PlayerName;
    bodyJson["metadata"] =  metadata;
    bodyJson["score"] = score;

    auto req = Net::HttpRequest(entries_url, Json::Write(bodyJson));
    req.Headers.Set(xHeader, XOR(Text::DecodeBase64(Json::Parse(GlobalState).Get(k)), k));
    req.Start();
    while (!req.Finished()) {
        yield();
    }
}
