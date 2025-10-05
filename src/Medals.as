
const int SKIP_UNFINISHED_INDEX = 5;
const int SKIP_BROKEN_INDEX = 6;

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
        default:
            return vec4(0.88, 0.88, 0.88, 1);
    }
}
