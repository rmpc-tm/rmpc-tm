uint64 shownSkipCostTimerAt = 0;
uint64 shownNewScoreTimerAt = 0;

int64 lastSkipCost = 0;
int64 lastScore = 0;

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