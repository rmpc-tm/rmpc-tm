const int64 DISPLAY_EXTRA_TIMER_FOR = 5 * 1000;
const int64 DISPLAY_EXTRA_TIMER_FULL_ALPHA = 5 * 900;

uint64 shownSkipCostTimerAt = 0;
uint64 shownNewScoreTimerAt = 0;

int64 lastSkipCost = 0;
int64 lastScore = 0;

bool completeRunHidden = true;

/* Game Screen */
void DisplayGameScreen() {
    DisplayGameHeader();
    UI::Separator();

    if (game.IsInProgress()) {
        DisplayInProgressScreen();
    }
    if (game.IsFinished()) {
        DisplayFinishedScreen();
    }
    UI::Separator();

    RenderBottomRowButtons();
}

void DisplayGameHeader() {
    // Game Timers + PB
    RenderTimer(ProgressIcon(), COLOR_GREEN, game.timer, shownSkipCostTimerAt, lastSkipCost);
    RenderTooltip("Time Remaining");
    RenderTimer(Icons::Tachometer, COLOR_YELLOW, game.score, shownNewScoreTimerAt, lastScore);
    RenderTooltip("Score");
    if (RenderPB()) UI::NewLine();
    UI::Separator();

    // Timers
    int secondColumn = WINDOW_PADDING + 103;
    RenderTinyTimer(Icons::ClockO, game.IsFinished()?COLOR_WHITE:COLOR_GRAY_LIGHT, game.TotalTimeSpent());
    RenderTooltip("Time Spent (Total)");
    UI::SetCursorPosX(secondColumn);
    RenderTinyTimer(Icons::Map, COLOR_GRAY_LIGHT, game.CurrentTimeSpent());
    RenderTooltip("Time Spent (Current Map)");
    UI::NewLine();
}

void DisplayInProgressScreen() {
    auto autoPaused = IsAutoPaused();

    if (DEV_MODE) {
        // Map name
        UI::BeginGroup();
        UI::PushFontSize(12);
        UI::PushStyleColor(UI::Col::Text, COLOR_GRAY_LIGHT);
        UI::Text(game.CurrentMapName(), 35); UI::SameLine();
        UI::PopStyleColor();
        UI::PopFontSize();
        UI::EndGroup();
        RenderTooltip("Current Map");
    }

    // Possible bonus
    UI::BeginGroup();
    UI::Text(Icons::Tachometer); UI::SameLine();
    UI::PushStyleColor(UI::Col::Text, COLOR_GRAY_LIGHT);
    auto possibleScore = autoPaused?"???":"+" + clock(game.PossibleScoreMin()) + "–" + clock(game.PossibleScoreMax());
    UI::Text(possibleScore); UI::SameLine();
    UI::PopStyleColor();
    UI::EndGroup();
    RenderTooltip("Max Possible Score");

    // Medals
    UI::BeginGroup();
    auto currentMedal = game.CurrentMedal();
    RenderMedalIcon(currentMedal == Medals::Unfinished?Medals::Unfinished:Medals::None);
    for( int m = Medals::Bronze; m <= Medals::Author; m++ ) {
        auto color = game.HasMedal(Medals(m)) ? MedalColor(Medals(m)) : COLOR_GRAY_DARK;
        UI::PushStyleColor(UI::Col::Text, color);
        UI::Text(m == Medals::None?Icons::FlagCheckered:Icons::Circle); UI::SameLine();
        UI::PopStyleColor();
    }
    UI::EndGroup();
    RenderTooltip("Gained Medals");

    // Next Map
    UI::PushFontSize(18);
    string nextLabel = Icons::Forward + "  Next Map ";
    auto nextButton = game.IsPaused() ? DisabledButton(nextLabel) : UI::ButtonColored(nextLabel, 0.860f);
    if (nextButton) {
        game.SkipToNextMap();
    }
    UI::PopFontSize();

    // Cost
    UI::BeginGroup();
    auto currentSkipCost = game.CurrentSkipPenalty();
    UI::Text(Icons::HourglassHalf); UI::SameLine();
    auto penaltyLabel = currentSkipCost >= -99 ? "Free" : clock(currentSkipCost);
    if (autoPaused) { penaltyLabel = "???"; }
    UI::PushStyleColor(UI::Col::Text, COLOR_GREEN);
    UI::Text(penaltyLabel); UI::SameLine();
    UI::PopStyleColor();
    UI::EndGroup();
    RenderTooltip("Current Skip Cost");
}

void DisplayFinishedScreen() {
    // Stats
    UI::PushStyleColor(UI::Col::Text, COLOR_TAN);
    UI::Text(Icons::Map); UI::SameLine();
    UI::PopStyleColor();
    UI::Text("" + game.MapCount());
    UI::SameLine();

    UI::PushStyleColor(UI::Col::Text, COLOR_PURPLISH);
    UI::Text(Icons::Forward); UI::SameLine();
    UI::PopStyleColor();
    UI::Text("" + game.SkippedCount());

    // Medals
    for( int m = Medals::Bronze; m <= Medals::Author; m++ ) {
        RenderMedalIcon(Medals(m));
        UI::Text("" + game.MedalCount(Medals(m)));
        UI::SameLine();
    }
    UI::NewLine();

    // Complete Run
    auto detailsIcon = completeRunHidden ? Icons::ChevronDown : Icons::ChevronUp;
    if (UI::ButtonColored(detailsIcon + " Full run ", 0, 0, 0.3)) {
        completeRunHidden = !completeRunHidden;
    }

    if (!completeRunHidden) {
        auto medals = game.GetAllMedals();
        for (uint i=0; i < medals.Length; i++) {
            RenderMedalIcon(medals[i]);
            if ((i + 1) % 7 == 0) UI::NewLine();
        }
        UI::NewLine();
    }
}

void RenderBottomRowButtons() {
    UI::PushFontSize(13);

    // Pause
    auto pauseLabel = game.IsPaused()?Icons::Play:Icons::Pause;
    if (UI::ButtonColored(pauseLabel, 0.3f)) {
        game.TogglePause();
    }
    RenderTooltip(game.IsPaused() ? "Resume" : "Pause");
    UI::SameLine();

    // Skip Broken
    UI::SetCursorPosX(92);
    string brokenLabel = Icons::TimesCircleO + "Broken";
    auto brokenButton = game.IsPaused() ? DisabledButton(brokenLabel) : UI::ButtonColored(brokenLabel, 0.15f);
    if (brokenButton) {
        if (game.IsInProgress()) game.SkipBrokenMap();
    }
    RenderTooltip("Skip Broken Map");
    UI::SameLine();

    // Reset
    if (UI::ButtonColored(Icons::Times + "Reset", 0.0f)) {
        Reset();
    }
    RenderTooltip("End Game");

    UI::PopFontSize();
}

string ProgressIcon() {
    if (game is null) return Icons::HourglassO;
    auto progress = 1 - float(game.TotalTimeSpent()) / float(ONE_HOUR); // TODO hardcoded
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

vec4 fadeoutTimerColor(vec4 bc, int64 t) {
    auto td = Time::Now - t;
    if (td > DISPLAY_EXTRA_TIMER_FOR) {
        return vec4(0,0,0,0);
    }
    if (td < DISPLAY_EXTRA_TIMER_FULL_ALPHA) {
        return bc;
    }

    auto alpha = float(DISPLAY_EXTRA_TIMER_FOR - td) / float(DISPLAY_EXTRA_TIMER_FOR - DISPLAY_EXTRA_TIMER_FULL_ALPHA);
    return vec4(bc.x, bc.y, bc.z, Math::Max(alpha, 0));
}
