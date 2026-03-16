import Foundation
import NeuroNavKit

/// Datos de ejemplo para modo invitado.
/// Se muestran al usuario no autenticado para que vea cómo luce la app.
enum SampleData {

    // MARK: - Rutinas

    static let routines: [RoutineResponse] = [
        RoutineResponse(
            id: "sample-1",
            title: "Rutina de la mañana",
            description: "Prepara todo para empezar bien el día",
            category: "hygiene",
            isActive: true,
            assignedTo: nil,
            complexityLevel: 3,
            steps: [
                StepResponse(id: "s1-1", stepOrder: 1, title: "Lavarse la cara", instruction: "Abre el grifo y lávate la cara con agua", instructionSimple: "Lávate la cara", instructionDetailed: nil, imageURL: nil, audioURL: nil, videoURL: nil, durationHint: 120, checkpoint: false),
                StepResponse(id: "s1-2", stepOrder: 2, title: "Cepillarse los dientes", instruction: "Pon pasta en el cepillo y cepilla 2 minutos", instructionSimple: "Cepilla tus dientes", instructionDetailed: nil, imageURL: nil, audioURL: nil, videoURL: nil, durationHint: 120, checkpoint: false),
                StepResponse(id: "s1-3", stepOrder: 3, title: "Vestirse", instruction: "Escoge ropa limpia y vístete", instructionSimple: "Ponte la ropa", instructionDetailed: nil, imageURL: nil, audioURL: nil, videoURL: nil, durationHint: 300, checkpoint: true),
                StepResponse(id: "s1-4", stepOrder: 4, title: "Desayunar", instruction: "Prepara tu desayuno y come sentado", instructionSimple: "Come tu desayuno", instructionDetailed: nil, imageURL: nil, audioURL: nil, videoURL: nil, durationHint: 600, checkpoint: true),
            ],
            createdAt: nil
        ),
        RoutineResponse(
            id: "sample-2",
            title: "Preparar almuerzo",
            description: "Pasos para preparar una comida sencilla",
            category: "cooking",
            isActive: true,
            assignedTo: nil,
            complexityLevel: 3,
            steps: [
                StepResponse(id: "s2-1", stepOrder: 1, title: "Lavar las manos", instruction: "Lávate las manos con jabón", instructionSimple: "Lávate las manos", instructionDetailed: nil, imageURL: nil, audioURL: nil, videoURL: nil, durationHint: 60, checkpoint: false),
                StepResponse(id: "s2-2", stepOrder: 2, title: "Sacar ingredientes", instruction: "Busca lo que necesitas en la nevera", instructionSimple: "Saca la comida", instructionDetailed: nil, imageURL: nil, audioURL: nil, videoURL: nil, durationHint: 120, checkpoint: false),
                StepResponse(id: "s2-3", stepOrder: 3, title: "Cocinar", instruction: "Sigue la receta paso a paso", instructionSimple: "Cocina", instructionDetailed: nil, imageURL: nil, audioURL: nil, videoURL: nil, durationHint: 900, checkpoint: true),
            ],
            createdAt: nil
        ),
        RoutineResponse(
            id: "sample-3",
            title: "Tomar el autobús",
            description: "Cómo ir al centro en transporte público",
            category: "transit",
            isActive: true,
            assignedTo: nil,
            complexityLevel: 2,
            steps: [
                StepResponse(id: "s3-1", stepOrder: 1, title: "Preparar la tarjeta", instruction: "Busca tu tarjeta de transporte", instructionSimple: "Busca tu tarjeta", instructionDetailed: nil, imageURL: nil, audioURL: nil, videoURL: nil, durationHint: 60, checkpoint: false),
                StepResponse(id: "s3-2", stepOrder: 2, title: "Ir a la parada", instruction: "Camina hasta la parada del autobús", instructionSimple: "Ve a la parada", instructionDetailed: nil, imageURL: nil, audioURL: nil, videoURL: nil, durationHint: 300, checkpoint: true),
            ],
            createdAt: nil
        ),
    ]

    // MARK: - Medicamentos

    static let medications: [MedicationViewModel.MedicationItem] = [
        .init(id: "sample-med-1", name: "Metilfenidato", dosage: "10mg - 1 pastilla", hour: 8, minute: 0, takenToday: true, reminderOffsets: [5, 15]),
        .init(id: "sample-med-2", name: "Omega 3", dosage: "1 cápsula", hour: 13, minute: 0, takenToday: false, reminderOffsets: [5]),
        .init(id: "sample-med-3", name: "Melatonina", dosage: "3mg", hour: 21, minute: 30, takenToday: false, reminderOffsets: [10, 30]),
    ]

    // MARK: - Citas médicas

    static let appointments: [AppointmentRow] = [
        AppointmentRow(
            id: "sample-appt-1",
            userId: "sample",
            doctorName: "Dr. García",
            specialty: "Neurólogo",
            location: "Hospital Central",
            notes: "Llevar estudios anteriores",
            appointmentDate: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: 5, to: Date())!),
            isRecurring: true,
            recurringMonths: 3,
            status: AppConstants.AppointmentStatus.scheduled.rawValue,
            createdAt: "2025-01-01"
        ),
        AppointmentRow(
            id: "sample-appt-2",
            userId: "sample",
            doctorName: "Dra. López",
            specialty: "Psiquiatra",
            location: "Consultorio 204",
            notes: nil,
            appointmentDate: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .day, value: 15, to: Date())!),
            isRecurring: true,
            recurringMonths: 1,
            status: AppConstants.AppointmentStatus.scheduled.rawValue,
            createdAt: "2025-01-01"
        ),
        AppointmentRow(
            id: "sample-appt-3",
            userId: "sample",
            doctorName: "Dr. Martínez",
            specialty: "Médico General",
            location: nil,
            notes: "Chequeo anual",
            appointmentDate: ISO8601DateFormatter().string(from: Calendar.current.date(byAdding: .month, value: 2, to: Date())!),
            isRecurring: false,
            recurringMonths: nil,
            status: AppConstants.AppointmentStatus.scheduled.rawValue,
            createdAt: "2025-01-01"
        ),
    ]

    // MARK: - Contactos de emergencia

    static let emergencyContacts: [EmergencyContactResponse] = [
        EmergencyContactResponse(id: "sample-ec-1", userId: "sample", name: "María García", phone: "+34600000000", relationship: "Madre", isPrimary: true),
        EmergencyContactResponse(id: "sample-ec-2", userId: "sample", name: "Dr. Rodríguez", phone: "+34600000001", relationship: "Médico", isPrimary: false),
    ]

    // MARK: - Vínculos de ejemplo (para cuidador/familiar en guest mode)

    static let caregiverLinks: [CaregiverLinkRow] = [
        CaregiverLinkRow(
            id: "sample-link-1",
            userId: "sample-patient-1",
            caregiverId: "sample-caregiver",
            relationship: "Hijo",
            status: AppConstants.LinkStatus.active.rawValue,
            inviteCode: nil,
            permViewActivity: true,
            permEditRoutines: true,
            permViewLocation: true,
            permViewMedications: true,
            permViewEmergency: true,
            createdAt: "2025-01-15",
            profiles: LinkedProfileInfo(displayName: "Carlos López", email: "carlos@ejemplo.com", currentComplexity: 3, sensoryMode: "default")
        ),
        CaregiverLinkRow(
            id: "sample-link-2",
            userId: "sample-patient-2",
            caregiverId: "sample-caregiver",
            relationship: "Paciente",
            status: AppConstants.LinkStatus.active.rawValue,
            inviteCode: nil,
            permViewActivity: true,
            permEditRoutines: false,
            permViewLocation: false,
            permViewMedications: true,
            permViewEmergency: true,
            createdAt: "2025-03-01",
            profiles: LinkedProfileInfo(displayName: "Ana Martín", email: "ana@ejemplo.com", currentComplexity: 2, sensoryMode: "lowStimulation")
        ),
    ]

    static let familyLinks: [CaregiverLinkRow] = [
        CaregiverLinkRow(
            id: "sample-link-3",
            userId: "sample-user",
            caregiverId: "sample-family",
            relationship: "Madre",
            status: AppConstants.LinkStatus.active.rawValue,
            inviteCode: nil,
            permViewActivity: true,
            permEditRoutines: false,
            permViewLocation: true,
            permViewMedications: true,
            permViewEmergency: true,
            createdAt: "2025-02-10",
            profiles: LinkedProfileInfo(displayName: "Pedro Sánchez", email: "pedro@ejemplo.com", currentComplexity: 3, sensoryMode: "default")
        ),
    ]
}
