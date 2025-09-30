uint64 shownSkipCostTimerAt = 0;
uint64 shownNewScoreTimerAt = 0;

int64 lastSkipCost = 0;
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
    // UI::SetNextWindowSize(350, 600); // not compatible with UI::WindowFlags::AlwaysAutoResize
    UI::Begin(SHORT_NAME_WITH_ICON, UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoCollapse);
    if (game is null) {
        DisplayStartScreen();
    } else {
        DisplayGameScreen();
    }

    // DEBUG();

    UI::End();
    UI::PopStyleVar(styleVarCount);
}

void DisplayGameScreen() {
    RenderTimer(ProgressIcon(), COLOR_GREEN, game.timer, shownSkipCostTimerAt, lastSkipCost);
    RenderTimer(Icons::Tachometer, COLOR_YELLOW, game.score, shownNewScoreTimerAt, lastScore);
    RenderPB();
    UI::NewLine();
    UI::Separator();


    int secondColumn = WINDOW_PADDING + 103;
    RenderTinyTimer(Icons::ClockO, COLOR_GRAY_LIGHT, game.TotalTimeSpent());
    UI::SetCursorPosX(secondColumn);
    RenderTinyTimer(Icons::ClockO, COLOR_GRAY_LIGHT, game.CurrentTimeSpent());
    UI::NewLine();
    if (game.IsFinished()) {
        // TODO stats
        // RenderTiny(Icons::Road, COLOR_GRAY_LIGHT, "" + CurrentMapCount());
        // UI::SetCursorPosX(secondColumn);
        // RenderTiny(Icons::Forward, COLOR_GRAY_LIGHT, "" + CurrentMapsSkipped());
        // UI::NewLine();
    }
   
    if (game.IsInProgress()) {
        auto currentSkipCost = game.CurrentSkipPenalty();
        UI::Separator();
        // Medals
        for( int m = Medals::None; m <= Medals::Author; m++ ) {
            auto color = game.HasMedal(Medals(m)) ? MedalColor(Medals(m)) : COLOR_GRAY_DARK;
            UI::PushStyleColor(UI::Col::Text, color);
            UI::Text(m == Medals::None?Icons::FlagCheckered:Icons::Circle); UI::SameLine();
            UI::PopStyleColor();
        }
        UI::NewLine();

        // Next Map
        UI::PushFontSize(18);
        if (UI::ButtonColored(Icons::Forward + "  Next Map ", 0.860)) {
            game.SkipToNextMap();
        }
        UI::PopFontSize();

        // Cost
        UI::Text(Icons::HourglassHalf); UI::SameLine();
        auto penaltyLabel = currentSkipCost==0 ? "Free" : clock(currentSkipCost);
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
    auto pauseLabel = game.IsPaused()?Icons::Play:Icons::Pause;
    if (UI::ButtonColored(pauseLabel, 0.3f)) {
        game.TogglePause();
    }
    UI::SameLine();
    UI::SetCursorPosX(92);
    if (UI::ButtonColored(Icons::TimesCircleO + "Broken", 0.15f)) {
        if (game.IsInProgress()) game.SkipBrokenMap();
    }
    UI::SameLine();
    if (UI::ButtonColored(Icons::Times + "Reset", 0.0f)) {
        Reset();
    }
    UI::PopFontSize();
}

void modeComboItem(ChallengeMode id) {
        UI::PushID(ModeName(id));
        if (UI::Selectable(ModeName(id), SelectedChallengeMode == id)) {
            SelectedChallengeMode = id;
        }
        UI::PopID();
}

void DisplayStartScreen() {
    UI::PushFontSize(18);
    UI::Text("Challenge Target");
    UI::PopFontSize();
    UI::PushItemWidth(140);
    if(UI::BeginCombo("##ChallengeTarget", ModeName(SelectedChallengeMode))) {
        modeComboItem(ChallengeMode::Author60);
        modeComboItem(ChallengeMode::Gold60);
        UI::EndCombo();
    }
    UI::PopItemWidth();
    
    UI::PushFontSize(14);
    UI::SameLine();
    UI::SetCursorPosX(170);
    RenderPB();
    UI::NewLine();
    UI::Separator();

    UI::Markdown("**Goal**  \nCollect Time ("+Icons::Tachometer+") until the Timer ("+Icons::HourglassStart+") runs out.");
    UI::NewLine();
    UI::Markdown("**Details**  \nYou only get scored if you beat the " + ModeMedalName(SelectedChallengeMode) + " time. The score you "+
            "gain into your Time is calculated from map length and your finishing time. You can skip any map, "+
            "but time may be substracted from the Timer. The cost is displayed under the skip button "+
            "and is based on the medals you have earned so far.");
    UI::Markdown("**If not stated otherwise, RMC rules apply.**");
    UI::PopFontSize();
    UI::NewLine();
    UI::PushFontSize(12);
    UI::Markdown("**Disclaimer**");
    UI::Text("Beta Version, be kind  " + "\\$F00" + Icons::HeartO + "\\$z");
    UI::NewLine();
    UI::Text("Built on and inspired by " + "\\$AAA" + "ManiaExchange Random Map Picker" + "\\$z");
    UI::PopFontSize();

    UI::Separator();
    auto label = Icons::Play + " Start ";
    UI::PushFontSize(20);
    if (UI::ButtonColored(label, 0.3f)) {
        StartNewGame(SelectedChallengeMode);
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

        auto pos = UI::GetCursorPos();
        UI::PushStyleColor(UI::Col::Text, color);
        UI::PushFontSize(38);
        UI::Text(clock(value)); UI::SameLine();
        UI::PopFontSize();
        UI::PopStyleColor();

        UI::SetCursorPos(vec2(pos.x + 90, pos.y - 9));
        auto extraColor = fadeoutTimerColor(color, extraTimerStart);
        UI::PushStyleColor(UI::Col::Text, extraColor);
        UI::PushFontSize(15);
        UI::Text((extraValue>0?"+":"") + clock(extraValue));
        UI::PopFontSize();
        UI::PopStyleColor();
}

void RenderPB() {
    RenderTiny(Icons::Trophy, COLOR_GRAY_DARK, clock(PersonalBest(SelectedChallengeMode)));
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
    if (game is null) return Icons::HourglassO;

    auto progress = float(game.timer) / float(DEFAULT_TIME);
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
    RenderTimer(ProgressIcon(), COLOR_GREEN, ONE_HOUR - 1, Time::Now, -3*ONE_MINUTE);
    RenderTimer(Icons::Tachometer, COLOR_YELLOW, ONE_HOUR - 1, Time::Now, ONE_MINUTE);
}