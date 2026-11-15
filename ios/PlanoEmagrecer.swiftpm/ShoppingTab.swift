import SwiftUI

struct ShoppingTab: View {
    @Environment(Store.self) private var store
    @State private var showingAdd = false
    @State private var newName = ""
    @State private var newQty = ""
    @State private var confirmReset = false

    var body: some View {
        let toBuy = store.data.shopping.filter { !$0.bought }
        let bought = store.data.shopping.filter { $0.bought }

        NavigationStack {
            List {
                Section {
                    ProgressView(value: Double(bought.count), total: Double(max(1, store.data.shopping.count))) {
                        Text("\(bought.count) de \(store.data.shopping.count) comprados")
                            .font(.subheadline)
                    }
                    .tint(.green)
                }

                Section("Por comprar") {
                    if toBuy.isEmpty {
                        Text("Está tudo comprado 🎉").foregroundStyle(.secondary)
                    }
                    ForEach(toBuy) { row($0) }
                        .onDelete { store.deleteItems($0.map { toBuy[$0] }) }
                }

                if !bought.isEmpty {
                    Section("Comprado") {
                        ForEach(bought) { row($0) }
                            .onDelete { store.deleteItems($0.map { bought[$0] }) }
                    }
                }
            }
            .navigationTitle("Compras")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Desmarcar tudo (nova semana)", systemImage: "arrow.counterclockwise") {
                            store.resetShopping()
                        }
                        Button("Repor lista original", systemImage: "list.bullet.clipboard", role: .destructive) {
                            confirmReset = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(item: store.shoppingText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .alert("Novo produto", isPresented: $showingAdd) {
                TextField("Produto", text: $newName)
                TextField("Quantidade", text: $newQty)
                Button("Adicionar") {
                    store.addItem(name: newName, quantity: newQty)
                    newName = ""; newQty = ""
                }
                Button("Cancelar", role: .cancel) { newName = ""; newQty = "" }
            }
            .confirmationDialog("Repor a lista original? Os produtos que adicionaste são apagados.",
                                isPresented: $confirmReset, titleVisibility: .visible) {
                Button("Repor lista", role: .destructive) { store.restoreDefaultShopping() }
            }
        }
    }

    private func row(_ item: ShoppingItem) -> some View {
        Button {
            withAnimation { store.toggleBought(item) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.bought ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.bought ? Color.green : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .strikethrough(item.bought, color: .secondary)
                        .foregroundStyle(item.bought ? .secondary : .primary)
                    if !item.quantity.isEmpty {
                        Text(item.quantity).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }
}
