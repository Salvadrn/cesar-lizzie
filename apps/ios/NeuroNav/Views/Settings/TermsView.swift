import SwiftUI

struct TermsView: View {
    var body: some View {
        Form {
            Section {
                Text("Por favor, lee detenidamente los siguientes términos y condiciones antes de usar NeuroNav.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("1. Naturaleza de la Aplicación") {
                Text("NeuroNav es una herramienta de apoyo diseñada para asistir en actividades de la vida diaria. NO es un dispositivo médico ni un sustituto de atención profesional de salud. No debe utilizarse como reemplazo de diagnósticos, tratamientos o recomendaciones médicas.")
                    .font(.subheadline)
            }

            Section("2. Recordatorios de Medicamentos") {
                Text("La aplicación ofrece recordatorios de medicamentos como función de apoyo. Sin embargo, NeuroNav NO garantiza la adherencia a medicamentos. Si el usuario no toma sus medicamentos a pesar de los recordatorios, NeuroNav y sus desarrolladores NO son responsables de las consecuencias que esto pueda ocasionar.")
                    .font(.subheadline)
            }

            Section("3. Público Objetivo y Responsabilidad") {
                Text("NeuroNav está diseñada para adultos con discapacidades cognitivas. El usuario y/o su cuidador asumen toda la responsabilidad del cuidado personal. La aplicación es un complemento, no un sustituto del cuidado humano directo.")
                    .font(.subheadline)
            }

            Section("4. Almacenamiento de Datos") {
                Text("Los datos del usuario se almacenan de forma segura siguiendo prácticas estándar de la industria. Al usar NeuroNav, el usuario acepta nuestra política de manejo y almacenamiento de datos personales. Los datos se utilizan exclusivamente para el funcionamiento de la aplicación.")
                    .font(.subheadline)
            }

            Section("5. Notificaciones y Recordatorios") {
                Text("Las notificaciones y recordatorios se proporcionan con base en el mejor esfuerzo. Pueden fallar o retrasarse debido a restricciones del sistema operativo, optimización de batería, configuraciones del dispositivo u otras limitaciones técnicas fuera de nuestro control.")
                    .font(.subheadline)
            }

            Section("6. Servicios de Ubicación y Detección de Caídas") {
                Text("NeuroNav puede utilizar detección de caídas y servicios de ubicación como funciones de seguridad. Al usar estas funciones, el usuario consiente al acceso y procesamiento de estos datos con el fin de brindar mayor protección.")
                    .font(.subheadline)
            }

            Section("7. Limitación de Responsabilidad") {
                Text("NeuroNav y sus desarrolladores no asumen responsabilidad por daños, lesiones o consecuencias médicas derivadas del uso o la imposibilidad de uso de la aplicación. El usuario utiliza la aplicación bajo su propio riesgo.")
                    .font(.subheadline)
            }

            Section("8. Garantías") {
                Text("La aplicación se proporciona \"tal cual\" (as is), sin garantías de ningún tipo, ya sean expresas o implícitas. No garantizamos que la aplicación funcionará sin interrupciones o libre de errores.")
                    .font(.subheadline)
            }

            Section("9. Edad Mínima") {
                Text("Los usuarios deben ser mayores de 18 años para utilizar NeuroNav. En caso de menores de edad o personas bajo tutela legal, un tutor legal debe aceptar estos términos en su nombre.")
                    .font(.subheadline)
            }

            Section("10. Modificaciones a los Términos") {
                Text("Estos términos pueden actualizarse periódicamente. El uso continuado de la aplicación después de cualquier modificación constituye la aceptación de los nuevos términos. Se recomienda revisar esta sección regularmente.")
                    .font(.subheadline)
            }

            Section {
                VStack(alignment: .center, spacing: 8) {
                    Text("Versión 1.0.0")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Última actualización: Febrero 2026")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Términos y Condiciones")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TermsView()
    }
}
