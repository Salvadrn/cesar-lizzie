import Foundation

// MARK: - String Extension

extension String {
    /// Convenience to look up this string as an NSLocalizedString key.
    var localized: String {
        NSLocalizedString(self, comment: "")
    }

    /// Convenience with format arguments.
    func localized(_ args: CVarArg...) -> String {
        String(format: NSLocalizedString(self, comment: ""), arguments: args)
    }
}

// MARK: - L10n (Localization Constants)

/// Type-safe localization keys.
/// Usage: `Text(L10n.tabHome)` or `label.text = L10n.commonSave`
///
/// All keys reference entries in `Localizable.xcstrings`.
enum L10n {

    // MARK: Tabs

    static let tabHome = String(localized: "tab.home")
    static let tabRoutines = String(localized: "tab.routines")
    static let tabMedications = String(localized: "tab.medications")
    static let tabHealth = String(localized: "tab.health")
    static let tabFamily = String(localized: "tab.family")
    static let tabEmergency = String(localized: "tab.emergency")
    static let tabSettings = String(localized: "tab.settings")

    // MARK: Common UI

    static let commonLoading = String(localized: "common.loading")
    static let commonSave = String(localized: "common.save")
    static let commonCancel = String(localized: "common.cancel")
    static let commonShare = String(localized: "common.share")
    static let commonEdit = String(localized: "common.edit")
    static let commonDelete = String(localized: "common.delete")
    static let commonClose = String(localized: "common.close")
    static let commonAccept = String(localized: "common.accept")
    static let commonDone = String(localized: "common.done")
    static let commonBack = String(localized: "common.back")

    // MARK: Home Screen

    static let homeGoodMorning = String(localized: "home.goodMorning")
    static let homeGoodAfternoon = String(localized: "home.goodAfternoon")
    static let homeGoodEvening = String(localized: "home.goodEvening")
    static let homeNextRoutine = String(localized: "home.nextRoutine")
    static let homeNoRoutinesScheduled = String(localized: "home.noRoutinesScheduled")
    static let homePendingMedications = String(localized: "home.pendingMedications")

    // MARK: Emergency

    static let emergencyTitle = String(localized: "emergency.title")
    static let emergencyTapForHelp = String(localized: "emergency.tapForHelp")
    static let emergencyContacts = String(localized: "emergency.contacts")
    static let emergencyLostMode = String(localized: "emergency.lostMode")
    static let emergencyMedicalID = String(localized: "emergency.medicalID")
    static let emergencyFallDetection = String(localized: "emergency.fallDetection")

    // MARK: Medications

    static let medicationsTake = String(localized: "medications.take")
    static let medicationsTaken = String(localized: "medications.taken")
    static let medicationsPending = String(localized: "medications.pending")
    static let medicationsTimeForMedication = String(localized: "medications.timeForMedication")

    // MARK: Settings

    static let settingsPatientProfile = String(localized: "settings.patientProfile")
    static let settingsTheme = String(localized: "settings.theme")
    static let settingsAutomatic = String(localized: "settings.automatic")
    static let settingsLight = String(localized: "settings.light")
    static let settingsDark = String(localized: "settings.dark")
    static let settingsSignOut = String(localized: "settings.signOut")
    static let settingsAbout = String(localized: "settings.about")
    static let settingsLanguage = String(localized: "settings.language")

    // MARK: Health

    static let healthConnectHealthKit = String(localized: "health.connectHealthKit")
    static let healthHeartRate = String(localized: "health.heartRate")
    static let healthSteps = String(localized: "health.steps")
    static let healthBloodOxygen = String(localized: "health.bloodOxygen")
    static let healthSleep = String(localized: "health.sleep")
    static let healthActiveCalories = String(localized: "health.activeCalories")

    // MARK: Auth

    static let authSignIn = String(localized: "auth.signIn")
    static let authGuestMode = String(localized: "auth.guestMode")
    static let authCreateAccount = String(localized: "auth.createAccount")

    // MARK: Routines

    static let routinesCompleted = String(localized: "routines.completed")
    static let routinesInProgress = String(localized: "routines.inProgress")
    static let routinesAbandoned = String(localized: "routines.abandoned")
    static let routinesSteps = String(localized: "routines.steps")

    // MARK: Family / Caregiver

    static let familyLinkPatient = String(localized: "family.linkPatient")
    static let familyStatistics = String(localized: "family.statistics")
    static let familyReminders = String(localized: "family.reminders")
    static let familyUnlinkPatient = String(localized: "family.unlinkPatient")

    // MARK: Notifications

    static let notificationsDidYouTakeMedication = String(localized: "notifications.didYouTakeMedication")
    static let notificationsITookIt = String(localized: "notifications.iTookIt")
    static let notificationsRemindIn5Min = String(localized: "notifications.remindIn5Min")

    // MARK: Guest Banner

    static let guestBanner = String(localized: "guest.banner")
}
