const bool DEV_MODE = Meta::IsDeveloperMode();
const string RECORDS_URL = "https://openplanet.dev/plugin/randommappace/config/records";

const int WINDOW_PADDING = 8;
const int WINDOW_WIDTH = 205;

const string VERSION = Meta::ExecutingPlugin().Version;
const int SCORING_VERSION = 1;

const string PLUGIN_ICON = "\\$D3D" + Icons::Tachometer + "\\$z";
const string PLUGIN_NAME = "Random Map Pace Challenge";
const string SHORT_NAME = "Random Map Pace";
const string PLUGIN_NAME_WITH_ICON = PLUGIN_ICON + " " + PLUGIN_NAME;
const string SHORT_NAME_WITH_ICON = PLUGIN_ICON + " " + SHORT_NAME;


const vec4 COLOR_WHITE = vec4(1.0f, 1.0f, 1.0f, 1.0f);
const vec4 COLOR_TAN = vec4(0.9f, 0.8f, 0.7f, 1.0f);
const vec4 COLOR_GRAY_DARK = vec4(0.3f, 0.3f, 0.3f, 1.0f);
const vec4 COLOR_GRAY_LIGHT = vec4(0.4f, 0.4f, 0.4f, 1.0f);
const vec4 COLOR_GREEN = vec4(0.3f, 0.8f, 0.5f, 1.0f);
const vec4 COLOR_DARK_GREEN = vec4(0.0f, 0.7f, 0.2f, 1.0f);
const vec4 COLOR_YELLOW = vec4(0.9f, 0.9f, 0.3f, 1.0f);
const vec4 COLOR_RED_ISH = vec4(0.9f, 0.1f, 0.2f, 1.0f);
const vec4 COLOR_PURPLISH = vec4(0.87f, 0.20f, 0.87f, 1.0f);
const vec4 COLOR_ERROR = COLOR_RED_ISH;

const int64 ONE_SECOND = 1000;
const int64 ONE_MINUTE = 60 * ONE_SECOND;
const int64 ONE_HOUR = 60 * ONE_MINUTE;

const int64 MAX_MAP_LENGTH = 3 * ONE_MINUTE;
