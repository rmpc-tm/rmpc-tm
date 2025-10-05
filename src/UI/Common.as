
bool DisabledButton(const string label) {
    UI::ButtonColored(label, 0.0f, 0.0f, 0.3f);
    return false;
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

string clock(int64 ms) {
    return Time::Format(ms, true, false, false, true);
}

void RenderMedalIcon(Medals medal) {
    string icon;
    switch(medal) {
        case Medals::Broken:
            icon = Icons::TimesCircleO;
            break;
        case Medals::Unfinished:
        case Medals::None:
            icon = Icons::FlagCheckered;
            break;
        default:
            icon = Icons::Circle;
            break;
    }
    auto pos = UI::GetCursorPos();
    UI::PushStyleColor(UI::Col::Text, MedalColor(medal));
    UI::Text(icon); UI::SameLine();
    if (medal == Medals::Unfinished || medal == Medals::None) {
        UI::SetCursorPos(pos);
        auto fIcon = medal == Medals::Unfinished ? Icons::Times : Icons::Check;
        auto fColor = medal == Medals::Unfinished ? COLOR_RED_ISH : COLOR_DARK_GREEN;
        UI::PushStyleColor(UI::Col::Text, fColor);
        UI::Text(fIcon); UI::SameLine();
        UI::PopStyleColor();
    }
    UI::PopStyleColor();
}