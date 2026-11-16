import Foundation
import SwiftUI
import Observation

struct WeighIn: Identifiable {
    var id: String { key }
    let key: String
    let date: Date
    let weight: Double
}

struct WeekStat: Identifiable {
    var id: Date { start }
    let start: Date
    let points: Int
    let maxPoints: Int
    let beers: Int
}

@Observable
final class Store {
    var data: AppData

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("plano.json")
    }

    init() {
        if let raw = try? Data(contentsOf: Store.fileURL),
           let decoded = try? JSONDecoder().decode(AppData.self, from: raw) {
            data = decoded
        } else {
            data = AppData()
        }
    }

    func save() {
        do {
            let raw = try JSONEncoder().encode(data)
            try raw.write(to: Store.fileURL, options: .atomic)
        } catch {
            print("Erro a guardar: \(error)")
        }
    }

    // MARK: Registo

    func log(_ key: String) -> DayLog { data.logs[key] ?? DayLog(date: key) }

    func binding(for key: String) -> Binding<DayLog> {
        Binding(
            get: { self.log(key) },
            set: { newValue in
                var value = newValue
                let old = self.log(key)
                // Marcou todas as refeições → "Cumpri a ementa" fica marcado automaticamente.
                // (exceto se alguma refeição foi "o que comi", ou seja, fora do plano)
                if value.mealsDone != old.mealsDone && !value.mealsDone.contains(false)
                    && !value.custom.values.contains(where: { $0.mode == .eaten }) {
                    value.followedMenu = true
                }
                self.data.logs[key] = value
                self.save()
            }
        )
    }

    var settingsBinding: Binding<AppSettings> {
        Binding(
            get: { self.data.settings },
            set: { self.data.settings = $0; self.save() }
        )
    }

    var settings: AppSettings { data.settings }

    // MARK: Refeições, extras e água

    private func update(_ key: String, _ change: (inout DayLog) -> Void) {
        var log = self.log(key)
        change(&log)
        data.logs[key] = log
        save()
    }

    /// Altera (ou repõe, com nil) uma refeição do dia.
    func setMeal(_ key: String, _ index: Int, _ custom: CustomMeal?, markDone: Bool = false) {
        update(key) { log in
            log.custom[index] = custom
            if markDone { log.mealsDone[index] = true }
        }
    }

    func addExtras(_ key: String, _ items: [FoodItem]) {
        update(key) { $0.extras.append(contentsOf: items) }
    }

    func removeExtra(_ key: String, id: UUID) {
        update(key) { $0.extras.removeAll { $0.id == id } }
    }

    func addWater(_ key: String, ml: Int) {
        update(key) { $0.water = max(0, $0.water + ml) }
    }

    /// Média de calorias dos últimos dias (até 7) com comida registada.
    var averageKcal: (kcal: Int, days: Int)? {
        let today = Day.key(Day.today)
        let days = data.logs.values.filter { $0.hasFood && $0.date <= today }
            .sorted { $0.date > $1.date }.prefix(7)
        guard !days.isEmpty else { return nil }
        return (days.reduce(0) { $0 + $1.eatenKcal } / days.count, days.count)
    }

    var startDate: Date { Day.date(settings.startDate) ?? Day.today }

    // MARK: Peso

    var weighIns: [WeighIn] {
        data.logs.values
            .compactMap { log -> WeighIn? in
                guard let w = log.weight, let d = Day.date(log.date) else { return nil }
                return WeighIn(key: log.date, date: d, weight: w)
            }
            .sorted { $0.date < $1.date }
    }

    var currentWeight: Double { weighIns.last?.weight ?? settings.initialWeight }
    var lost: Double { settings.initialWeight - currentWeight }
    var remaining: Double { max(0, currentWeight - settings.goalWeight) }

    var goalProgress: Double {
        let total = settings.initialWeight - settings.goalWeight
        guard total > 0 else { return 0 }
        return min(1, max(0, lost / total))
    }

    /// Ritmo médio (kg por semana) desde a primeira pesagem / peso inicial.
    var weeklyRate: Double? {
        var points = weighIns.map { ($0.date, $0.weight) }
        if points.first.map({ $0.0 > startDate }) ?? false {
            points.insert((startDate, settings.initialWeight), at: 0)
        }
        guard let first = points.first, let last = points.last else { return nil }
        let days = Double(Day.cal.dateComponents([.day], from: first.0, to: last.0).day ?? 0)
        guard days >= 7 else { return nil }
        return (first.1 - last.1) / days * 7
    }

    var projectedGoalDate: Date? {
        guard let rate = weeklyRate, rate > 0.05, remaining > 0 else { return nil }
        let weeks = remaining / rate
        return Day.add(Int((weeks * 7).rounded(.up)), to: weighIns.last?.date ?? Day.today)
    }

    // MARK: Semana

    /// Pontos da semana até hoje (como a folha), a contar a partir da data de início.
    func weekPoints(containing date: Date) -> (points: Int, maxSoFar: Int) {
        let start = Day.weekStart(date)
        let today = Day.today
        var points = 0, maxSoFar = 0
        for i in 0..<7 {
            let d = Day.add(i, to: start)
            guard d <= today, d >= startDate else { continue }
            points += log(Day.key(d)).points
            maxSoFar += 4
        }
        return (points, maxSoFar)
    }

    func weekBeers(containing date: Date) -> Int {
        let start = Day.weekStart(date)
        return (0..<7).reduce(0) { $0 + log(Day.key(Day.add($1, to: start))).beers }
    }

    func recentWeeks(_ count: Int = 8) -> [WeekStat] {
        let thisWeek = Day.weekStart(Day.today)
        return (0..<count).reversed().compactMap { offset -> WeekStat? in
            let start = Day.add(-7 * offset, to: thisWeek)
            guard Day.add(6, to: start) >= Day.weekStart(startDate) else { return nil }
            let p = weekPoints(containing: start)
            return WeekStat(start: start, points: p.points, maxPoints: p.maxSoFar, beers: weekBeers(containing: start))
        }
    }

    /// Dias seguidos (até ontem ou hoje) com 4/4 pontos.
    var perfectStreak: Int {
        var streak = 0
        var d = Day.today
        if log(Day.key(d)).points < 4 { d = Day.add(-1, to: d) }
        while d >= startDate, log(Day.key(d)).points == 4 {
            streak += 1
            d = Day.add(-1, to: d)
        }
        return streak
    }

    var loggedDays: [DayLog] {
        data.logs.values.sorted { $0.date > $1.date }
    }

    // MARK: Compras

    func toggleBought(_ item: ShoppingItem) {
        guard let i = data.shopping.firstIndex(where: { $0.id == item.id }) else { return }
        data.shopping[i].bought.toggle()
        save()
    }

    func addItem(name: String, quantity: String) {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard !n.isEmpty else { return }
        data.shopping.append(ShoppingItem(name: n, quantity: quantity.trimmingCharacters(in: .whitespaces)))
        save()
    }

    func deleteItems(_ items: [ShoppingItem]) {
        let ids = Set(items.map(\.id))
        data.shopping.removeAll { ids.contains($0.id) }
        save()
    }

    func resetShopping() {
        for i in data.shopping.indices { data.shopping[i].bought = false }
        save()
    }

    func restoreDefaultShopping() {
        data.shopping = Plan.shopping
        save()
    }

    var shoppingText: String {
        let items = data.shopping.filter { !$0.bought }
        return "Lista de compras\n" + items.map { "• \($0.name)" + ($0.quantity.isEmpty ? "" : " — \($0.quantity)") }.joined(separator: "\n")
    }

    // MARK: Exportar

    var csv: String {
        var lines = ["Data;Cumpri a ementa;Doces só os planeados;Cervejas;Caminhei 30 min;Pontos;Peso (kg);Calorias (kcal);Água (L);Refeições alteradas;Notas"]
        for l in data.logs.values.sorted(by: { $0.date < $1.date }) {
            let w = l.weight.map { String(format: "%.1f", $0).replacingOccurrences(of: ".", with: ",") } ?? ""
            let notes = l.notes.replacingOccurrences(of: ";", with: ",").replacingOccurrences(of: "\n", with: " ")
            let water = String(format: "%.2f", Double(l.water) / 1000).replacingOccurrences(of: ".", with: ",")
            let changed = l.custom.keys.sorted().map { "\(Plan.meals[$0].name): \(l.custom[$0]!.text)" }
                .joined(separator: " | ").replacingOccurrences(of: ";", with: ",").replacingOccurrences(of: "\n", with: " ")
            lines.append("\(l.date);\(l.followedMenu ? "Sim" : "Não");\(l.onlyPlannedSweets ? "Sim" : "Não");\(l.beers);\(l.walked ? "Sim" : "Não");\(l.points);\(w);\(l.eatenKcal);\(water);\(changed);\(notes)")
        }
        return lines.joined(separator: "\n")
    }

    func resetAll() {
        data = AppData()
        save()
    }
}
