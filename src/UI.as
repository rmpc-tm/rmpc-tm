uint64 shownSkipCostTimerAt = 0;
uint64 shownNewScoreTimerAt = 0;

int64 lastSkipCost = - 4 * MAX_MAP_LENGTH;
int64 lastScore = 0;


void Render() {
    if (!Visible) {
        return;
    }

    const int styleVarCount = 4;
    {
        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(WINDOW_PADDING, WINDOW_PADDING));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 5.0);
        UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(5, 5));
        UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(0.5, 0.5));
    }

    UI::Begin(SHORT_NAME_WITH_ICON, UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoCollapse | UI::WindowFlags::NoResize);

    if (GameInProgress() || GameFinished()) {
        DisplayGameScreen();
    } else {
        // DisplayGameScreen();
        DisplayStartScreen();
    }

    UI::End();
    UI::PopStyleVar(styleVarCount);
}

void DisplayGameScreen() {
    RenderTimer(ProgressIcon(), COLOR_GREEN, gameTimerMs, 0, 0);
    RenderTimer(Icons::Tachometer, COLOR_YELLOW, scoreTimerMs, shownNewScoreTimerAt, lastScore);
    RenderPB();
    UI::NewLine();
    UI::Separator();


    int secondColumn = 110 + WINDOW_PADDING;
    RenderTinyTimer(Icons::ClockO, COLOR_GRAY_LIGHT, TotalTimeSpent());
    UI::SetCursorPosX(secondColumn);
    RenderTinyTimer(Icons::ClockO, COLOR_GRAY_LIGHT, CurrentTimeSpent());
    UI::NewLine();
    if (GameFinished()) {
        RenderTiny(Icons::Road, COLOR_GRAY_LIGHT, "" + CurrentMapCount());
        UI::SetCursorPosX(secondColumn);
        RenderTiny(Icons::Forward, COLOR_GRAY_LIGHT, "" + CurrentMapsSkipped());
        UI::NewLine();
    }

    // RenderTiny(Icons::Tachometer, COLOR_GRAY_LIGHT, "+" + clock(LiveScore()));
    // UI::NewLine();
    
    if (GameInProgress()) {
        UI::Separator();
        // Medals
        for( int m = Medals::None; m <= Medals::Author; m++ ) {
            auto color = HasMedal(Medals(m)) ? MedalColor(Medals(m)) : COLOR_GRAY_DARK;
            UI::PushStyleColor(UI::Col::Text, color);
            UI::Text(m == Medals::None?Icons::FlagCheckered:Icons::Circle); UI::SameLine();
            UI::PopStyleColor();
        }
        UI::NewLine();

        // Next Map
        UI::PushFontSize(18);
        if (UI::ButtonColored(Icons::Forward + "  Next Map ", 0.860)) {
            ShowLastSkip(CurrentSkipPenalty());
            SkipToNextMap();
        }
        UI::PopFontSize();

        // Cost
        UI::Text(Icons::HourglassHalf); UI::SameLine();
        auto penaltyLabel = CurrentSkipPenalty()==0 ? "Free" : clock(CurrentSkipPenalty());
        if (IsAutoPaused()) { penaltyLabel = "???"; }
        UI::PushStyleColor(UI::Col::Text, COLOR_GREEN);
        UI::Text(penaltyLabel); UI::SameLine();
        UI::PopStyleColor();
    } else {
        UI::Text("Finished, yay!"); UI::SameLine();
    }

    UI::NewLine();
    UI::Separator();

    // Bottom Row UI
    RenderBottomRowButtons();
}

void RenderBottomRowButtons() {
    UI::PushFontSize(13);
    auto pauseLabel = isPaused?Icons::Play:Icons::Pause;
    if (UI::ButtonColored(pauseLabel, 0.3f)) {
        TogglePause();
    }
    UI::SameLine();
    UI::SetCursorPosX(108);
    if (UI::ButtonColored(Icons::TimesCircleO + "Broken", 0.15f)) {
        if (GameInProgress()) FreeSkip();
    }
    UI::SameLine();
    if (UI::ButtonColored(Icons::Times + "Reset", 0.0f)) {
        Reset();
    }
    UI::PopFontSize();
}

void DisplayStartScreen() {
    UI::PushFontSize(18);
    UI::Text("Timer:"); UI::SameLine(); UI::Text(clock(DEFAULT_TIME));
    UI::Text("Mode:"); UI::SameLine(); UI::Text(DEFAULT_MODE);

    UI::PopFontSize();
    
    UI::PushFontSize(15);
    RenderPB();
    UI::NewLine();
    UI::Separator();
    UI::Text("Goal:\nCollect Time by beating ATs until the timer runs out.");
    UI::Text("Details:\nYou only get scored if you beat the AT. The time you\n"+
            "gain into your score  ("+Icons::Tachometer+" icon)  is calculated from\n"+
            "your finishing time. You can skip any map,\n"+
            "but time may be substracted from your remaining\n"+
            "time.  The cost is displayed under to the skip button\n"+
            "and is based on the medals you have earned so far.");
    UI::Text("If not stated otherwise, RMC rules apply.");
    UI::PopFontSize();
    UI::NewLine();
    UI::PushFontSize(12);
    UI::Text("Disclaimer:\nPre-release Alpha Version, be kind " + "\\$F00" + Icons::HeartO + "\\$z");
    UI::Text("Credits:\nBuilt on and inspired by " + "\\$AAA" + "ManiaExchange Random Map Picker" + "\\$z");
    UI::PopFontSize();

    UI::Separator();
    auto label = Icons::Play + " Start ";
    UI::PushFontSize(20);
    if (UI::ButtonColored(label, 0.3f)) {
        StartNewGame(DEFAULT_TIME, DEFAULT_MODE);
    }
    UI::PopFontSize();
}

string clock(int64 ms) {
    return Time::Format(ms, true, false, false, true);
}

vec4 fadeoutTimerColor(vec4 bc, int64 t) {
    auto td = Time::Now - t;
    if (td > DISPLAY_EXTRA_TIMER_FOR) {
        return vec4(0,0,0,0);
    }
    if (td < DISPLAY_EXTRA_TIMER_FULL_APHA) {
        return bc;
    }

    auto alpha = float(DISPLAY_EXTRA_TIMER_FOR - td) / float(DISPLAY_EXTRA_TIMER_FOR - DISPLAY_EXTRA_TIMER_FULL_APHA);
    return vec4(bc.x, bc.y, bc.z, Math::Max(alpha, 0));
}

void RenderTimer(const string icon, vec4 color, int64 value, int64 extraTimerStart = 0, int64 extraValue = 0) {
        UI::PushFontSize(15);
        UI::Text(icon); UI::SameLine();
        UI::PopFontSize();

        UI::PushStyleColor(UI::Col::Text, color);
        UI::PushFontSize(38);
        UI::Text(clock(value)); UI::SameLine();
        UI::PopFontSize();
        UI::PopStyleColor();

        auto extraColor = fadeoutTimerColor(color, extraTimerStart);
        UI::PushStyleColor(UI::Col::Text, extraColor);
        UI::PushFontSize(15);
        UI::Text((extraValue>0?"+":"") + clock(extraValue));
        UI::PopFontSize();
        UI::PopStyleColor();
}

void RenderPB() {
    RenderTiny(Icons::Trophy, COLOR_GRAY_DARK, clock(PersonalBest));
}

void RenderTinyTimer(const string icon, vec4 color, int64 time) {
    RenderTiny(icon, color, clock(time));
}

void RenderTiny(const string icon, vec4 color, const string value) {
    UI::PushStyleColor(UI::Col::Text, color);
    UI::PushFontSize(15);
    UI::Text(icon);
    UI::SameLine();
    UI::PopFontSize();
    UI::PushFontSize(20);
    UI::Text(value); UI::SameLine();
    UI::PopFontSize();
    UI::PopStyleColor();
}


string ProgressIcon() {
    auto progress = float(gameTimerMs) / float(DEFAULT_TIME);
    if (progress > 0.75f) {
        return Icons::HourglassStart;
    } else if (progress > 0.25f) {
        return Icons::HourglassHalf;
    } else {
        return Icons::HourglassEnd;
    }
}

void ShowLastSkip(int64 cost) {
    if (cost == 0) return;
    shownSkipCostTimerAt = Time::Now;
    lastSkipCost = cost;

}

void ShowLastScore(int64 score) {
    shownNewScoreTimerAt = Time::Now;
    lastScore = score;
}


void DEBUG() {
    UI::Separator();
    UI::Text("AT: " + clock(currentMap.medals[Medals::Author]));
    UI::Text("Gold: " + clock(currentMap.medals[Medals::Gold]));
    UI::Text("Silver: " + clock(currentMap.medals[Medals::Silver]));
    UI::Text("Bronze: " + clock(currentMap.medals[Medals::Bronze]));
    UI::NewLine();
    UI::Text("PB: " + clock(currentMap.pbFinishTime));
    UI::Text("Last: " + clock(currentMap.lastFinishTime));
    UI::Text("Medal: " + MedalName(currentMap.EarnedMedal()));
    UI::NewLine();

    UI::Separator();

}