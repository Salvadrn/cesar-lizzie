import 'models/routine.dart';
import 'models/medication.dart';
import 'models/appointment.dart';
import 'models/emergency_contact.dart';
import 'models/caregiver_link.dart';

/// Sample data for development and preview purposes.
/// Mirrors the Swift SampleData used in the iOS app.
class SampleData {
  SampleData._();

  // ---------------------------------------------------------------------------
  // Routines
  // ---------------------------------------------------------------------------

  static final List<RoutineRow> sampleRoutines = [
    RoutineRow(
      id: 'sample-routine-1',
      title: 'Rutina de la mañana',
      description: 'Pasos para empezar bien el día',
      category: 'hygiene',
      isActive: true,
      complexityLevel: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      routineSteps: [
        const StepRow(
          id: 'sample-step-1-1',
          stepOrder: 1,
          title: 'Lavarse la cara',
          instruction: 'Abre el grifo, mójate la cara con agua y sécala con la toalla.',
          instructionSimple: 'Lava tu cara.',
          instructionDetailed:
              'Primero abre el grifo del agua fría. Después moja tus manos y pásalas por la cara. '
              'Luego cierra el grifo y seca tu cara con la toalla azul que está en el gancho.',
          durationHint: 120,
          checkpoint: false,
        ),
        const StepRow(
          id: 'sample-step-1-2',
          stepOrder: 2,
          title: 'Cepillarse los dientes',
          instruction: 'Pon pasta en el cepillo, cepilla 2 minutos y enjuaga.',
          instructionSimple: 'Cepilla tus dientes.',
          instructionDetailed:
              'Toma el cepillo de dientes del vaso. Pon un poco de pasta dental sobre las cerdas. '
              'Cepilla con movimientos circulares durante 2 minutos. Enjuaga la boca con agua y guarda el cepillo.',
          durationHint: 180,
          checkpoint: false,
        ),
        const StepRow(
          id: 'sample-step-1-3',
          stepOrder: 3,
          title: 'Vestirse',
          instruction: 'Elige ropa limpia del armario y vístete.',
          instructionSimple: 'Ponte la ropa.',
          instructionDetailed:
              'Abre el armario y escoge una camiseta, un pantalón y ropa interior limpia. '
              'Quítate el pijama y ponlo en el cesto de la ropa sucia. Vístete con la ropa limpia.',
          durationHint: 300,
          checkpoint: true,
        ),
        const StepRow(
          id: 'sample-step-1-4',
          stepOrder: 4,
          title: 'Desayunar',
          instruction: 'Prepara y come tu desayuno en la cocina.',
          instructionSimple: 'Come tu desayuno.',
          instructionDetailed:
              'Ve a la cocina. Saca los cereales y la leche. Sirve los cereales en un plato hondo y '
              'añade la leche. Come despacio y al terminar pon los platos en el fregadero.',
          durationHint: 600,
          checkpoint: true,
        ),
      ],
    ),
    RoutineRow(
      id: 'sample-routine-2',
      title: 'Preparar almuerzo',
      description: 'Preparar un almuerzo sencillo',
      category: 'cooking',
      isActive: true,
      complexityLevel: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      routineSteps: [
        const StepRow(
          id: 'sample-step-2-1',
          stepOrder: 1,
          title: 'Preparar ingredientes',
          instruction: 'Saca los ingredientes de la nevera y ponlos sobre la encimera.',
          instructionSimple: 'Saca los ingredientes.',
          durationHint: 180,
          checkpoint: false,
        ),
        const StepRow(
          id: 'sample-step-2-2',
          stepOrder: 2,
          title: 'Cocinar',
          instruction: 'Sigue la receta paso a paso para cocinar el almuerzo.',
          instructionSimple: 'Cocina la comida.',
          durationHint: 900,
          checkpoint: true,
        ),
        const StepRow(
          id: 'sample-step-2-3',
          stepOrder: 3,
          title: 'Servir y limpiar',
          instruction: 'Sirve la comida en un plato y limpia la cocina.',
          instructionSimple: 'Sirve y limpia.',
          durationHint: 300,
          checkpoint: false,
        ),
      ],
    ),
    RoutineRow(
      id: 'sample-routine-3',
      title: 'Tomar el autobús',
      description: 'Pasos para ir en transporte público',
      category: 'transit',
      isActive: true,
      complexityLevel: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      routineSteps: [
        const StepRow(
          id: 'sample-step-3-1',
          stepOrder: 1,
          title: 'Ir a la parada',
          instruction: 'Sal de casa y camina hasta la parada de autobús más cercana.',
          instructionSimple: 'Ve a la parada.',
          instructionDetailed:
              'Asegúrate de llevar tu tarjeta de transporte y el móvil. Sal por la puerta '
              'principal y camina a la derecha. La parada está a 3 minutos caminando.',
          durationHint: 300,
          checkpoint: true,
        ),
        const StepRow(
          id: 'sample-step-3-2',
          stepOrder: 2,
          title: 'Subir al autobús',
          instruction: 'Cuando llegue el autobús, sube y pasa tu tarjeta por el lector.',
          instructionSimple: 'Sube al bus.',
          instructionDetailed:
              'Espera a que el autobús se detenga completamente y se abran las puertas. '
              'Sube por la puerta delantera. Pasa tu tarjeta por el lector hasta que suene el pitido. '
              'Busca un asiento libre y siéntate.',
          durationHint: 120,
          checkpoint: true,
        ),
      ],
    ),
  ];

  // ---------------------------------------------------------------------------
  // Medications
  // ---------------------------------------------------------------------------

  static const List<MedicationRow> sampleMedications = [
    MedicationRow(
      id: 'sample-med-1',
      userId: 'sample-user-1',
      name: 'Metilfenidato',
      dosage: '10mg',
      hour: 8,
      minute: 0,
      takenToday: true,
      isActive: true,
    ),
    MedicationRow(
      id: 'sample-med-2',
      userId: 'sample-user-1',
      name: 'Omega 3',
      dosage: '1000mg',
      hour: 13,
      minute: 0,
      takenToday: false,
      isActive: true,
    ),
    MedicationRow(
      id: 'sample-med-3',
      userId: 'sample-user-1',
      name: 'Melatonina',
      dosage: '3mg',
      hour: 21,
      minute: 30,
      takenToday: false,
      isActive: true,
      reminderOffsets: [10, 30],
    ),
  ];

  // ---------------------------------------------------------------------------
  // Appointments
  // ---------------------------------------------------------------------------

  static final List<AppointmentRow> sampleAppointments = [
    AppointmentRow(
      id: 'sample-appt-1',
      userId: 'sample-user-1',
      doctorName: 'Dr. García',
      specialty: 'Neurólogo',
      location: 'Hospital Central, Planta 3',
      notes: 'Llevar informe del colegio',
      appointmentDate:
          DateTime.now().add(const Duration(days: 15)).toIso8601String(),
      isRecurring: true,
      recurringMonths: 3,
      status: 'scheduled',
      createdAt: DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
    ),
    AppointmentRow(
      id: 'sample-appt-2',
      userId: 'sample-user-1',
      doctorName: 'Dra. López',
      specialty: 'Psiquiatra',
      location: 'Clínica Salud Mental, Consulta 7',
      appointmentDate:
          DateTime.now().add(const Duration(days: 5)).toIso8601String(),
      isRecurring: true,
      recurringMonths: 1,
      status: 'scheduled',
      createdAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    ),
    AppointmentRow(
      id: 'sample-appt-3',
      userId: 'sample-user-1',
      doctorName: 'Dr. Martínez',
      specialty: 'General',
      location: 'Centro de Salud Norte',
      notes: 'Revisión anual',
      appointmentDate:
          DateTime.now().add(const Duration(days: 45)).toIso8601String(),
      isRecurring: false,
      status: 'scheduled',
      createdAt: DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Emergency Contacts
  // ---------------------------------------------------------------------------

  static const List<EmergencyContactRow> sampleEmergencyContacts = [
    EmergencyContactRow(
      id: 'sample-contact-1',
      userId: 'sample-user-1',
      name: 'María García',
      phone: '+34 612 345 678',
      relationship: 'Madre',
      isPrimary: true,
    ),
    EmergencyContactRow(
      id: 'sample-contact-2',
      userId: 'sample-user-1',
      name: 'Dr. Rodríguez',
      phone: '+34 698 765 432',
      relationship: 'Médico',
      isPrimary: false,
    ),
  ];

  // ---------------------------------------------------------------------------
  // Caregiver Links
  // ---------------------------------------------------------------------------

  static final List<CaregiverLinkRow> sampleCaregiverLinks = [
    CaregiverLinkRow(
      id: 'sample-link-1',
      userId: 'sample-user-1',
      caregiverId: 'sample-caregiver-1',
      relationship: 'Padre',
      status: 'active',
      permViewActivity: true,
      permEditRoutines: true,
      permViewLocation: true,
      permViewMedications: true,
      permViewEmergency: true,
      createdAt: DateTime.now().subtract(const Duration(days: 90)).toIso8601String(),
      profiles: const LinkedProfileInfo(
        displayName: 'Carlos López',
        email: 'carlos@example.com',
        currentComplexity: 3,
        sensoryMode: 'default',
      ),
    ),
    CaregiverLinkRow(
      id: 'sample-link-2',
      userId: 'sample-user-1',
      caregiverId: 'sample-caregiver-2',
      relationship: 'Terapeuta',
      status: 'active',
      permViewActivity: true,
      permEditRoutines: false,
      permViewLocation: false,
      permViewMedications: true,
      permViewEmergency: false,
      createdAt: DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
      profiles: const LinkedProfileInfo(
        displayName: 'Ana Martín',
        email: 'ana.martin@example.com',
        currentComplexity: 3,
        sensoryMode: 'default',
      ),
    ),
  ];

  // ---------------------------------------------------------------------------
  // Family Links
  // ---------------------------------------------------------------------------

  static final List<CaregiverLinkRow> sampleFamilyLinks = [
    CaregiverLinkRow(
      id: 'sample-family-link-1',
      userId: 'sample-user-1',
      caregiverId: 'sample-family-1',
      relationship: 'Hermano',
      status: 'active',
      permViewActivity: true,
      permEditRoutines: false,
      permViewLocation: true,
      permViewMedications: false,
      permViewEmergency: true,
      createdAt: DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
      profiles: const LinkedProfileInfo(
        displayName: 'Pedro Sánchez',
        email: 'pedro@example.com',
        currentComplexity: 3,
        sensoryMode: 'default',
      ),
    ),
  ];
}
