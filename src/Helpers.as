
// source: https://github.com/XertroV/tm-green-timer/blob/0.2.2/src/GreenTimer.as#L89
bool IsAutoPaused() {
    auto app = GetApp();

    bool inPG = app.CurrentPlayground !is null;
    if ((app.Editor !is null && !inPG)) {
        return true;
    }
    if ((app.Switcher.ModuleStack.Length < 1 || cast<CTrackManiaMenus>(app.Switcher.ModuleStack[0]) !is null)) {
        return true;
    }
    if (app.LoadProgress.State == NGameLoadProgress::EState::Displayed) {
        return true;
    }

    return false;
}

int64 lastDeltaAt = 0;
int64 calculateDelta() {
   auto now = Time::Now;
   auto newDelta = (lastDeltaAt==0)?0:now-lastDeltaAt;
   lastDeltaAt = now;

   return newDelta;
}

// source: MXRandom
int GetFinishTime() {
    auto app = cast<CTrackMania>(GetApp());
    auto playground = cast<CSmArenaClient>(app.CurrentPlayground);
    auto script = cast<CSmArenaRulesMode>(app.PlaygroundScript);

    int finishTime = -1;

    if (playground !is null && script !is null && playground.GameTerminals.Length > 0) {
        auto terminal = playground.GameTerminals[0];
        auto player = cast<CSmPlayer>(terminal.ControlledPlayer);
        if (player !is null) {
            auto seq = terminal.UISequence_Current;
            if (seq == SGamePlaygroundUIConfig::EUISequence::Finish || seq == SGamePlaygroundUIConfig::EUISequence::UIInteraction) {
                CSmScriptPlayer@ playerScriptAPI = cast<CSmScriptPlayer>(player.ScriptAPI);
                auto ghost = script.Ghost_RetrieveFromPlayer(playerScriptAPI);
                if (ghost !is null) {
                    if (ghost.Result.Time > 0 && ghost.Result.Time < uint(-1)) {
                        finishTime = ghost.Result.Time;
                    }
                    script.DataFileMgr.Ghost_Release(ghost.Id);
                }
            }
        }
    }

    return finishTime;
}