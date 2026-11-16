import SwiftUI

struct MoreTab: View {
    @Environment(Store.self) private var store
    @State private var confirmReset = false

    var body: some View {
        let s = store.settingsBinding

        NavigationStack {
            Form {
                Section("As minhas regras") {
                    ForEach(Array(Plan.rules.enumerated()), id: \.offset) { i, rule in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(i + 1)")
                                .font(.caption.bold())
                                .frame(width: 22, height: 22)
                                .background(Color.green.opacity(0.18), in: Circle())
                            Text(rule)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Como se ganham pontos (0–4 por dia)") {
                    Label("Cumpri a ementa", systemImage: "1.circle")
                    Label("Doces só os planeados", systemImage: "2.circle")
                    Label("Caminhei 30 minutos", systemImage: "3.circle")
                    Label("Cerveja dentro da regra: 0, ou até 2 à quarta, sábado ou domingo", systemImage: "4.circle")
                }

                Section("Objetivos") {
                    weightField("Peso inicial", value: s.initialWeight)
                    weightField("Meta", value: s.goalWeight)
                    Stepper("Meta semanal: \(s.wrappedValue.weeklyPointsGoal) pontos", value: s.weeklyPointsGoal, in: 7...28)
                    Stepper("Máx. cervejas/semana: \(s.wrappedValue.maxBeersWeek)", value: s.maxBeersWeek, in: 0...14)
                    Stepper("Calorias por dia: \(kcalText(s.wrappedValue.kcalGoal)) kcal", value: s.kcalGoal, in: 1200...4000, step: 50)
                    Stepper("Água por dia: \(litresText(s.wrappedValue.waterGoal)) L", value: s.waterGoal, in: 1...5, step: 0.25)
                    DatePicker("Início do plano",
                               selection: Binding(
                                   get: { store.startDate },
                                   set: { s.wrappedValue.startDate = Day.key(Day.cal.startOfDay(for: $0)) }),
                               displayedComponents: .date)
                }

                Section {
                    Toggle("Registo à noite", isOn: s.nightlyReminder)
                    if s.wrappedValue.nightlyReminder {
                        Stepper("Hora: \(s.wrappedValue.nightlyHour)h", value: s.nightlyHour, in: 18...23)
                    }
                    Toggle("Pesagem à segunda (8h)", isOn: s.weighInReminder)
                    Toggle("Beber água", isOn: s.waterReminder)
                    if s.wrappedValue.waterReminder {
                        Stepper("Das \(s.wrappedValue.waterStartHour)h", value: s.waterStartHour, in: 6...s.wrappedValue.waterEndHour)
                        Stepper("Até às \(s.wrappedValue.waterEndHour)h", value: s.waterEndHour, in: s.wrappedValue.waterStartHour...23)
                        Stepper("De \(s.wrappedValue.waterEveryHours) em \(s.wrappedValue.waterEveryHours) horas", value: s.waterEveryHours, in: 1...4)
                        Text("Lembretes às " + s.wrappedValue.waterHours.map { "\($0)h" }.joined(separator: ", "))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    Toggle("Caminhada diária", isOn: s.walkReminder)
                    if s.wrappedValue.walkReminder {
                        Stepper("Hora: \(s.wrappedValue.walkHour)h", value: s.walkHour, in: 6...21)
                    }
                } header: {
                    Text("Lembretes")
                } footer: {
                    Text("Com o lembrete da noite ligado, recebes também um aviso ao domingo para preparares a sopa e as marmitas.")
                }

                Section("Dados") {
                    ShareLink(item: store.csv, preview: SharePreview("Registo.csv")) {
                        Label("Exportar registo (CSV)", systemImage: "square.and.arrow.up")
                    }
                    Button("Apagar todos os dados", role: .destructive) { confirmReset = true }
                }
            }
            .navigationTitle("Plano")
            .onChange(of: store.settings) { _, new in
                Task { await Reminders.apply(new) }
            }
            .confirmationDialog("Apagar o registo, o peso e a lista de compras? Não dá para desfazer.",
                                isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Apagar tudo", role: .destructive) { store.resetAll() }
            }
        }
    }

    private func litresText(_ v: Double) -> String {
        v.formatted(.number.precision(.fractionLength(0...2)).locale(Locale(identifier: "pt_PT")))
    }

    private func weightField(_ title: String, value: Binding<Double>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: value, format: .number.precision(.fractionLength(0...1)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 90)
            Text("kg").foregroundStyle(.secondary)
        }
    }
}
