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
        UI::PushStyleVar(UI::StyleVar::WindowPadding, vec2(WINDOW_PADDING, WINDOW_PADDING - 2));
        UI::PushStyleVar(UI::StyleVar::WindowRounding, 4.0);
        UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(4, 4));
        UI::PushStyleVar(UI::StyleVar::WindowTitleAlign, vec2(0.5, 0.5));
    }
    // UI::SetNextWindowSize(350, 600); // not compatible with UI::WindowFlags::AlwaysAutoResize
    UI::Begin(SHORT_NAME_WITH_ICON, UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoCollapse);

    UI::Dummy(vec2(WINDOW_WIDTH, 0));

    if (game is null) {
        DisplayStartScreen();
    } else {
        DisplayGameScreen();
        DEBUG();
    }

    // DEBUG();

    // UI::PushFontSize(9);
    // UI::PushStyleColor(UI::Col::Text, COLOR_GRAY_DARK);
    // UI::SetCursorPosY(170);
    // UI::Text("Version: " + VERSION);
    // UI::PopStyleColor();
    // UI::PopFontSize();

    UI::End();
    UI::PopStyleVar(styleVarCount);
}

void DisplayGameScreen() {
    RenderTimer(ProgressIcon(), COLOR_GREEN, game.timer, shownSkipCostTimerAt, lastSkipCost);
    RenderTimer(Icons::Tachometer, COLOR_YELLOW, game.score, shownNewScoreTimerAt, lastScore);
    RenderPB();
    UI::NewLine();
    UI::Separator();

    auto autoPaused = IsAutoPaused();

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
        UI::Separator();

        // UI::Text(Icons::Map);
        // UI::PushStyleColor(UI::Col::Text, COLOR_GRAY_LIGHT); UI::SameLine();
        // const int maxMapNameLength = 22;
        // UI::Text(game.CurrentMapName(), maxMapNameLength); UI::SameLine();
        // game.CurrentMapName().Length > maxMapNameLength ? UI::Text("...") : UI::NewLine();
        // UI::PopStyleColor();

        UI::Text(Icons::Tachometer); UI::SameLine();
        UI::PushStyleColor(UI::Col::Text, COLOR_GRAY_LIGHT);
        UI::Text("+" + clock(game.PossibleScoreMin()) + "–" + clock(game.PossibleScoreMax())); UI::SameLine();
        UI::PopStyleColor();
        UI::NewLine();


        // Medals
        RenderUnfinishedIcon();
        for( int m = Medals::None; m <= Medals::Author; m++ ) {
            auto color = game.HasMedal(Medals(m)) ? MedalColor(Medals(m)) : COLOR_GRAY_DARK;
            UI::PushStyleColor(UI::Col::Text, color);
            UI::Text(m == Medals::None?Icons::FlagCheckered:Icons::Circle); UI::SameLine();
            UI::PopStyleColor();
        }
        UI::NewLine();

        // Next Map
        UI::PushFontSize(18);
        string nextLabel = Icons::Forward + "  Next Map ";
        auto nextButton = game.IsPaused() ?DisabledButton(nextLabel) : UI::ButtonColored(nextLabel, 0.860f);
        if (nextButton) {
            game.SkipToNextMap();
        }
        UI::PopFontSize();

        // Cost
        auto currentSkipCost = game.CurrentSkipPenalty();
        UI::Text(Icons::HourglassHalf); UI::SameLine();
        auto penaltyLabel = currentSkipCost >= -99 ? "Free" : clock(currentSkipCost);
        if (autoPaused) { penaltyLabel = "???"; }
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

bool DisabledButton(const string label) {
    UI::ButtonColored(label, 0.0f, 0.0f, 0.3f);
    return false;
}

void RenderBottomRowButtons() {
    UI::PushFontSize(13);
    auto pauseLabel = game.IsPaused()?Icons::Play:Icons::Pause;
    if (UI::ButtonColored(pauseLabel, 0.3f)) {
        game.TogglePause();
    }
    UI::SameLine();
    UI::SetCursorPosX(92);
    string brokenLabel = Icons::TimesCircleO + "Broken";
    auto brokenButton = game.IsPaused() ? DisabledButton(brokenLabel) : UI::ButtonColored(brokenLabel, 0.15f);
    if (brokenButton) {
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
    
    UI::PushFontSize(15);
    UI::SameLine();
    // UI::SetCursorPosX(165);
    UI::NewLine();
    RenderPB();
    UI::NewLine();
    UI::Separator();

    UI::Markdown("**Goal**");
    UI::Text("Collect Time ("+Icons::Tachometer+") until  \nthe Timer ("+Icons::HourglassStart+") runs out.");
    // UI::NewLine();

    auto detailsIcon = detailsHidden ? Icons::ChevronDown : Icons::ChevronUp;
    if (UI::ButtonColored(detailsIcon + " Details ", 0, 0, 0.3)) {
        detailsHidden = !detailsHidden;
    }
    UI::PopFontSize();

    if (!detailsHidden) {
        UI::PushFontSize(13);
        UI::Markdown("You only get scored if you beat the " + ModeMedalName(SelectedChallengeMode) + " time. The score you "+
                "gain into your Time is calculated from the map length and your finishing time. You can skip any map, "+
                "but time may be substracted from the Timer. The cost is displayed under the skip button "+
                "and is based on your best finishing time.");
        UI::Markdown("**If not stated otherwise, RMC rules apply.**");
        UI::PopFontSize();
    }

    
    UI::NewLine();
    UI::PushFontSize(12);
    UI::Markdown("**Disclaimer**");
    UI::Text("Beta Version, be kind  " + "\\$F00" + Icons::HeartO + "\\$z");
    UI::NewLine();
    UI::Markdown("**Built on and inspired by**");
    UI::Text("\\$AAA" + "ManiaExchange Random Map Picker" + "\\$z");
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

void RenderUnfinishedIcon() {
    auto pos = UI::GetCursorPos();
    UI::Text(Icons::FlagCheckered);
    UI::SetCursorPos(pos);
    UI::PushStyleColor(UI::Col::Text, COLOR_RED_ISH);
    UI::Text(Icons::Times); UI::SameLine();
    UI::PopStyleColor();
}

string ProgressIcon() {
    if (game is null) return Icons::HourglassO;

    auto progress = float(game.timer) / float(ONE_HOUR);
    if (progress > 0.75f) {
        return Icons::HourglassStart;
    } else if (progress > 0.25f) {
        return Icons::HourglassHalf;
    } else {
        return Icons::HourglassEnd;
    }
}

void ShowLastSkip(int64 cost) {
    if (cost >= -99) return;
    shownSkipCostTimerAt = Time::Now;
    lastSkipCost = cost;

}

void ShowLastScore(int64 score) {
    shownNewScoreTimerAt = Time::Now;
    lastScore = score;
}

void DEBUG() {
    if (game is null) return;
    int skipUnfinishedCount = game.MedalStats(Medals(SKIP_UNFINISHED_INDEX));
    auto pos = UI::GetCursorPos();
    UI::Text(Icons::FlagCheckered);
    UI::SetCursorPos(pos);
    UI::PushStyleColor(UI::Col::Text, COLOR_RED_ISH);
    UI::Text(Icons::Times); UI::SameLine();
    UI::PopStyleColor();
    UI::Text("" + skipUnfinishedCount);
    UI::SameLine();

    int totalSkipped = 0;
    int totalFinished = 0;
    for( int m = Medals::None; m <= Medals::Author; m++ ) {
        auto mCount = game.MedalStats(Medals(m));
        UI::PushStyleColor(UI::Col::Text, MedalColor(Medals(m)));
        UI::Text((m == Medals::None?Icons::FlagCheckered:Icons::Circle)); UI::SameLine();
        UI::PopStyleColor();
        UI::Text("" + mCount);
        if (m != Medals::None) UI::SameLine();
        if (m >= game.TargetMedal()) {
            totalFinished += mCount;
        } else {
            totalSkipped += mCount;
        }
    }
    UI::NewLine();

    UI::PushStyleColor(UI::Col::Text, COLOR_PURPLISH);
    UI::Text(Icons::Forward); UI::SameLine();
    UI::PopStyleColor();
    UI::Text("" + (skipUnfinishedCount + totalSkipped));

    UI::PushStyleColor(UI::Col::Text, COLOR_IDK_COLOR_NAMES);
    UI::Text(Icons::Map); UI::SameLine();
    UI::PopStyleColor();
    UI::Text("" + (skipUnfinishedCount + totalSkipped + totalFinished));

    int skipBrokenCount = game.MedalStats(Medals(SKIP_BROKEN_INDEX));
    UI::PushStyleColor(UI::Col::Text, COLOR_RED_ISH);
    UI::Text(Icons::TimesCircleO); UI::SameLine();
    UI::PopStyleColor();
    UI::Text("" + skipBrokenCount);
}
