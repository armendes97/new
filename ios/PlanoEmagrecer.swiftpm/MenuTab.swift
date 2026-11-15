import SwiftUI

struct MenuTab: View {
    private var todayIndex: Int { Day.isoWeekday(Day.today) - 1 }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(0..<7, id: \.self) { d in
                        Section {
                            ForEach(Plan.meals) { meal in
                                VStack(alignment: .leading, spacing: 3) {
                                    Label(meal.name, systemImage: meal.icon)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Text(Plan.menu[d][meal.id])
                                }
                                .padding(.vertical, 2)
                            }
                        } header: {
                            HStack {
                                Text(Plan.dayNames[d])
                                if d == todayIndex {
                                    Text("HOJE")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(Color.green, in: Capsule())
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .id(d)
                    }

                    Section("Notas") {
                        Label("Sopa sempre primeiro, ao almoço e ao jantar.", systemImage: "drop")
                        Label("Um prato só, sem repetir.", systemImage: "hand.raised")
                        Label("Domingo: preparar sopa e marmitas.", systemImage: "takeoutbag.and.cup.and.straw")
                    }
                }
                .onAppear { proxy.scrollTo(todayIndex, anchor: .top) }
            }
            .navigationTitle("Ementa")
        }
    }
}
