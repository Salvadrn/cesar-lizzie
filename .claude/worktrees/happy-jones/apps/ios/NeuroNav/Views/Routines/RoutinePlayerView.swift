import SwiftUI
import NeuroNavKit

struct RoutinePlayerView: View {
    let routineId: String
    @State private var vm = RoutinePlayerViewModel()
    @Environment(AdaptiveEngine.self) private var engine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("Preparando rutina...")
            } else if vm.isCompleted {
                completionView
            } else if let step = vm.currentStep {
                stepView(step)
            }
        }
        .navigationTitle(vm.routine?.title ?? "Rutina")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Pausar", systemImage: "pause.fill") { vm.pause() }
                    Button("Abandonar", systemImage: "xmark.circle", role: .destructive) {
                        vm.abandon()
                        dismiss()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task { await vm.loadRoutine(id: routineId) }
    }

    // MARK: - Step View

    @ViewBuilder
    private func stepView(_ step: StepResponse) -> some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: vm.progress)
                .tint(.blue)
                .padding(.horizontal)
                .padding(.top, 8)

            Text(vm.progressText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            ScrollView {
                VStack(spacing: 24) {
                    // Step title
                    Text(step.title)
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                        .padding(.top, 24)

                    // Instruction based on complexity level
                    instructionView(step)

                    // Stall banner
                    if vm.stallPhase != .none {
                        StallBanner(phase: vm.stallPhase) {
                            // Reset stall
                            vm.stallPhase = .none
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button {
                    vm.completeCurrentStep()
                } label: {
                    Text("Listo")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if step.checkpoint {
                    Text("Paso de seguridad — confirma antes de continuar")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Button {
                    vm.markError()
                } label: {
                    Text("Necesito ayuda")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            .padding(24)
        }
    }

    @ViewBuilder
    private func instructionView(_ step: StepResponse) -> some View {
        let level = engine.currentLevel
        let text: String = {
            if level <= 2, let simple = step.instructionSimple, !simple.isEmpty {
                return simple
            }
            return step.instruction
        }()

        Text(text)
            .font(level <= 2 ? .title3 : .body)
            .multilineTextAlignment(.center)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 96))
                .foregroundStyle(.green)

            Text("Rutina Completada!")
                .font(.title.bold())

            Text("Completaste todos los \(vm.steps.count) pasos")
                .foregroundStyle(.secondary)

            if vm.totalErrors > 0 || vm.totalStalls > 0 {
                VStack(spacing: 8) {
                    if vm.totalErrors > 0 {
                        Label("\(vm.totalErrors) errores", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if vm.totalStalls > 0 {
                        Label("\(vm.totalStalls) pausas largas", systemImage: "pause.circle")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
            }

            Spacer()

            Button("Volver al inicio") {
                dismiss()
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
