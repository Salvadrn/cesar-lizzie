import SwiftUI
import PhotosUI
import NeuroNavKit

struct MedicationView: View {
    @Environment(AuthService.self) private var authService
    @Environment(AdaptiveEngine.self) private var engine
    @Environment(\.colorScheme) private var colorScheme
    @State private var vm = MedicationViewModel()
    @State private var showAddSheet = false
    @State private var selectedMedication: MedicationViewModel.MedicationItem?

    private var isDark: Bool { colorScheme == .dark }
    private var level: Int { engine.currentLevel }

    var body: some View {
        Group {
            if level <= 2 {
                simpleMedicationView
            } else {
                standardMedicationView
            }
        }
        .navigationTitle("Medicamentos")
        .toolbar {
            if level >= 3 {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        if authService.isGuestMode { return }
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(authService.isGuestMode)
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddMedicationSheet(vm: vm)
        }
        .sheet(item: $selectedMedication) { med in
            MedicationPhotoViewer(medication: med)
        }
        .task { await vm.load() }
        .refreshable { await vm.load() }
    }

    // MARK: - Simple View (Level 1-2)

    private var simpleMedicationView: some View {
        ScrollView {
            VStack(spacing: level == 1 ? 16 : 12) {
                if authService.isGuestMode {
                    GuestModeBanner()
                }

                if vm.medications.isEmpty && !vm.isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.nnMidGray)
                        Text("Sin medicamentos")
                            .font(.nnTitle3)
                            .foregroundStyle(.nnMidGray)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    let pending = vm.medications.filter { !$0.takenToday }.sorted { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }
                    let taken = vm.medications.filter { $0.takenToday }

                    if !pending.isEmpty {
                        ForEach(pending) { med in
                            simpleMedCard(med)
                        }
                    }

                    if !taken.isEmpty {
                        if !pending.isEmpty {
                            HStack {
                                Rectangle()
                                    .fill(Color.nnRule.opacity(isDark ? 0.3 : 1))
                                    .frame(height: 1)
                                Text("Tomados")
                                    .font(.nnCaption)
                                    .foregroundStyle(.nnMidGray)
                                Rectangle()
                                    .fill(Color.nnRule.opacity(isDark ? 0.3 : 1))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 4)
                        }

                        ForEach(taken) { med in
                            simpleMedCard(med)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(isDark ? Color.nnNightBG : Color(.systemGroupedBackground))
    }

    private func simpleMedCard(_ med: MedicationViewModel.MedicationItem) -> some View {
        Button {
            if !med.takenToday && !authService.isGuestMode {
                Task { await vm.markAsTaken(id: med.id) }
            }
        } label: {
            HStack(spacing: level == 1 ? 16 : 14) {
                Image(systemName: med.takenToday ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: level == 1 ? 40 : 32))
                    .foregroundStyle(med.takenToday ? .nnSuccess : .nnPrimary)

                // Foto del medicamento — SIEMPRE visible para evitar confusiones
                if med.hasImages {
                    Button {
                        selectedMedication = med
                    } label: {
                        MedicationThumbnail(bottleUrl: med.bottleImageUrl, pillUrl: med.pillImageUrl)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(med.name)
                        .font(level == 1 ? .nnTitle3 : .nnHeadline)
                        .foregroundStyle(isDark ? .white : .nnDarkText)
                        .strikethrough(med.takenToday)

                    Text(med.scheduledTime)
                        .font(level == 1 ? .nnSubheadline : .nnCaption)
                        .foregroundStyle(timeColor(for: med))
                }

                Spacer()

                if med.takenToday {
                    Text("Listo")
                        .font(.nnCaption)
                        .foregroundStyle(.nnSuccess)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.nnSuccess.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(level == 1 ? 18 : 14)
            .background(isDark ? Color.white.opacity(0.08) : .white)
            .clipShape(RoundedRectangle(cornerRadius: level == 1 ? 18 : 14))
            .shadow(color: .black.opacity(isDark ? 0 : 0.04), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(authService.isGuestMode)
    }

    // MARK: - Standard View (Level 3+)

    private var standardMedicationView: some View {
        List {
            if authService.isGuestMode {
                Section {
                    GuestModeBanner()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            if vm.medications.isEmpty && !vm.isLoading {
                ContentUnavailableView(
                    "Sin medicamentos",
                    systemImage: "pills.fill",
                    description: Text("Agrega tus medicamentos para recibir recordatorios")
                )
            }

            let pending = vm.medications.filter { !$0.takenToday }.sorted { ($0.hour * 60 + $0.minute) < ($1.hour * 60 + $1.minute) }
            let taken = vm.medications.filter { $0.takenToday }

            if !pending.isEmpty {
                Section("Pendientes") {
                    ForEach(pending) { med in
                        medicationRow(med)
                    }
                }
            }

            if !taken.isEmpty {
                Section("Tomados hoy") {
                    ForEach(taken) { med in
                        medicationRow(med)
                    }
                }
            }

            Section {
                NavigationLink {
                    AppointmentView()
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "stethoscope")
                            .font(.title3)
                            .foregroundStyle(.purple)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Citas Médicas")
                                .font(.nnBody)
                            if level >= 4 {
                                Text("Citas al doctor y recordatorios")
                                    .font(.nnCaption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func medicationRow(_ med: MedicationViewModel.MedicationItem) -> some View {
        HStack(spacing: 14) {
            Button {
                if !med.takenToday && !authService.isGuestMode {
                    Task { await vm.markAsTaken(id: med.id) }
                }
            } label: {
                Image(systemName: med.takenToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(med.takenToday ? .nnSuccess : .nnPrimary)
            }
            .buttonStyle(.plain)
            .disabled(authService.isGuestMode)

            // Fotos SIEMPRE visibles — ayudan a identificar el medicamento correcto
            if med.hasImages {
                Button {
                    selectedMedication = med
                } label: {
                    MedicationThumbnail(bottleUrl: med.bottleImageUrl, pillUrl: med.pillImageUrl)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(med.name)
                    .font(.nnBody)
                    .strikethrough(med.takenToday)

                HStack(spacing: 4) {
                    Text(med.dosage)
                        .font(.nnCaption)
                        .foregroundStyle(.secondary)

                    if level >= 4 {
                        if med.hasImages {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.nnPrimary)
                        }
                        if let offLabel = med.offsetsLabel {
                            Text("·")
                                .font(.nnCaption)
                                .foregroundStyle(.secondary)
                            Image(systemName: "bell.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.nnWarning)
                            Text(offLabel)
                                .font(.nnCaption2)
                                .foregroundStyle(.nnWarning)
                        }
                    }
                }
            }

            Spacer()

            Text(med.scheduledTime)
                .font(.callout.monospacedDigit())
                .foregroundStyle(timeColor(for: med))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(timeColor(for: med).opacity(0.1))
                .clipShape(Capsule())
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if !authService.isGuestMode {
                Button(role: .destructive) {
                    Task { await vm.deleteMedication(id: med.id) }
                } label: {
                    Label("Eliminar", systemImage: "trash")
                }
            }
        }
    }

    private func timeColor(for med: MedicationViewModel.MedicationItem) -> Color {
        if med.takenToday { return .nnSuccess }
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let nowMinutes = (now.hour ?? 0) * 60 + (now.minute ?? 0)
        let medMinutes = med.hour * 60 + med.minute
        if medMinutes < nowMinutes { return .nnError }
        if medMinutes - nowMinutes < 60 { return .nnWarning }
        return .nnPrimary
    }
}

// MARK: - Medication Photo Thumbnail

struct MedicationThumbnail: View {
    let bottleUrl: String?
    let pillUrl: String?

    private var displayUrl: String? { bottleUrl ?? pillUrl }

    var body: some View {
        if let urlString = displayUrl, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 44, height: 44)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                case .failure:
                    placeholderIcon
                default:
                    ProgressView()
                        .frame(width: 44, height: 44)
                }
            }
        } else {
            placeholderIcon
        }
    }

    private var placeholderIcon: some View {
        Image(systemName: "pills.fill")
            .font(.title3)
            .foregroundStyle(.nnPrimary)
            .frame(width: 44, height: 44)
            .background(Color.nnPrimary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Full Photo Viewer

struct MedicationPhotoViewer: View {
    let medication: MedicationViewModel.MedicationItem
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text(medication.name)
                    .font(.nnTitle2)
                    .padding(.top, 16)

                Text(medication.dosage)
                    .font(.nnSubheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                if medication.bottleImageUrl != nil && medication.pillImageUrl != nil {
                    Picker("Foto", selection: $selectedTab) {
                        Label("Frasco", systemImage: "cross.vial.fill").tag(0)
                        Label("Pastilla", systemImage: "pills.fill").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                }

                TabView(selection: $selectedTab) {
                    if let bottleUrl = medication.bottleImageUrl {
                        photoPage(urlString: bottleUrl, label: "Frasco / Empaque")
                            .tag(0)
                    }
                    if let pillUrl = medication.pillImageUrl {
                        photoPage(urlString: pillUrl, label: "Pastilla / Medicamento")
                            .tag(medication.bottleImageUrl != nil ? 1 : 0)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .automatic))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }

    private func photoPage(urlString: String, label: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal, 20)
                    case .failure:
                        VStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text("No se pudo cargar la imagen")
                                .font(.nnCaption)
                                .foregroundStyle(.secondary)
                        }
                    default:
                        ProgressView()
                            .frame(height: 200)
                    }
                }
            }
            Text(label)
                .font(.nnCaption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            Spacer()
        }
    }
}

// MARK: - Add Medication Sheet (with Photos)

struct AddMedicationSheet: View {
    let vm: MedicationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var dosage = ""
    @State private var time = Date()
    @State private var selectedOffsets: Set<Int> = [5]
    @State private var isSaving = false

    @State private var bottlePhotoItem: PhotosPickerItem?
    @State private var pillPhotoItem: PhotosPickerItem?
    @State private var bottleImage: UIImage?
    @State private var pillImage: UIImage?

    private let availableOffsets = [5, 10, 15, 30]

    var body: some View {
        NavigationStack {
            Form {
                Section("Medicamento") {
                    TextField("Nombre", text: $name)
                    TextField("Dosis (ej: 1 pastilla, 5ml)", text: $dosage)
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fotos del medicamento")
                            .font(.nnSubheadline)
                        Text("Ayuda a identificar visualmente el medicamento")
                            .font(.nnCaption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 16) {
                            photoPickerCard(label: "Frasco", icon: "cross.vial.fill", image: bottleImage, pickerItem: $bottlePhotoItem)
                            photoPickerCard(label: "Pastilla", icon: "pills.fill", image: pillImage, pickerItem: $pillPhotoItem)
                        }
                    }
                    .padding(.vertical, 4)
                } footer: {
                    Text("Opcional: toma una foto del frasco y de la pastilla para reconocerlos mejor")
                }

                Section("Horario") {
                    DatePicker("Hora", selection: $time, displayedComponents: .hourAndMinute)
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Recordatorios previos")
                            .font(.nnSubheadline)
                        HStack(spacing: 8) {
                            ForEach(availableOffsets, id: \.self) { offset in
                                offsetChip(offset)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } footer: {
                    Text("Recibirás una notificación antes de la hora programada")
                }
            }
            .navigationTitle("Nuevo medicamento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isSaving = true
                        Task { await saveWithPhotos() }
                    } label: {
                        if isSaving { ProgressView() } else { Text("Guardar") }
                    }
                    .disabled(name.isEmpty || dosage.isEmpty || isSaving)
                }
            }
            .onChange(of: bottlePhotoItem) { _, newItem in
                Task { await loadPhoto(from: newItem, into: .bottle) }
            }
            .onChange(of: pillPhotoItem) { _, newItem in
                Task { await loadPhoto(from: newItem, into: .pill) }
            }
        }
        .presentationDetents([.large])
    }

    private func photoPickerCard(label: String, icon: String, image: UIImage?, pickerItem: Binding<PhotosPickerItem?>) -> some View {
        VStack(spacing: 8) {
            PhotosPicker(selection: pickerItem, matching: .images) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.nnSuccess)
                                .background(.white, in: Circle())
                                .padding(4)
                        }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundStyle(.nnPrimary)
                        Image(systemName: "camera.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(width: 100, height: 100)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                            .foregroundStyle(.secondary)
                    )
                }
            }

            Text(label)
                .font(.nnCaption)
                .foregroundStyle(.secondary)
        }
    }

    private enum PhotoType { case bottle, pill }

    private func loadPhoto(from item: PhotosPickerItem?, into type: PhotoType) async {
        guard let item, let data = try? await item.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        switch type {
        case .bottle: bottleImage = uiImage
        case .pill: pillImage = uiImage
        }
    }

    private enum UploadResult: Sendable {
        case bottle(String?)
        case pill(String?)
    }

    private func saveWithPhotos() async {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        var bottleUrl: String?
        var pillUrl: String?

        let bottleData = bottleImage?.jpegData(compressionQuality: 0.7)
        let pillData = pillImage?.jpegData(compressionQuality: 0.7)

        let results = await withTaskGroup(of: UploadResult.self, returning: [UploadResult].self) { group in
            if let bottleData {
                group.addTask {
                    let url = await self.vm.uploadImage(data: bottleData, type: "bottle")
                    return .bottle(url)
                }
            }
            if let pillData {
                group.addTask {
                    let url = await self.vm.uploadImage(data: pillData, type: "pill")
                    return .pill(url)
                }
            }
            var collected: [UploadResult] = []
            for await result in group { collected.append(result) }
            return collected
        }

        for result in results {
            switch result {
            case .bottle(let url): bottleUrl = url
            case .pill(let url): pillUrl = url
            }
        }

        await vm.addMedication(
            name: name, dosage: dosage,
            hour: components.hour ?? 8, minute: components.minute ?? 0,
            offsets: Array(selectedOffsets).sorted(),
            bottleImageUrl: bottleUrl, pillImageUrl: pillUrl
        )
        isSaving = false
        dismiss()
    }

    private func offsetChip(_ offset: Int) -> some View {
        let isSelected = selectedOffsets.contains(offset)
        return Button {
            if isSelected { selectedOffsets.remove(offset) } else { selectedOffsets.insert(offset) }
        } label: {
            Text("\(offset) min")
                .font(.nnCaption)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.nnPrimary : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
