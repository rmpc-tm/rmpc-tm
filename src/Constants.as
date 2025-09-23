const int WINDOW_PADDING = 10;

const string PLUGIN_ICON = "\\$D3D" + Icons::Tachometer + "\\$z";
const string PLUGIN_NAME = "Random Map Pace Challenge";
const string SHORT_NAME = "Random Map Pace";
const string PLUGIN_NAME_WITH_ICON = PLUGIN_ICON + " " + PLUGIN_NAME;
const string SHORT_NAME_WITH_ICON = PLUGIN_ICON + " " + SHORT_NAME;


const vec4 COLOR_GRAY_DARK = vec4(0.3f, 0.3f, 0.3f, 1.0f);
const vec4 COLOR_GRAY_LIGHT = vec4(0.4f, 0.4f, 0.4f, 1.0f);
const vec4 COLOR_GREEN = vec4(0.3f, 0.8f, 0.5f, 1.0f);
const vec4 COLOR_YELLOW = vec4(0.9f, 0.9f, 0.3f, 1.0f);
const vec4 COLOR_RED_ISH = vec4(0.9f, 0.1f, 0.2f, 1.0f);
const vec4 COLOR_PURPLISH = vec4(0.87f, 0.20f, 0.87f, 1.0f);
const vec4 COLOR_MAIN = COLOR_PURPLISH;
const vec4 COLOR_ERROR = COLOR_RED_ISH;

const int64 ONE_MINUTE = 60 * 1000;
const int64 ONE_HOUR = 60 * ONE_MINUTE;
const int64 DEFAULT_TIME = ONE_HOUR;
const string DEFAULT_MODE = "Author Time";

const int64 DISPLAY_EXTRA_TIMER_FOR = 5 * 1000;
const int64 DISPLAY_EXTRA_TIMER_FULL_APHA = 5 * 900;

const int64 MAX_MAP_LENGTH = 3 * 60 * 1000;

enum Medals {
   None,
   Bronze,
   Silver,
   Gold,
   Author
}

string MedalName(Medals medal) {
    switch(medal) {
        case Medals::Author:
            return "AT";
        case Medals::Gold:
            return "Gold";
        case Medals::Silver:
            return "Silver";
        case Medals::Bronze:
            return "Bronze";
        default:
            return "None";
    }
}

vec4 MedalColor(Medals medal) {
    switch(medal) {
        case Medals::Author:
            return vec4(0.00, 0.47, 0.03, 1);
        case Medals::Gold:
            return vec4(0.87, 0.74, 0.26, 1);
        case Medals::Silver:
            return vec4(0.54, 0.60, 0.60, 1);
        case Medals::Bronze:
            return vec4(0.60, 0.40, 0.26, 1);
        default:
            return vec4(0.88, 0.88, 0.88, 1);
    }
}