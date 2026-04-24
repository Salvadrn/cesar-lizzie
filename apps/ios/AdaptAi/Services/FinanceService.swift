import Foundation
import SwiftUI

// MARK: - Transaction

struct FinanceTransaction: Identifiable, Hashable, Codable {
    var id: UUID = UUID()
    var title: String
    var amountMXN: Double
    var type: Kind
    var category: FinanceCategory
    var date: Date
    var notes: String = ""

    enum Kind: String, Codable, CaseIterable, Identifiable {
        case income = "Ingreso"
        case expense = "Egreso"
        var id: String { rawValue }
    }

    var signedAmount: Double {
        type == .income ? amountMXN : -amountMXN
    }
}

// MARK: - Category

enum FinanceCategory: String, Codable, CaseIterable, Identifiable {
    // Income
    case salario = "Salario"
    case inversion = "Inversiones"
    case freelance = "Freelance"
    case otroIngreso = "Otro ingreso"

    // Expense
    case comida = "Alimentos"
    case salud = "Salud y medicinas"
    case hogar = "Hogar"
    case transporte = "Transporte"
    case entretenimiento = "Entretenimiento"
    case ropa = "Ropa"
    case ahorro = "Ahorro"
    case otro = "Otros"

    var id: String { rawValue }

    var isIncome: Bool {
        switch self {
        case .salario, .inversion, .freelance, .otroIngreso: return true
        default: return false
        }
    }

    var icon: String {
        switch self {
        case .salario: return "briefcase.fill"
        case .inversion: return "chart.line.uptrend.xyaxis"
        case .freelance: return "laptopcomputer"
        case .otroIngreso: return "plus.circle"
        case .comida: return "fork.knife"
        case .salud: return "cross.case.fill"
        case .hogar: return "house.fill"
        case .transporte: return "car.fill"
        case .entretenimiento: return "sparkles.tv.fill"
        case .ropa: return "tshirt.fill"
        case .ahorro: return "banknote.fill"
        case .otro: return "ellipsis.circle"
        }
    }

    var tint: Color {
        switch self {
        case .salario, .freelance, .otroIngreso: return .nnPrimary
        case .inversion: return .nnSuccess
        case .comida: return .orange
        case .salud: return .red
        case .hogar: return .brown
        case .transporte: return .cyan
        case .entretenimiento: return .purple
        case .ropa: return .pink
        case .ahorro: return .nnGold
        case .otro: return .gray
        }
    }

    static var incomeCategories: [FinanceCategory] { allCases.filter(\.isIncome) }
    static var expenseCategories: [FinanceCategory] { allCases.filter { !$0.isIncome } }
}

// MARK: - Reporting

enum FinanceReport {
    static func filter(_ txs: [FinanceTransaction], in month: Date) -> [FinanceTransaction] {
        let cal = Calendar.current
        return txs.filter { cal.isDate($0.date, equalTo: month, toGranularity: .month) }
    }

    static func totals(_ txs: [FinanceTransaction]) -> (income: Double, expense: Double) {
        var income = 0.0, expense = 0.0
        for t in txs {
            if t.type == .income { income += t.amountMXN } else { expense += t.amountMXN }
        }
        return (income, expense)
    }

    static func byCategory(_ txs: [FinanceTransaction], type: FinanceTransaction.Kind) -> [(FinanceCategory, Double)] {
        let filtered = txs.filter { $0.type == type }
        let grouped = Dictionary(grouping: filtered, by: \.category)
            .mapValues { $0.reduce(0.0) { $0 + $1.amountMXN } }
        return grouped.sorted { $0.value > $1.value }
    }

    static func dailyExpenses(_ txs: [FinanceTransaction], in month: Date) -> [(Date, Double)] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: month),
              let anchor = cal.date(from: cal.dateComponents([.year, .month], from: month)) else {
            return []
        }
        return range.compactMap { day -> (Date, Double)? in
            guard let date = cal.date(byAdding: .day, value: day - 1, to: anchor) else { return nil }
            let total = txs
                .filter { $0.type == .expense && cal.isDate($0.date, inSameDayAs: date) }
                .reduce(0.0) { $0 + $1.amountMXN }
            return (date, total)
        }
    }

    static func sampleTransactions(now: Date = Date()) -> [FinanceTransaction] {
        let cal = Calendar.current
        func t(_ daysAgo: Int, _ title: String, _ amount: Double,
               _ type: FinanceTransaction.Kind, _ cat: FinanceCategory) -> FinanceTransaction {
            FinanceTransaction(
                title: title, amountMXN: amount, type: type, category: cat,
                date: cal.date(byAdding: .day, value: -daysAgo, to: now) ?? now
            )
        }
        return [
            t(1, "Consulta médica", 850, .expense, .salud),
            t(2, "Super semanal", 1_200, .expense, .comida),
            t(5, "Metformina", 320, .expense, .salud),
            t(8, "Pensión quincenal", 12_500, .income, .salario),
            t(12, "Renta", 8_000, .expense, .hogar),
            t(15, "Gasolina", 600, .expense, .transporte),
        ]
    }
}

// MARK: - Store

@Observable
final class FinanceStore {
    static let shared = FinanceStore()
    private let key = "adaptai.finance.transactions.v1"

    var transactions: [FinanceTransaction] = [] {
        didSet { save() }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([FinanceTransaction].self, from: data) {
            transactions = decoded
        } else {
            transactions = FinanceReport.sampleTransactions()
        }
    }

    func add(_ tx: FinanceTransaction) {
        transactions.insert(tx, at: 0)
    }

    func remove(_ tx: FinanceTransaction) {
        transactions.removeAll { $0.id == tx.id }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
