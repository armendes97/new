import SwiftUI

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

/// Formulário de um dia: refeições, as 4 regras que dão pontos, peso e notas.
struct DayForm: View {
    @Environment(Store.self) private var store
    let date: Date
    var showMeals = true

    var body: some View {
        let key = Day.key(date)
        let log = store.binding(for: key)
        let menu = Plan.menu(for: date)
        let beerDay = DayLog.isBeerDay(date)

        if showMeals {
            Section {
                ForEach(Plan.meals) { meal in
                    Button {
                        log.wrappedValue.mealsDone[meal.id].toggle()
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: log.wrappedValue.mealsDone[meal.id] ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(log.wrappedValue.mealsDone[meal.id] ? Color.green : Color.secondary)
                            VStack(alignment: .leading, spacing: 3) {
                                Label(meal.name, systemImage: meal.icon)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(menu[meal.id])
                                    .foregroundStyle(.primary)
                                    .strikethrough(log.wrappedValue.mealsDone[meal.id], color: .secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("Ementa — \(Plan.dayNames[Day.isoWeekday(date) - 1])")
            } footer: {
                Text("Marca as refeições ao longo do dia. Com as 5 marcadas, \"Cumpri a ementa\" fica feito.")
            }
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
