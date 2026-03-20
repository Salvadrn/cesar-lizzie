import SwiftUI

// Brand Identity Manual — Section 03: Color Palette
// All colors defined exactly as specified in the AdaptAi Brand Identity Manual

// ShapeStyle conformance so colors work with .foregroundStyle(.nnPrimary)
extension ShapeStyle where Self == Color {
    static var nnPrimary: Color { Color.nnPrimary }
    static var nnGold: Color { Color.nnGold }
    static var nnSensoryGray: Color { Color.nnSensoryGray }
    static var nnLightBG: Color { Color.nnLightBG }
    static var nnDarkText: Color { Color.nnDarkText }
    static var nnNightBG: Color { Color.nnNightBG }
    static var nnMidGray: Color { Color.nnMidGray }
    static var nnSuccess: Color { Color.nnSuccess }
    static var nnError: Color { Color.nnError }
    static var nnTint: Color { Color.nnTint }
    static var nnRule: Color { Color.nnRule }
    static var nnLowStimBG: Color { Color.nnLowStimBG }
    static var nnLowStimAccent: Color { Color.nnLowStimAccent }
    static var nnMedication: Color { Color.nnMedication }
    static var nnEmergency: Color { Color.nnEmergency }
    static var nnFamily: Color { Color.nnFamily }
    static var nnCaregiver: Color { Color.nnCaregiver }
    static var nnWarning: Color { Color.nnWarning }
}

extension Color {

    // MARK: - Primary Colors

    /// #4078DA — Accents, CTAs, progress bars, interactive elements
    static let nnPrimary = Color(red: 0x40/255, green: 0x78/255, blue: 0xDA/255)

    /// #FFD700 — High-contrast mode accent only
    static let nnGold = Color(red: 0xFF/255, green: 0xD7/255, blue: 0x00/255)

    /// #738D9E — Low-stimulation mode primary
    static let nnSensoryGray = Color(red: 0x73/255, green: 0x8D/255, blue: 0x9E/255)

    // MARK: - Interface Colors

    /// #F5F7FB — Default light background
    static let nnLightBG = Color(red: 0xF5/255, green: 0xF7/255, blue: 0xFB/255)

    /// #121827 — Primary text color
    static let nnDarkText = Color(red: 0x12/255, green: 0x18/255, blue: 0x27/255)

    /// #1A1F2E — Dark mode background
    static let nnNightBG = Color(red: 0x1A/255, green: 0x1F/255, blue: 0x2E/255)

    /// #A0AEC0 — Secondary text, placeholders
    static let nnMidGray = Color(red: 0xA0/255, green: 0xAE/255, blue: 0xC0/255)

    // MARK: - Semantic Colors

    /// #38A169 — Success, completion, medication taken
    static let nnSuccess = Color(red: 0x38/255, green: 0xA1/255, blue: 0x69/255)

    /// #E53E3E — Error, emergency, destructive actions
    static let nnError = Color(red: 0xE5/255, green: 0x3E/255, blue: 0x3E/255)

    /// #EBF0FF — Tint/highlight backgrounds
    static let nnTint = Color(red: 0xEB/255, green: 0xF0/255, blue: 0xFF/255)

    /// #E2EBF0 — Dividers, borders, rules
    static let nnRule = Color(red: 0xE2/255, green: 0xEB/255, blue: 0xF0/255)

    // MARK: - Low Stimulation Mode Colors

    /// #E8ECF0 — Low stimulation background
    static let nnLowStimBG = Color(red: 0xE8/255, green: 0xEC/255, blue: 0xF0/255)

    /// #5A7080 — Low stimulation accent
    static let nnLowStimAccent = Color(red: 0x5A/255, green: 0x70/255, blue: 0x80/255)

    // MARK: - Feature Colors (for quick action tiles & navigation)

    /// Medications — green tinted
    static let nnMedication = nnSuccess

    /// Emergency — red tinted
    static let nnEmergency = nnError

    /// Family — purple
    static let nnFamily = Color(red: 0x68/255, green: 0x50/255, blue: 0xB8/255)

    /// Caregiver — warm purple
    static let nnCaregiver = Color(red: 0x80/255, green: 0x5A/255, blue: 0xD5/255)

    /// Warning — orange
    static let nnWarning = Color(red: 0xDD/255, green: 0x6B/255, blue: 0x20/255)
}
