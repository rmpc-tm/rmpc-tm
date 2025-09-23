
// credit: https://github.com/XertroV/tm-green-timer/blob/0.2.2/src/GreenTimer.as#L89
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