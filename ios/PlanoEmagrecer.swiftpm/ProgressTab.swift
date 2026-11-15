import SwiftUI
import Charts

struct ProgressTab: View {
    @Environment(Store.self) private var store

    var body: some View {
        NavigationStack {
            List {
                Section { weightHeader }

                Section("Evolução do peso") { weightChart }

                Section("Pontos por semana") { weeksChart }

                Section("Histórico") {
                    NavigationLink {
                        HistoryView()
                    } label: {
                        Label("Todos os dias registados", systemImage: "calendar")
                    }
                    LabeledContent("Dias seguidos com 4/4", value: "\(store.perfectStreak)")
                }
            }
            .navigationTitle("Progresso")
        }
    }

    private var weightHeader: some View {
        let s = store.settings
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                stat("Inicial", s.initialWeight)
                stat("Atual", store.currentWeight, bold: true)
                stat("Meta", s.goalWeight)
            }
            ProgressView(value: store.goalProgress) {
                HStack {
                    Text(store.lost >= 0 ? "Já perdi \(fmt(store.lost)) kg" : "Ganhei \(fmt(-store.lost)) kg")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(store.remaining > 0 ? "Faltam \(fmt(store.remaining)) kg" : "Meta atingida! 🎉")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.green)

            if let rate = store.weeklyRate {
                Label(rate > 0 ? "Ritmo: −\(fmt(rate)) kg por semana" : "Ritmo: sem descida nas últimas pesagens",
                      systemImage: "speedometer")
                    .font(.subheadline)
                if let d = store.projectedGoalDate {
                    Label("A este ritmo, chegas aos \(fmt(s.goalWeight)) kg por volta de \(Day.short(d))",
                          systemImage: "flag.checkered")
                        .font(.subheadline)
                        .foregroundStyle(.green)
                }
                if rate > 1.0 {
                    Text("Mais de 1 kg por semana é rápido. Um ritmo de 0,5–1 kg é mais fácil de manter.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Regista o peso às segundas-feiras. Ao fim de uma semana aparece o ritmo e a data prevista para chegar à meta.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func stat(_ title: String, _ value: Double, bold: Bool = false) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text("\(fmt(value))").font(bold ? .title.bold() : .title3).monospacedDigit()
            Text("kg").font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var weightChart: some View {
        let s = store.settings
        let points = [WeighIn(key: "start", date: store.startDate, weight: s.initialWeight)]
            + store.weighIns.filter { $0.date > store.startDate }
        if points.count < 2 {
            ContentUnavailableView("Ainda sem pesagens",
                                   systemImage: "scalemass",
                                   description: Text("O gráfico aparece depois da primeira pesagem."))
        } else {
            let all = points.map(\.weight) + [s.goalWeight]
            let lo = (all.min() ?? 0) - 1
            let hi = (all.max() ?? 100) + 1
            Chart {
                ForEach(points) { p in
                    LineMark(x: .value("Data", p.date), y: .value("Peso", p.weight))
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Data", p.date), y: .value("Peso", p.weight))
                }
                RuleMark(y: .value("Meta", s.goalWeight))
                    .foregroundStyle(.green)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
                    .annotation(position: .top, alignment: .leading) {
                        Text("Meta \(fmt(s.goalWeight)) kg").font(.caption2).foregroundStyle(.green)
                    }
            }
            .chartYScale(domain: lo...hi)
            .frame(height: 220)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var weeksChart: some View {
        let weeks = store.recentWeeks()
        let goal = store.settings.weeklyPointsGoal
        Chart {
            ForEach(weeks) { w in
                BarMark(x: .value("Semana", Day.short(w.start)), y: .value("Pontos", w.points))
                    .foregroundStyle(w.points >= goal ? Color.green : Color.accentColor.opacity(0.6))
                    .annotation(position: .top) {
                        Text("\(w.points)").font(.caption2).foregroundStyle(.secondary)
                    }
            }
            RuleMark(y: .value("Meta", goal))
                .foregroundStyle(.secondary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 4]))
        }
        .chartYScale(domain: 0...28)
        .frame(height: 180)
        .padding(.vertical, 8)
    }
}

struct HistoryView: View {
    @Environment(Store.self) private var store

    var body: some View {
        let days = store.loggedDays
        List {
            if days.isEmpty {
                ContentUnavailableView("Sem registos", systemImage: "calendar",
                                       description: Text("Os dias que registares aparecem aqui."))
            }
            ForEach(days, id: \.date) { log in
                if let d = Day.date(log.date) {
                    NavigationLink {
                        List { DayForm(date: d, showMeals: true) }
                            .navigationTitle(Day.short(d))
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(Day.long(d))
                                if !log.notes.isEmpty {
                                    Text(log.notes).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                            Spacer()
                            if let w = log.weight {
                                Text("\(fmt(w)) kg").font(.caption).foregroundStyle(.secondary)
                            }
                            PointsDots(points: log.points)
                        }
                    }
                }
            }
        }
        .navigationTitle("Histórico")
    }
}

func fmt(_ v: Double) -> String {
    v.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "pt_PT")))
}
