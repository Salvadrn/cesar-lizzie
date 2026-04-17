import SwiftUI
import WidgetKit

@main
struct AdaptAiWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextRoutineWidget()
        DailyProgressWidget()
        EmergencyWidget()
        MedicationWidget()
    }
}
