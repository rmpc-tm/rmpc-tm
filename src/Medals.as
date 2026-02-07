
enum Medals {
    Broken = -2,
    Unfinished = -1,
    None = 0, // Finished
    Bronze,
    Silver,
    Gold,
    Author,
}

string MedalName(Medals medal) {
    switch(medal) {
        case Medals::Author:
            return "Author";
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
        case Medals::Broken:
            return COLOR_RED_ISH;
        case Medals::Unfinished:
            return COLOR_WHITE;
        default:
            return vec4(0.88, 0.88, 0.88, 1);
    }
}
