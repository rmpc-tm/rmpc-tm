bool detailsHidden = true;

// Main
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
    }

    UI::End();
    UI::PopStyleVar(styleVarCount);
}

/* Start Screen */
void DisplayStartScreen() {
    UI::PushFontSize(18);
    UI::Text("Challenge Settings");
    UI::PopFontSize();
    UI::PushItemWidth(140);
    if(UI::BeginCombo("##ChallengeTarget", ModeName(SelectedChallengeMode))) {
        GameModeComboItem(ChallengeMode::Author60);
        GameModeComboItem(ChallengeMode::Gold60);
        UI::EndCombo();
    }
    UI::PopItemWidth();

    if (CustomMaps) {
        UI::Text("Custom filters enabled.");
    } else {
        if (RenderPB()) UI::NewLine();
        if (RenderWR()) UI::NewLine();
    }
    UI::Separator();

    UI::Markdown("**Goal**");
    UI::Text("Collect Time ("+Icons::Tachometer+") until  \nthe Timer ("+Icons::HourglassStart+") runs out.");

    auto detailsIcon = detailsHidden ? Icons::ChevronDown : Icons::ChevronUp;
    if (UI::ButtonColored(detailsIcon + " More Details ", 0, 0, 0.3)) {
        detailsHidden = !detailsHidden;
    }

    if (!detailsHidden) {
        UI::PushFontSize(13);
        UI::Markdown("You only get scored if you beat the " + ModeMedalName(SelectedChallengeMode) + " time. The score you "+
                "gain into your Time is calculated from the map length and your finishing time. You can skip any map, "+
                "but time may be subtracted from the Timer. The cost is displayed under the skip button "+
                "and is based on your best finishing time.");
        UI::NewLine();
        UI::Markdown("**If not stated otherwise, RMC rules apply.**");
        UI::PopFontSize();
    }

    UI::PushFontSize(12);
    UI::NewLine();
    UI::Markdown("**Built on and inspired by**");
    UI::Text("\\$AAA" + "ManiaExchange Random Map Picker" + "\\$z");
    UI::PopFontSize();

    UI::Separator();
    auto label = Icons::Play + " Start ";
    UI::PushFontSize(20);
    if (UI::ButtonColored(label, 0.3f)) {
        StartNewGame(SelectedChallengeMode, CustomMaps);
    }
    UI::PopFontSize();
}

void GameModeComboItem(ChallengeMode id) {
        UI::PushID(ModeName(id));
        if (UI::Selectable(ModeName(id), SelectedChallengeMode == id)) {
            SelectedChallengeMode = id;
        }
        UI::PopID();
}
