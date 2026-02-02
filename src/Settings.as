[Setting hidden]
bool Visible = false;

[Setting hidden]
int ScoringVersion = 1;

[Setting hidden]
int64 PersonalBestAuthor60 = 0;

[Setting hidden]
WorldRecord WRAuthor60;

[Setting hidden]
int64 PersonalBestGold60 = 0;

[Setting hidden]
WorldRecord WRGold60;

[Setting hidden]
ChallengeMode SelectedChallengeMode = ChallengeMode::Author60;

[Setting hidden]
bool CustomMaps = false;

[SettingsTab name="Random Map Pace Challenge" order="1" icon="Tachometer"]
void RenderSettings() {
    CustomMaps = UI::Checkbox("Use custom map filters", CustomMaps);
    UI::SameLine();
    UI::Text("\\$AAA" + "(configured in MX Random)" + "\\$z");
    UI::Separator();

    if (UI::ButtonColored("Reset PBs", 0.15f)) {
        PersonalBestGold60 = 0;
        PersonalBestAuthor60 = 0;
    }
    UI::SameLine();
    UI::Text("\\$AAA" + "Set local personal best scores to 0" + "\\$z");
}
