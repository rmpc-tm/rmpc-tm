
enum ChallengeMode {
    Author60,
    Gold60
}

int64 ModeTimer(ChallengeMode mode) {
    switch(mode) {
        case ChallengeMode::Author60:
            return ONE_HOUR;
        case ChallengeMode::Gold60:
            return ONE_HOUR;
        default:
            return ONE_HOUR;
    }
}

Medals ModeMedal(ChallengeMode mode) {
    switch(mode) {
        case ChallengeMode::Author60:
            return Medals::Author;
        case ChallengeMode::Gold60:
            return Medals::Gold;
        default:
            return Medals::Author;
    }
}

string ModeMedalName(ChallengeMode mode) {
    switch(mode) {
        case ChallengeMode::Author60:
            return MedalName(Medals::Author);
        case ChallengeMode::Gold60:
            return MedalName(Medals::Gold);
        default:
            return MedalName(Medals::Author);
    }
}

string ModeName(ChallengeMode mode) {
    // return ModeMedalName(mode) + " (" + clock(ModeTimer(mode)) + ")";
    return ModeMedalName(mode) + " (1 Hour)";
}

int64 PersonalBest(ChallengeMode mode) {
    switch(mode) {
        case ChallengeMode::Author60:
            return PersonalBestAuthor60;
        case ChallengeMode::Gold60:
            return PersonalBestGold60;
        default:
            return 0;
    }
}

void SavePersonalBest(ChallengeMode mode, int64 score) {
    switch(mode) {
        case ChallengeMode::Author60:
            PersonalBestAuthor60 = score;
            break;
        case ChallengeMode::Gold60:
            PersonalBestGold60 = score;
            break;
    }
}
