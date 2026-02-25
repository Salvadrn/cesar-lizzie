import SwiftUI
import WidgetKit

@main
struct NeuroNavWidgetBundle: WidgetBundle {
    var body: some Widget {
        NextRoutineWidget()
        DailyProgressWidget()
        EmergencyWidget()
        MedicationWidget()
    }
}
