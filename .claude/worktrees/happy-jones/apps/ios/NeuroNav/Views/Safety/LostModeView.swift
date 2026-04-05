import SwiftUI
import NeuroNavKit

struct LostModeView: View {
    @State private var profile: UserProfileResponse?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.blue.ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(.white)
            } else if let profile {
                VStack(spacing: 32) {
                    Spacer()

                    // Photo
                    if let photoURL = profile.lostModePhotoURL, !photoURL.isEmpty {
                        AsyncImage(url: URL(string: photoURL)) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 120))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 4))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 120))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    // Name
                    if let name = profile.lostModeName, !name.isEmpty {
                        Text(name)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    Text("NECESITO AYUDA\nPOR FAVOR LLAME A MI CONTACTO")
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    // Contact info
                    VStack(spacing: 16) {
                        if let address = profile.lostModeAddress, !address.isEmpty {
                            infoRow(icon: "house.fill", text: address)
                        }

                        if let phone = profile.lostModePhone, !phone.isEmpty,
                           let url = URL(string: "tel://\(phone)") {
                            Link(destination: url) {
                                HStack(spacing: 12) {
                                    Image(systemName: "phone.fill")
                                        .font(.title2)
                                    Text(phone)
                                        .font(.title2.bold())
                                }
                                .foregroundStyle(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(.green)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                    }
                    .padding(.horizontal, 32)

                    Spacer()
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.yellow)

                    Text("Modo perdido no configurado")
                        .font(.title3.bold())
                        .foregroundStyle(.white)

                    Text("Pide a tu cuidador que configure tu información de modo perdido.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadProfile() }
    }

    @ViewBuilder
    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
            Text(text)
                .font(.body)
        }
        .foregroundStyle(.white)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func loadProfile() async {
        do {
            profile = try await APIClient.shared.fetchProfile()
        } catch {
            print("Failed to load profile: \(error)")
        }
        isLoading = false
    }
}
