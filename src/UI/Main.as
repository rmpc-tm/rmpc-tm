bool recordsHidden = true;
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

    auto flags = UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoScrollbar | UI::WindowFlags::NoCollapse;
    if (game is null) {
        // Home Screen can be closed
        UI::Begin(SHORT_NAME_WITH_ICON, Visible, flags);
        UI::Dummy(vec2(WINDOW_WIDTH, 0));
        DisplayStartScreen();
        UI::End();
    } else {
        UI::Begin(SHORT_NAME_WITH_ICON, flags);
        UI::Dummy(vec2(WINDOW_WIDTH, 0));
        DisplayGameScreen();
        UI::End();
    }

    UI::PopStyleVar(styleVarCount);
}

/* Start Screen */
void DisplayStartScreen() {
    UI::PushFontSize(18);
    UI::Text("Select Goal");
    UI::PopFontSize();
    UI::PushItemWidth(140);
    if(UI::BeginCombo("##ChallengeTarget", ModeName(SelectedChallengeMode))) {
        GameModeComboItem(ChallengeMode::Author60);
        GameModeComboItem(ChallengeMode::Gold60);
        UI::EndCombo();
    }
    UI::PopItemWidth();

    if (CustomMaps) {
        UI::Text(Icons::ExclamationCircle + " Custom filters enabled.");
    } else {
        auto recordsIcon = recordsHidden ? Icons::ChevronDown : Icons::ChevronUp;
        if (UI::ButtonColored(recordsIcon + " Records ", 0.6, 0.6, 0.6)) {
            recordsHidden = !recordsHidden;
        }

        if (!recordsHidden) {
            UI::Text("Personal Best");
            RenderPB(); UI::NewLine();
            UI::Text("Global Records");
            RenderWRs();

            if (ScoreApiHost != "") {
                auto leaderBoardURL = ScoreApiHost + "/rmpc";
                UI::TextLinkOpenURL("Full Leaderboard", leaderBoardURL);
                RenderTooltip(leaderBoardURL);
            }
        }
    }

    UI::Separator();

    UI::Markdown("**Goal**");
    UI::Text("Collect Time "+Icons::Tachometer+" until  \nyour Time "+Icons::HourglassStart+" runs out.");

    auto detailsIcon = detailsHidden ? Icons::ChevronDown : Icons::ChevronUp;
    if (UI::ButtonColored(detailsIcon + " More Details ", 0, 0, 0.3)) {
        detailsHidden = !detailsHidden;
    }

    if (!detailsHidden) {
        UI::PushFontSize(13);
        UI::Markdown("Finish maps to earn Score (" + Icons::Tachometer + "). " +
                "Longer maps give more. " +
                "You can skip any map at any time — " +
                "skipping costs remaining Timer (" + Icons::HourglassStart + ") " +
                "based on how close to the goal you got.");
        UI::PushFontSize(3); UI::NewLine(); UI::PopFontSize();
        UI::Markdown("Read more in plugin description.");
        UI::PopFontSize();
    }

    UI::PushFontSize(12);
    UI::NewLine();
    UI::Text("\\$AAA" + "Requires MX Random Map Picker" + "\\$z");
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
