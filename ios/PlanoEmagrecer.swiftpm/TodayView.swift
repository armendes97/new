import SwiftUI
import UIKit

struct TodayView: View {
    @Environment(Store.self) private var store
    @State private var selected = Day.today

    private var isToday: Bool { selected == Day.today }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    daySwitcher
                }

                Section {
                    WeekSummaryCard(date: selected)
                }

                DayForm(date: selected, showMeals: true)
            }
            .navigationTitle(isToday ? "Hoje" : "Registo")
            .toolbar {
                if !isToday {
                    Button("Hoje") { withAnimation { selected = Day.today } }
                }
            }
        }
    }

    private var daySwitcher: some View {
        HStack {
            Button {
                withAnimation { selected = Day.add(-1, to: selected) }
            } label: {
                Image(systemName: "chevron.left").font(.title3.bold())
            }
            .buttonStyle(.borderless)

            Spacer()
            VStack(spacing: 2) {
                Text(Day.long(selected)).font(.headline)
                let pts = store.log(Day.key(selected)).points
                Text(selected > Day.today ? "Dia futuro" : "\(pts) de 4 pontos")
                    .font(.subheadline)
                    .foregroundStyle(pts == 4 ? Color.green : Color.secondary)
            }
            Spacer()

            Button {
                withAnimation { selected = Day.add(1, to: selected) }
            } label: {
                Image(systemName: "chevron.right").font(.title3.bold())
            }
            .buttonStyle(.borderless)
        }
    }
}

/// Formulário de um dia: refeições, calorias, água, as 4 regras que dão pontos, peso e notas.
struct DayForm: View {
    @Environment(Store.self) private var store
    let date: Date
    var showMeals = true
    @State private var editing: EditTarget?

    var body: some View {
        let key = Day.key(date)
        let log = store.binding(for: key)
        let beerDay = DayLog.isBeerDay(date)

        if showMeals {
            Section {
                ForEach(Plan.meals) { meal in
                    MealRow(meal: meal, effective: log.wrappedValue.meal(meal.id),
                            done: log.wrappedValue.mealsDone[meal.id],
                            toggle: { log.wrappedValue.mealsDone[meal.id].toggle() },
                            edit: { editing = EditTarget(date: date, meal: meal.id) })
                }
            } header: {
                Text("Ementa — \(Plan.dayNames[Day.isoWeekday(date) - 1])")
            } footer: {
                Text("Toca na refeição quando a fizeres. Com o lápis trocas por outro dia, registas o que comeste fora ou reescreves.")
            }
            .sheet(item: $editing) { target in
                MealEditSheet(target: target, current: target.meal.map { store.log(key).meal($0) })
            }

            CaloriesSection(key: key, log: log.wrappedValue) {
                editing = EditTarget(date: date, meal: nil)
            }

            WaterSection(key: key, ml: log.wrappedValue.water)
        }

        Section {
            Toggle(isOn: log.followedMenu) {
                Label("Cumpri a ementa", systemImage: "fork.knife")
            }
            Toggle(isOn: log.onlyPlannedSweets) {
                Label("Doces só os planeados", systemImage: "birthday.cake")
            }
            Toggle(isOn: log.walked) {
                Label("Caminhei 30 min", systemImage: "figure.walk")
            }
            Stepper(value: log.beers, in: 0...12) {
                HStack {
                    Label("Cervejas", systemImage: "mug")
                    Spacer()
                    Text("\(log.wrappedValue.beers)")
                        .monospacedDigit()
                        .foregroundStyle(log.wrappedValue.beerOK ? Color.primary : Color.red)
                }
            }
        } header: {
            HStack {
                Text("Pontos do dia")
                Spacer()
                PointsDots(points: log.wrappedValue.points)
            }
        } footer: {
            Text(beerDay
                 ? "Hoje é dia de cerveja permitida: até 2. Um copo de água entre cada uma."
                 : "Hoje não é dia de cerveja: qualquer cerveja tira o ponto. Prefere sem álcool.")
                .foregroundStyle(log.wrappedValue.beerOK ? Color.secondary : Color.red)
        }

        Section {
            HStack {
                Label("Peso", systemImage: "scalemass")
                Spacer()
                TextField("—", value: log.weight, format: .number.precision(.fractionLength(0...1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 90)
                Text("kg").foregroundStyle(.secondary)
            }
            TextField("Notas do dia", text: log.notes, axis: .vertical)
                .lineLimit(1...5)
        } header: {
            Text("Peso e notas")
        } footer: {
            if Day.isoWeekday(date) == 1 {
                Text("É segunda-feira: pesa-te de manhã, em jejum, e regista aqui.")
            } else {
                Text("A regra é pesar só à segunda-feira de manhã.")
            }
        }
    }
}

struct MealRow: View {
    let meal: Meal
    let effective: EffectiveMeal
    let done: Bool
    let toggle: () -> Void
    let edit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Button(action: toggle) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(done ? Color.green : Color.secondary)
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Label(meal.name, systemImage: meal.icon)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            if let c = effective.change { ChangeTag(change: c) }
                        }
                        Text(effective.text)
                            .foregroundStyle(.primary)
                            .strikethrough(done, color: .secondary)
                        if let c = effective.change, c.mode != .swap {
                            Text("Na ementa: \(effective.original)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Text(effective.kcal.map { "≈ \(kcalText($0)) kcal" } ?? "kcal por indicar")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button(action: edit) {
                Image(systemName: "square.and.pencil").font(.title3)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Alterar \(meal.name)")
        }
    }
}

struct ChangeTag: View {
    let change: CustomMeal

    var body: some View {
        let (label, color): (String, Color) = {
            switch change.mode {
            case .swap:
                let day = change.fromDay.map { Plan.dayNames[$0].components(separatedBy: " ").first ?? "" } ?? ""
                return ("de \(day.lowercased())", .green)
            case .eaten: return ("o que comi", .orange)
            case .edit: return ("alterado", .green)
            }
        }()
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6).padding(.vertical, 1)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

struct CaloriesSection: View {
    @Environment(Store.self) private var store
    let key: String
    let log: DayLog
    let addExtra: () -> Void

    var body: some View {
        let goal = store.settings.kcalGoal
        let eaten = log.eatenKcal
        let over = eaten > goal
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(kcalText(eaten)).font(.title.bold()).monospacedDigit()
                    Text("kcal comidas").foregroundStyle(.secondary)
                    Spacer()
                    Text(over ? "+\(kcalText(eaten - goal)) acima" : "faltam \(kcalText(goal - eaten))")
                        .font(.subheadline.weight(over ? .semibold : .regular))
                        .foregroundStyle(over ? Color.orange : Color.secondary)
                }
                ProgressView(value: Double(min(eaten, goal)), total: Double(max(goal, 1)))
                    .tint(over ? .orange : .green)
                Text(plannedText).font(.caption).foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)

            ForEach(log.extras) { x in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(x.qty != 1 ? "\(fmtQty(x.qty)) × \(x.name)" : x.name)
                        Text("extra").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("≈ \(kcalText(Int(x.total.rounded()))) kcal").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .onDelete { idx in
                let ids = idx.map { log.extras[$0].id }
                ids.forEach { store.removeExtra(key, id: $0) }
            }

            Button(action: addExtra) {
                Label("Adicionar extra (petisco, doce, bebida…)", systemImage: "plus.circle")
            }
        } header: {
            HStack {
                Text("Calorias")
                Spacer()
                Text("meta \(kcalText(goal)) kcal")
            }
        } footer: {
            Text("Valores aproximados. As cervejas do contador contam \(Foods.beerKcal) kcal cada. Desliza um extra para o apagar.")
        }
    }

    private var plannedText: String {
        var t = "Previsto para o dia: ≈ \(kcalText(log.plannedKcal)) kcal"
        if log.mealsWithoutKcal > 0 { t += " (+ \(log.mealsWithoutKcal) refeição sem kcal)" }
        if log.beersKcal > 0 { t += " · cervejas \(kcalText(log.beersKcal)) kcal" }
        return t
    }
}

func litres(_ ml: Int) -> String {
    (Double(ml) / 1000).formatted(.number.precision(.fractionLength(1...2)).locale(Locale(identifier: "pt_PT")))
}

struct WaterSection: View {
    @Environment(Store.self) private var store
    let key: String
    let ml: Int

    var body: some View {
        let goal = Int((store.settings.waterGoal * 1000).rounded())
        let done = ml >= goal
        let glasses = max(Int((Double(goal) / 250).rounded(.up)), ml / 250)
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(litres(ml)) L").font(.title.bold()).monospacedDigit().foregroundStyle(.blue)
                    Text("bebidos").foregroundStyle(.secondary)
                    Spacer()
                    Text(done ? "Meta cumprida 💧" : "faltam \(litres(goal - ml)) L")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), alignment: .leading, spacing: 6) {
                    ForEach(0..<glasses, id: \.self) { i in
                        Image(systemName: i < ml / 250 ? "drop.fill" : (i == ml / 250 && ml % 250 >= 125 ? "drop.halffull" : "drop"))
                            .font(.title3)
                            .foregroundStyle(.blue)
                    }
                }
                .accessibilityHidden(true)
                HStack(spacing: 10) {
                    Button { add(250) } label: { Text("+ 250 ml").frame(maxWidth: .infinity) }
                    Button { add(500) } label: { Text("+ 500 ml").frame(maxWidth: .infinity) }
                    Button { store.addWater(key, ml: -250) } label: { Image(systemName: "minus") }
                        .accessibilityLabel("Tirar 250 ml")
                }
                .buttonStyle(.bordered)
                .tint(.blue)
            }
            .padding(.vertical, 4)
        } header: {
            HStack {
                Text("Água")
                Spacer()
                Text("meta \(litres(goal)) L")
            }
        } footer: {
            Text("Cada gota são 250 ml. Bebe um copo antes de cada refeição e um entre cada cerveja.")
        }
    }

    private func add(_ amount: Int) {
        let goal = Int((store.settings.waterGoal * 1000).rounded())
        let before = ml
        store.addWater(key, ml: amount)
        if before < goal && before + amount >= goal {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

struct PointsDots: View {
    let points: Int
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(i < points ? Color.green : Color.secondary.opacity(0.25))
                    .frame(width: 9, height: 9)
            }
        }
        .accessibilityLabel("\(points) de 4 pontos")
    }
}

struct WeekSummaryCard: View {
    @Environment(Store.self) private var store
    let date: Date

    var body: some View {
        let s = store.settings
        let week = store.weekPoints(containing: date)
        let beers = store.weekBeers(containing: date)
        let progress = Double(week.points) / 28

        HStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color.secondary.opacity(0.2), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(week.points >= s.weeklyPointsGoal ? Color.green : Color.accentColor,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Circle()
                    .trim(from: Double(s.weeklyPointsGoal) / 28 - 0.004, to: Double(s.weeklyPointsGoal) / 28 + 0.004)
                    .stroke(Color.primary.opacity(0.6), lineWidth: 14)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(week.points)").font(.title2.bold()).monospacedDigit()
                    Text("/ 28").font(.caption2).foregroundStyle(.secondary)
                }
            }
            .frame(width: 76, height: 76)
            .animation(.easeInOut, value: week.points)

            VStack(alignment: .leading, spacing: 6) {
                Text("Esta semana").font(.headline)
                Text(pointsMessage(points: week.points, maxSoFar: week.maxSoFar, goal: s.weeklyPointsGoal))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label("Cervejas: \(beers) de \(s.maxBeersWeek)", systemImage: "mug")
                    .font(.subheadline)
                    .foregroundStyle(beers > s.maxBeersWeek ? Color.red : Color.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func pointsMessage(points: Int, maxSoFar: Int, goal: Int) -> String {
        if points >= goal { return "Meta de \(goal) pontos atingida! 💪" }
        let remainingDays = 28 - maxSoFar
        let needed = goal - points
        if needed > remainingDays { return "Faltam \(needed) para a meta de \(goal). Já não dá esta semana, mas cada ponto conta." }
        return "Faltam \(needed) pontos para a meta de \(goal)."
    }
}
