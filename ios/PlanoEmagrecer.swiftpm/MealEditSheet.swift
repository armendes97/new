import SwiftUI

/// O que se está a alterar: uma refeição do dia, ou um extra (meal == nil).
struct EditTarget: Identifiable {
    let id = UUID()
    let date: Date
    let meal: Int?
}

func fmtQty(_ q: Double) -> String {
    let whole = Int(q)
    let half = q - Double(whole) >= 0.5
    let s = (whole > 0 ? "\(whole)" : "") + (half ? "½" : "")
    return s.isEmpty ? "0" : s
}

func kcalText(_ v: Int) -> String {
    v.formatted(.number.locale(Locale(identifier: "pt_PT")))
}

struct MealEditSheet: View {
    @Environment(Store.self) private var store
    @Environment(\.dismiss) private var dismiss

    let target: EditTarget

    enum Tab: String, CaseIterable, Identifiable {
        case swap = "Trocar", eat = "O que comi", write = "Escrever"
        var id: String { rawValue }
    }

    @State private var tab: Tab
    @State private var items: [FoodItem]
    @State private var query = ""
    @State private var text: String
    @State private var kcalInput: String
    @State private var customName = ""
    @State private var customKcal = ""

    init(target: EditTarget, current: EffectiveMeal?) {
        self.target = target
        let change = current?.change
        switch change?.mode {
        case .eaten?: _tab = State(initialValue: .eat)
        case .edit?: _tab = State(initialValue: .write)
        default: _tab = State(initialValue: target.meal == nil ? .eat : .swap)
        }
        _items = State(initialValue: change?.mode == .eaten ? change!.items : [])
        _text = State(initialValue: change?.mode == .edit ? change!.text : "")
        _kcalInput = State(initialValue: change?.mode == .edit ? (change!.kcal.map { String($0) } ?? "") : "")
    }

    private var key: String { Day.key(target.date) }
    private var weekday: Int { Day.isoWeekday(target.date) - 1 }
    private var total: Double { items.reduce(0) { $0 + $1.total } }
    private var isExtra: Bool { target.meal == nil }

    private var title: String {
        guard let m = target.meal else { return "Adicionar extra" }
        return "\(Plan.meals[m].name) · \(Plan.dayNames[weekday].components(separatedBy: " ").first ?? "")"
    }

    var body: some View {
        NavigationStack {
            List {
                if let m = target.meal {
                    let cur = store.log(key).meal(m)
                    Section(cur.changed ? "Agora" : "Previsto na ementa") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cur.text)
                            Text(cur.kcal.map { "≈ \(kcalText($0)) kcal" } ?? "kcal por indicar")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if cur.changed {
                            Button("Repor a da ementa", systemImage: "arrow.uturn.backward") {
                                store.setMeal(key, m, nil)
                                dismiss()
                            }
                        }
                    }
                    Section {
                        Picker("Como alterar", selection: $tab) {
                            ForEach(Tab.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                    }
                }

                switch tab {
                case .swap: swapSection
                case .eat: eatSections
                case .write: writeSection
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
                if tab != .swap {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(isExtra ? "Adicionar" : "Guardar") { save() }
                            .disabled(tab == .eat ? items.isEmpty : text.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
            }
        }
    }

    // MARK: Trocar

    @ViewBuilder
    private var swapSection: some View {
        if let m = target.meal {
            Section("Troca pelo \(Plan.meals[m].name.lowercased()) de outro dia") {
                ForEach(0..<7, id: \.self) { d in
                    if d != weekday {
                        Button {
                            store.setMeal(key, m, CustomMeal(mode: .swap, text: Plan.menu[d][m],
                                                             kcal: Foods.menuKcal[d][m], fromDay: d))
                            dismiss()
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(Plan.dayNames[d]).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                                Text(Plan.menu[d][m]).foregroundStyle(.primary)
                                Text("≈ \(kcalText(Foods.menuKcal[d][m])) kcal").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: O que comi

    @ViewBuilder
    private var eatSections: some View {
        Section {
            if items.isEmpty {
                Text("Procura e toca em + para juntar o que comeste. Ajusta as porções com − e +.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach($items) { $item in
                Stepper(value: $item.qty, in: 0.5...20, step: 0.5) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(fmtQty(item.qty)) × \(item.name)")
                        Text("\(item.portion) · ≈ \(kcalText(Int(item.total.rounded()))) kcal")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { items.remove(atOffsets: $0) }
            if !items.isEmpty {
                HStack {
                    Text("Total").bold()
                    Spacer()
                    Text("≈ \(kcalText(Int(total.rounded()))) kcal").bold()
                }
            }
        } header: {
            Text(isExtra ? "Extras a juntar" : "O que comi")
        } footer: {
            if !items.isEmpty { Text("Desliza para a esquerda para tirar um alimento.") }
        }

        Section("Outro alimento") {
            HStack {
                TextField("Nome", text: $customName)
                TextField("kcal", text: $customKcal)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                Button {
                    addCustom()
                } label: {
                    Image(systemName: "plus.circle.fill").font(.title2)
                }
                .buttonStyle(.borderless)
                .disabled(customName.trimmingCharacters(in: .whitespaces).isEmpty || Double(customKcal) == nil)
            }
        }

        Section {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Procurar: prato do dia, bitoque, sandes…", text: $query)
                    .autocorrectionDisabled()
                if !query.isEmpty {
                    Button { query = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }
                        .buttonStyle(.borderless)
                }
            }
        }

        let results = Foods.search(query)
        let categories = results.reduce(into: [String]()) { if !$0.contains($1.category) { $0.append($1.category) } }
        if results.isEmpty {
            Section { Text("Nada encontrado. Usa \"Outro alimento\".").foregroundStyle(.secondary) }
        }
        ForEach(categories, id: \.self) { cat in
            Section(cat) {
                ForEach(results.filter { $0.category == cat }) { food in
                    Button {
                        add(food)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name).foregroundStyle(.primary)
                                Text("\(food.portion) · \(kcalText(Int(food.kcal))) kcal")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill").font(.title3).foregroundStyle(.green)
                        }
                    }
                }
            }
        }
    }

    private func add(_ food: Food) {
        if let i = items.firstIndex(where: { $0.name == food.name }) {
            items[i].qty += 1
        } else {
            items.append(FoodItem(name: food.name, kcal: food.kcal, portion: food.portion))
        }
    }

    private func addCustom() {
        let name = customName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty, let k = Double(customKcal.replacingOccurrences(of: ",", with: ".")), k >= 0 else { return }
        items.append(FoodItem(name: name, kcal: k.rounded(), portion: "porção"))
        customName = ""
        customKcal = ""
    }

    // MARK: Escrever

    private var writeSection: some View {
        Section {
            TextField("Ex.: Prato do dia na cantina — frango grelhado com arroz e salada", text: $text, axis: .vertical)
                .lineLimit(3...8)
            HStack {
                Text("Calorias (opcional)")
                Spacer()
                TextField("kcal", text: $kcalInput)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 90)
            }
        } footer: {
            Text("Não sabes as calorias? Usa \"O que comi\" para as calcular.")
        }
    }

    // MARK: Guardar

    private func save() {
        switch tab {
        case .swap:
            break
        case .eat:
            guard !items.isEmpty else { return }
            if let m = target.meal {
                let text = items.map { ($0.qty != 1 ? "\(fmtQty($0.qty))× " : "") + $0.name }.joined(separator: " + ")
                store.setMeal(key, m, CustomMeal(mode: .eaten, text: text, kcal: Int(total.rounded()), items: items),
                              markDone: true)
            } else {
                store.addExtras(key, items)
            }
        case .write:
            guard let m = target.meal else { return }
            let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !t.isEmpty else { return }
            let k = Int(kcalInput.trimmingCharacters(in: .whitespaces))
            store.setMeal(key, m, CustomMeal(mode: .edit, text: t, kcal: k))
        }
        dismiss()
    }
}
