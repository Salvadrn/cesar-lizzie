import SwiftUI

struct CreditsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Logo / Header
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.primary)

                    Text("NeuroNav")
                        .font(.nnLargeTitle)

                    Text("Adaptive Daily Living Assistant")
                        .font(.nnSubheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)

                // Team
                VStack(spacing: 16) {
                    creditCard(
                        name: "NeuroNav Team",
                        role: "Desarrollo & Diseño",
                        icon: "laptopcomputer",
                        color: .blue
                    )
                }
                .padding(.horizontal)

                // Tech Stack
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tecnologías")
                        .font(.nnHeadline)

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
                        .font(.nnCaption)
                        .foregroundStyle(.secondary)
                    Text("Hecho con ❤️ para personas con discapacidades cognitivas")
                        .font(.nnCaption2)
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
                .font(.nnTitle2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.nnBody)
                Text(role)
                    .font(.nnCaption)
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
            .font(.nnCaption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
