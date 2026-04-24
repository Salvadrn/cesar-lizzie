import SwiftUI
import Charts
import AdaptAiKit

/// Personal finance view — only for complexity level 5.
/// Soulspring-inspired UI: big balance hero, transaction list, chart breakdown.
struct FinanceView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var store = FinanceStore.shared
    @State private var selectedMonth: Date = Date()
    @State private var showingAdd = false

    private var isDark: Bool { colorScheme == .dark }

    private var monthTxs: [FinanceTransaction] {
        FinanceReport.filter(store.transactions, in: selectedMonth)
            .sorted { $0.date > $1.date }
    }

    private var totals: (income: Double, expense: Double) {
        FinanceReport.totals(monthTxs)
    }

    private var balance: Double { totals.income - totals.expense }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                monthSwitcher
                totalsRow
                chartCard
                categoriesSection
                transactionsSection
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.nnGold.opacity(isDark ? 0.12 : 0.08),
                    Color(.systemBackground),
                ],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Finanzas")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.nnPrimary)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                AddTransactionSheet(store: store)
            }
        }
    }

    // MARK: - Hero

    private var hero: some View {
        VStack(spacing: 8) {
            eyebrow("Balance del mes")

            Text(formatCurrency(balance))
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(balance >= 0 ? .nnSuccess : .nnError)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            if balance >= 0 {
                Label("Vas bien este mes", systemImage: "checkmark.circle.fill")
                    .font(.nnCaption)
                    .foregroundStyle(.nnSuccess)
            } else {
                Label("Gastos superan ingresos", systemImage: "exclamationmark.triangle.fill")
                    .font(.nnCaption)
                    .foregroundStyle(.nnWarning)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
    }

    private var monthSwitcher: some View {
        HStack {
            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.left").font(.body.weight(.semibold))
            }
            Spacer()
            Text(monthName)
                .font(.nnSubheadline.weight(.semibold))
            Spacer()
            Button {
                selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
            } label: {
                Image(systemName: "chevron.right").font(.body.weight(.semibold))
            }
            .disabled(Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month))
        }
        .foregroundStyle(.primary)
        .padding(12)
        .background(isDark ? Color.white.opacity(0.06) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var monthName: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "LLLL yyyy"
        return f.string(from: selectedMonth).capitalized
    }

    // MARK: - Totals

    private var totalsRow: some View {
        HStack(spacing: 12) {
            totalTile(label: "Ingresos", value: totals.income, color: .nnSuccess, icon: "arrow.up.right")
            totalTile(label: "Gastos", value: totals.expense, color: .nnWarning, icon: "arrow.down.right")
        }
    }

    private func totalTile(label: String, value: Double, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle().fill(color.opacity(0.18)).frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(formatCurrency(value))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(label.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(isDark ? Color.white.opacity(0.06) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Chart

    private var chartCard: some View {
        let daily = FinanceReport.dailyExpenses(monthTxs, in: selectedMonth)

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Gastos diarios")

            if daily.allSatisfy({ $0.1 == 0 }) {
                Text("Sin gastos registrados este mes")
                    .font(.nnCaption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart(daily, id: \.0) { day, amount in
                    BarMark(
                        x: .value("Día", day, unit: .day),
                        y: .value("Monto", amount)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.nnWarning, .nnGold],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(4)
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 5)) { value in
                        AxisValueLabel(format: .dateTime.day(), centered: true)
                    }
                }
            }
        }
        .padding(14)
        .background(isDark ? Color.white.opacity(0.06) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Categories

    private var categoriesSection: some View {
        let byCat = FinanceReport.byCategory(monthTxs, type: .expense)

        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Por categoría")

            if byCat.isEmpty {
                Text("Agrega un gasto para ver este desglose")
                    .font(.nnCaption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(byCat.prefix(5), id: \.0) { category, amount in
                        categoryRow(category: category, amount: amount, total: totals.expense)
                    }
                }
            }
        }
    }

    private func categoryRow(category: FinanceCategory, amount: Double, total: Double) -> some View {
        let percent = total > 0 ? (amount / total) : 0

        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(category.tint.opacity(0.18)).frame(width: 36, height: 36)
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(category.tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(category.rawValue)
                        .font(.nnSubheadline.weight(.medium))
                    Spacer()
                    Text(formatCurrency(amount))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(category.tint.opacity(0.15))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(category.tint)
                            .frame(width: geo.size.width * percent, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(12)
        .background(isDark ? Color.white.opacity(0.04) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Transactions

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Movimientos recientes")

            if monthTxs.isEmpty {
                Text("Sin movimientos este mes")
                    .font(.nnCaption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(20)
            } else {
                VStack(spacing: 8) {
                    ForEach(monthTxs.prefix(10)) { tx in
                        transactionRow(tx)
                    }
                }
            }
        }
    }

    private func transactionRow(_ tx: FinanceTransaction) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(tx.category.tint.opacity(0.18)).frame(width: 36, height: 36)
                Image(systemName: tx.category.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tx.category.tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(tx.title).font(.nnSubheadline)
                Text(dateLabel(tx.date))
                    .font(.nnCaption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(tx.type == .income ? "+" : "-")\(formatCurrency(tx.amountMXN))")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(tx.type == .income ? .nnSuccess : .primary)
        }
        .padding(12)
        .background(isDark ? Color.white.opacity(0.04) : Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .swipeActions {
            Button(role: .destructive) {
                store.remove(tx)
            } label: {
                Label("Borrar", systemImage: "trash")
            }
        }
    }

    private func dateLabel(_ d: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "es_MX")
        f.dateFormat = "d MMM"
        return f.string(from: d)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.nnHeadline.weight(.bold))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(1.8)
            .foregroundStyle(.secondary)
    }

    private func formatCurrency(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "MXN"
        f.locale = Locale(identifier: "es_MX")
        f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}

// MARK: - Add Transaction Sheet

struct AddTransactionSheet: View {
    let store: FinanceStore
    @Environment(\.dismiss) private var dismiss
    @State private var kind: FinanceTransaction.Kind = .expense
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var category: FinanceCategory = .comida
    @State private var date = Date()

    var body: some View {
        Form {
            Picker("Tipo", selection: $kind) {
                ForEach(FinanceTransaction.Kind.allCases) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: kind) { _, _ in
                category = kind == .income ? .salario : .comida
            }

            Section("Detalles") {
                TextField("Descripción (ej. Medicamento)", text: $title)
                TextField("Monto", text: $amount)
                    .keyboardType(.decimalPad)
                DatePicker("Fecha", selection: $date, displayedComponents: .date)
            }

            Section("Categoría") {
                Picker("Categoría", selection: $category) {
                    ForEach(kind == .income ? FinanceCategory.incomeCategories : FinanceCategory.expenseCategories) { cat in
                        Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                    }
                }
                .pickerStyle(.navigationLink)
            }
        }
        .navigationTitle("Nuevo movimiento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Guardar") { save() }
                    .bold()
                    .disabled(title.isEmpty || Double(amount) == nil)
            }
        }
    }

    private func save() {
        guard let value = Double(amount) else { return }
        let tx = FinanceTransaction(
            title: title,
            amountMXN: value,
            type: kind,
            category: category,
            date: date
        )
        store.add(tx)
        dismiss()
    }
}
