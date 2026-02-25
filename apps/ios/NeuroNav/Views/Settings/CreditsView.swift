import SwiftUI

struct CreditsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Logo / Header
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                        .symbolEffect(.pulse)

                    Text("NeuroNav")
                        .font(.largeTitle.bold())

                    Text("Adaptive Daily Living Assistant")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Diego's credit
                VStack(spacing: 16) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.yellow)

                    Text("Diego")
                        .font(.title.bold())

                    Text("Es muy inteligente y es el mejor")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 6) {
                        ForEach(0..<5) { _ in
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                    }
                    .font(.title3)
                }
                .padding(24)
                .frame(maxWidth: .infinity)
                .background(.yellow.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal)

                // Team
                VStack(spacing: 16) {
                    creditCard(
                        name: "NeuroNav Team",
                        role: "Desarrollo & Diseño",
                        icon: "laptopcomputer",
                        color: .blue
                    )

                    creditCard(
                        name: "Claude (Anthropic)",
                        role: "Asistente de desarrollo IA",
                        icon: "cpu",
                        color: .purple
                    )
                }
                .padding(.horizontal)

                // Tech Stack
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tecnologías")
                        .font(.headline)

                    HStack(spacing: 10) {
                        techBadge("SwiftUI", color: .orange)
                        techBadge("iOS 17+", color: .blue)
                        techBadge("Supabase", color: .green)
                    }
                    HStack(spacing: 10) {
                        techBadge("WidgetKit", color: .purple)
                        techBadge("SwiftData", color: .red)
                        techBadge("VisionKit", color: .cyan)
                    }
                }
                .padding(.horizontal)

                // Version
                VStack(spacing: 4) {
                    Text("Versión 1.0.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Hecho con ❤️ para personas con discapacidades cognitivas")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Créditos")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func creditCard(name: String, role: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body.weight(.medium))
                Text(role)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func techBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
