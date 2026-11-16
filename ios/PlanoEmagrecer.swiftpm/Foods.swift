import Foundation

// Gerado a partir da versão web (index.html): calorias da ementa e lista de alimentos.

struct Food: Identifiable, Hashable {
    let id: Int
    let name: String
    let kcal: Double
    let portion: String
    let category: String
}

enum Foods {
    /// Calorias estimadas de cada refeição da ementa [dia 0…6][refeição 0…4]
    static let menuKcal: [[Int]] = [
        [370, 175, 650, 260, 420],
        [365, 220, 490, 200, 345],
        [370, 175, 685, 220, 440],
        [365, 220, 660, 260, 495],
        [370, 175, 570, 200, 415],
        [330, 270, 800, 200, 580],
        [370, 175, 620, 260, 400]
    ]

    static let beerKcal = 140

    private static let raw: [(String, Double, String, String)] = [
        ("Prato do dia de carne", 750, "dose", "Restaurante"),
        ("Prato do dia de peixe", 600, "dose", "Restaurante"),
        ("Meia dose (prato do dia)", 450, "meia dose", "Restaurante"),
        ("Bitoque com ovo, batata frita e arroz", 1100, "dose", "Restaurante"),
        ("Bife grelhado com salada", 450, "dose", "Restaurante"),
        ("Francesinha com batatas", 1500, "dose", "Restaurante"),
        ("Bacalhau à Brás", 750, "dose", "Restaurante"),
        ("Bacalhau com natas", 850, "dose", "Restaurante"),
        ("Bacalhau cozido com grão e batata", 600, "dose", "Restaurante"),
        ("Arroz de pato", 800, "dose", "Restaurante"),
        ("Arroz de marisco", 650, "dose", "Restaurante"),
        ("Feijoada", 850, "dose", "Restaurante"),
        ("Cozido à portuguesa", 1000, "dose", "Restaurante"),
        ("Carne de porco à alentejana", 900, "dose", "Restaurante"),
        ("Rojões com batata", 900, "dose", "Restaurante"),
        ("Alheira com ovo e batata frita", 950, "dose", "Restaurante"),
        ("Frango assado (½ frango, com pele)", 550, "½ frango", "Restaurante"),
        ("Frango de churrasco (¼, com pele)", 350, "¼ frango", "Restaurante"),
        ("Febras grelhadas", 400, "2 febras", "Restaurante"),
        ("Peixe grelhado", 300, "dose", "Restaurante"),
        ("Sardinhas assadas", 400, "4 sardinhas", "Restaurante"),
        ("Polvo à lagareiro", 650, "dose", "Restaurante"),
        ("Caldeirada de peixe", 550, "dose", "Restaurante"),
        ("Lasanha", 650, "dose", "Restaurante"),
        ("Esparguete à bolonhesa", 700, "dose", "Restaurante"),
        ("Massa carbonara", 800, "dose", "Restaurante"),
        ("Empadão", 600, "dose", "Restaurante"),
        ("Hambúrguer no prato com ovo", 650, "dose", "Restaurante"),
        ("Salada César com frango", 500, "dose", "Restaurante"),
        ("Salada de atum", 350, "dose", "Restaurante"),
        ("Omelete (3 ovos) com salada", 330, "dose", "Restaurante"),
        ("Pizza", 280, "fatia", "Fast food"),
        ("Pizza média inteira", 1100, "pizza", "Fast food"),
        ("Menu hambúrguer (batatas + bebida)", 1100, "menu", "Fast food"),
        ("Hambúrguer simples", 300, "unidade", "Fast food"),
        ("Kebab / durum", 750, "unidade", "Fast food"),
        ("Sushi", 45, "peça", "Fast food"),
        ("Nuggets de frango", 50, "unidade", "Fast food"),
        ("Cachorro", 450, "unidade", "Fast food"),
        ("Prego no pão", 500, "unidade", "Sandes"),
        ("Bifana no pão", 450, "unidade", "Sandes"),
        ("Tosta mista", 350, "unidade", "Sandes"),
        ("Sandes mista", 300, "unidade", "Sandes"),
        ("Sandes de atum", 350, "unidade", "Sandes"),
        ("Sandes de frango", 380, "unidade", "Sandes"),
        ("Wrap de frango", 450, "unidade", "Sandes"),
        ("Sopa de legumes", 90, "prato", "Sopas e acompanhamentos"),
        ("Sopa de feijão ou grão", 180, "prato", "Sopas e acompanhamentos"),
        ("Caldo verde", 150, "prato", "Sopas e acompanhamentos"),
        ("Arroz cozido", 200, "chávena", "Sopas e acompanhamentos"),
        ("Batata frita", 400, "dose", "Sopas e acompanhamentos"),
        ("Batata cozida", 110, "batata média", "Sopas e acompanhamentos"),
        ("Puré de batata", 200, "dose", "Sopas e acompanhamentos"),
        ("Massa cozida", 220, "chávena", "Sopas e acompanhamentos"),
        ("Feijão ou grão cozido", 120, "½ chávena", "Sopas e acompanhamentos"),
        ("Legumes cozidos ou salteados", 50, "dose", "Sopas e acompanhamentos"),
        ("Salada com azeite", 80, "dose", "Sopas e acompanhamentos"),
        ("Frango grelhado (peito)", 165, "100 g", "Carne, peixe e ovos"),
        ("Peru grelhado", 110, "100 g", "Carne, peixe e ovos"),
        ("Bife de vaca", 220, "100 g", "Carne, peixe e ovos"),
        ("Lombo de porco", 160, "100 g", "Carne, peixe e ovos"),
        ("Salmão", 205, "100 g", "Carne, peixe e ovos"),
        ("Pescada / peixe branco", 80, "100 g", "Carne, peixe e ovos"),
        ("Atum ao natural", 100, "lata", "Carne, peixe e ovos"),
        ("Ovo cozido", 75, "unidade", "Carne, peixe e ovos"),
        ("Ovo estrelado", 110, "unidade", "Carne, peixe e ovos"),
        ("Pão (papo-seco)", 150, "unidade", "Pão e pequeno-almoço"),
        ("Pão integral", 80, "fatia", "Pão e pequeno-almoço"),
        ("Broa de milho", 150, "fatia", "Pão e pequeno-almoço"),
        ("Torrada com manteiga", 350, "dose", "Pão e pequeno-almoço"),
        ("Croissant simples", 230, "unidade", "Pão e pequeno-almoço"),
        ("Croissant misto", 380, "unidade", "Pão e pequeno-almoço"),
        ("Cereais com leite", 300, "taça", "Pão e pequeno-almoço"),
        ("Papas de aveia (40 g + leite)", 270, "taça", "Pão e pequeno-almoço"),
        ("Panquecas de aveia", 370, "dose", "Pão e pequeno-almoço"),
        ("Queijo fresco", 100, "unidade", "Pão e pequeno-almoço"),
        ("Queijo flamengo", 70, "fatia", "Pão e pequeno-almoço"),
        ("Fiambre de peru", 20, "fatia", "Pão e pequeno-almoço"),
        ("Manteiga", 75, "c. chá cheia", "Pão e pequeno-almoço"),
        ("Manteiga de amendoim", 95, "c. sopa", "Pão e pequeno-almoço"),
        ("Iogurte natural", 70, "unidade", "Lanches"),
        ("Iogurte grego natural", 120, "unidade", "Lanches"),
        ("Skyr natural", 95, "unidade", "Lanches"),
        ("Iogurte açucarado ou líquido", 130, "unidade", "Lanches"),
        ("Peça de fruta (maçã, pera, laranja)", 80, "unidade", "Lanches"),
        ("Banana", 105, "unidade", "Lanches"),
        ("Kiwi", 45, "unidade", "Lanches"),
        ("Frutos secos", 190, "punhado (30 g)", "Lanches"),
        ("Barra de cereais", 120, "unidade", "Lanches"),
        ("Bolachas Maria", 33, "bolacha", "Lanches"),
        ("Pastel de nata", 300, "unidade", "Doces"),
        ("Bola de Berlim", 450, "unidade", "Doces"),
        ("Queque", 350, "unidade", "Doces"),
        ("Bolo", 350, "fatia", "Doces"),
        ("Chocolate negro 70%", 55, "quadrado", "Doces"),
        ("Chocolate de leite", 540, "tablete 100 g", "Doces"),
        ("Gelado", 150, "bola", "Doces"),
        ("Mousse de chocolate", 300, "taça", "Doces"),
        ("Arroz doce", 300, "taça", "Doces"),
        ("Batatas fritas de pacote", 250, "pacote pequeno", "Doces"),
        ("Amendoins", 170, "punhado", "Doces"),
        ("Café", 2, "chávena", "Bebidas"),
        ("Café com açúcar", 22, "chávena", "Bebidas"),
        ("Galão", 120, "copo", "Bebidas"),
        ("Meia de leite", 90, "chávena", "Bebidas"),
        ("Leite meio-gordo", 115, "copo 250 ml", "Bebidas"),
        ("Imperial / fino", 85, "20 cl", "Bebidas"),
        ("Cerveja mini", 105, "25 cl", "Bebidas"),
        ("Cerveja", 140, "33 cl", "Bebidas"),
        ("Cerveja sem álcool", 70, "33 cl", "Bebidas"),
        ("Vinho", 125, "copo", "Bebidas"),
        ("Refrigerante", 140, "lata", "Bebidas"),
        ("Refrigerante zero", 1, "lata", "Bebidas"),
        ("Sumo de laranja natural", 110, "copo", "Bebidas"),
        ("Água", 0, "copo", "Bebidas")
    ]

    static let all: [Food] = raw.enumerated().map { i, f in
        Food(id: i, name: f.0, kcal: f.1, portion: f.2, category: f.3)
    }

    static func search(_ text: String) -> [Food] {
        let words = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .split(separator: " ").map(String.init)
        guard !words.isEmpty else { return all }
        return all.filter { f in
            let hay = (f.name + " " + f.category).folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            return words.allSatisfy { hay.contains($0) }
        }
    }
}
