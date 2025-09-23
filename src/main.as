
void Main() {
   if (!Permissions::PlayLocalMap()) {
      UI::ShowNotification(PLUGIN_NAME, "Unable to play local maps.\n(Missing Club Access?)", COLOR_ERROR);
      return;
   }
   print("Starting: " + PLUGIN_NAME + "...");
   // TODO start in a disabled mode?
   Visible = true;

   while (true) {
      Run(calculateDelta());
      yield();
   }
}
