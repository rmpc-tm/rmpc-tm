const string entries_url = "https://api.simpleboards.dev/api/entries";
const string xHeader = "x-api-key";
const string k = "k"; const string i = "i";


class GameData {
    ChallengeMode mode;
    int64 score;
    int64 duration;
    int64 mapCount;

    GameData(ChallengeMode m, int64 s, int64 d, int64 mc) {
        mode = m; score = s; duration = d; mapCount = mc;
    }

    // Metadata builds metadata string in the format "key1=value1,key2=value2"
    string Metadata() {
        auto data = "ver=" + Meta::ExecutingPlugin().Version;
        string mod = "???";
        if (game.Mode() == ChallengeMode::Gold60) {
            mod = "gold";
        } else if (game.Mode() == ChallengeMode::Author60) {
            mod = "author";
        }
        data += ",mod=" + mod;
        data += ",cnt=" + Text::Format("%d", mapCount);
        data += ",dur=" +  Text::Format("%d", duration / 1000);

        return data;
    }

    // Use seconds for Gold so they don't occupy places in the leaderboard.
    int64 Score() {
        switch(game.Mode()) {
            case ChallengeMode::Author60:
                return score;
            case ChallengeMode::Gold60:
                return score / 1000;
            default:
                return 0;
        }
    }

    // Add suffix to player id so each player can have two entries in leaderboard.
    string playerId() {
        switch(game.Mode()) {
            case ChallengeMode::Author60:
                return PlayerID;
            case ChallengeMode::Gold60:
                return PlayerID + "-gold";
            default:
                return PlayerID + "-unknwon";
        }
    }

    // Prepare JSON payload for scoring service.
    Json::Value AsJson() {
        Json::Value bodyJson = Json::Object();
        bodyJson["leaderboardId"] = XOR(Text::DecodeBase64(Json::Parse(GlobalState).Get(i)), i);
        bodyJson["playerId"] = playerId();
        bodyJson["playerDisplayName"] = PlayerName;
        bodyJson["score"] = Score();
        bodyJson["metadata"] =  Metadata();

        return bodyJson;
    }
}


void SavePBAsync(ref@ gameData) {
    GameData@ data = cast<GameData>(gameData);

    if (GlobalState.Length == 0 || game is null) return;
    if (PlayerID.Length == 0) return;

    auto bodyJson = data.AsJson();

    auto req = Net::HttpRequest(entries_url, Json::Write(bodyJson));
    req.Headers.Set(xHeader, XOR(Text::DecodeBase64(Json::Parse(GlobalState).Get(k)), k));
    req.Start();
    while (!req.Finished()) {
        yield();
    }
}
