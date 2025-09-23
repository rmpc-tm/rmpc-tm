
void RenderMenu() {
        if (UI::MenuItem(PLUGIN_NAME_WITH_ICON, "", Visible)) {
            Visible = !Visible;
            if (!Visible) {
                Stop();
            }
        }
}
