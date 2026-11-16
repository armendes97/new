import Foundation

// MARK: - Datas

enum Day {
    /// Calendário com semanas a começar à segunda-feira (como a folha: WEEKDAY(...;2)).
    static let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        c.minimumDaysInFirstWeek = 4
        c.timeZone = .current
        c.locale = Locale(identifier: "pt_PT")
        return c
    }()

    private static let keyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func key(_ date: Date) -> String { keyFormatter.string(from: date) }
    static func date(_ key: String) -> Date? { keyFormatter.date(from: key) }

    static var today: Date { cal.startOfDay(for: Date()) }

    /// 1 = segunda … 7 = domingo
    static func isoWeekday(_ date: Date) -> Int {
        let w = cal.component(.weekday, from: date) // 1 = domingo
        return (w + 5) % 7 + 1
    }

    static func weekStart(_ date: Date) -> Date {
        cal.dateInterval(of: .weekOfYear, for: date)?.start ?? cal.startOfDay(for: date)
    }

    static func add(_ days: Int, to date: Date) -> Date {
        cal.date(byAdding: .day, value: days, to: date) ?? date
    }

    static func long(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.wide).day().month(.wide).locale(Locale(identifier: "pt_PT"))).capitalizedFirst
    }

    static func short(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "pt_PT")))
    }
}

extension String {
    var capitalizedFirst: String { prefix(1).uppercased() + dropFirst() }
}

// MARK: - Registo diário

struct DayLog: Codable, Hashable {
    var date: String
    var followedMenu = false
    var onlyPlannedSweets = false
    var beers = 0
    var walked = false
    var weight: Double? = nil
    var notes = ""
    var mealsDone: [Bool] = Array(repeating: false, count: 5)
    /// Refeições alteradas neste dia (índice 0…4).
    var custom: [Int: CustomMeal] = [:]
    /// Extras fora das refeições (petiscos, doces, bebidas).
    var extras: [FoodItem] = []
    /// Água bebida, em ml.
    var water = 0

    init(date: String) { self.date = date }

    /// Dias em que a cerveja é permitida (máx. 2): quarta, sábado e domingo.
    static func isBeerDay(_ date: Date) -> Bool {
        let wd = Day.isoWeekday(date)
        return wd == 3 || wd >= 6
    }

    var beerOK: Bool {
        guard let d = Day.date(date) else { return beers == 0 }
        return beers == 0 || (DayLog.isBeerDay(d) && beers <= 2)
    }

    /// Mesma regra da folha: ementa + doces + caminhada + cerveja dentro da regra (0–4).
    var points: Int {
        [followedMenu, onlyPlannedSweets, walked, beerOK].filter { $0 }.count
    }

    // Descodificação tolerante, para versões futuras não perderem dados.
    enum CodingKeys: String, CodingKey { case date, followedMenu, onlyPlannedSweets, beers, walked, weight, notes, mealsDone, custom, extras, water }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        date = try c.decode(String.self, forKey: .date)
        followedMenu = try c.decodeIfPresent(Bool.self, forKey: .followedMenu) ?? false
        onlyPlannedSweets = try c.decodeIfPresent(Bool.self, forKey: .onlyPlannedSweets) ?? false
        beers = try c.decodeIfPresent(Int.self, forKey: .beers) ?? 0
        walked = try c.decodeIfPresent(Bool.self, forKey: .walked) ?? false
        weight = try c.decodeIfPresent(Double.self, forKey: .weight)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        var meals = try c.decodeIfPresent([Bool].self, forKey: .mealsDone) ?? []
        while meals.count < 5 { meals.append(false) }
        mealsDone = Array(meals.prefix(5))
        custom = try c.decodeIfPresent([Int: CustomMeal].self, forKey: .custom) ?? [:]
        extras = try c.decodeIfPresent([FoodItem].self, forKey: .extras) ?? []
        water = try c.decodeIfPresent(Int.self, forKey: .water) ?? 0
    }
}

// MARK: - Refeições alteradas e calorias

struct FoodItem: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var kcal: Double
    var portion: String
    var qty: Double = 1

    var total: Double { kcal * qty }
}

enum MealChange: String, Codable {
    case swap   // trocada pela de outro dia
    case eaten  // o que comi (com alimentos)
    case edit   // escrita à mão
}

struct CustomMeal: Codable, Hashable {
    var mode: MealChange
    var text: String
    var kcal: Int?
    var fromDay: Int? = nil
    var items: [FoodItem] = []
}

/// A refeição que vale para um dia: a da ementa ou a alterada.
struct EffectiveMeal {
    let text: String
    let kcal: Int?
    let change: CustomMeal?
    let original: String

    var changed: Bool { change != nil }
}

extension DayLog {
    func meal(_ i: Int) -> EffectiveMeal {
        let wd = (Day.date(date).map(Day.isoWeekday) ?? 1) - 1
        let original = Plan.menu[wd][i]
        if let c = custom[i] {
            return EffectiveMeal(text: c.text, kcal: c.kcal, change: c, original: original)
        }
        return EffectiveMeal(text: original, kcal: Foods.menuKcal[wd][i], change: nil, original: original)
    }

    var extrasKcal: Double { extras.reduce(0) { $0 + $1.total } }
    var beersKcal: Int { beers * Foods.beerKcal }

    /// Calorias das refeições marcadas + extras + cervejas.
    var eatenKcal: Int {
        let meals = (0..<5).reduce(0) { sum, i in mealsDone[i] ? sum + (meal(i).kcal ?? 0) : sum }
        return meals + Int(extrasKcal.rounded()) + beersKcal
    }

    /// Calorias previstas para o dia (todas as refeições + extras + cervejas).
    var plannedKcal: Int {
        let meals = (0..<5).reduce(0) { $0 + (meal($1).kcal ?? 0) }
        return meals + Int(extrasKcal.rounded()) + beersKcal
    }

    var mealsWithoutKcal: Int { (0..<5).filter { meal($0).kcal == nil }.count }
    var hasFood: Bool { mealsDone.contains(true) || !extras.isEmpty }
}

// MARK: - Compras

struct ShoppingItem: Codable, Hashable, Identifiable {
    var id = UUID()
    var name: String
    var quantity: String
    var bought = false
}

// MARK: - Definições

struct AppSettings: Codable, Hashable {
    var initialWeight: Double = 93
    var goalWeight: Double = 85
    var weeklyPointsGoal: Int = 22
    var maxBeersWeek: Int = 4
    var startDate: String = Day.key(Day.today)

    var nightlyReminder = false
    var nightlyHour = 22
    var weighInReminder = false
    var walkReminder = false
    var walkHour = 18

    var kcalGoal = 2000
    /// Meta de água em litros.
    var waterGoal: Double = 2.5
    var waterReminder = false
    var waterStartHour = 9
    var waterEndHour = 19
    var waterEveryHours = 2

    init() {}

    // Leitura tolerante: dados guardados por versões antigas não têm os campos novos.
    enum CodingKeys: String, CodingKey {
        case initialWeight, goalWeight, weeklyPointsGoal, maxBeersWeek, startDate
        case nightlyReminder, nightlyHour, weighInReminder, walkReminder, walkHour
        case kcalGoal, waterGoal, waterReminder, waterStartHour, waterEndHour, waterEveryHours
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings()
        initialWeight = try c.decodeIfPresent(Double.self, forKey: .initialWeight) ?? d.initialWeight
        goalWeight = try c.decodeIfPresent(Double.self, forKey: .goalWeight) ?? d.goalWeight
        weeklyPointsGoal = try c.decodeIfPresent(Int.self, forKey: .weeklyPointsGoal) ?? d.weeklyPointsGoal
        maxBeersWeek = try c.decodeIfPresent(Int.self, forKey: .maxBeersWeek) ?? d.maxBeersWeek
        startDate = try c.decodeIfPresent(String.self, forKey: .startDate) ?? d.startDate
        nightlyReminder = try c.decodeIfPresent(Bool.self, forKey: .nightlyReminder) ?? d.nightlyReminder
        nightlyHour = try c.decodeIfPresent(Int.self, forKey: .nightlyHour) ?? d.nightlyHour
        weighInReminder = try c.decodeIfPresent(Bool.self, forKey: .weighInReminder) ?? d.weighInReminder
        walkReminder = try c.decodeIfPresent(Bool.self, forKey: .walkReminder) ?? d.walkReminder
        walkHour = try c.decodeIfPresent(Int.self, forKey: .walkHour) ?? d.walkHour
        kcalGoal = try c.decodeIfPresent(Int.self, forKey: .kcalGoal) ?? d.kcalGoal
        waterGoal = try c.decodeIfPresent(Double.self, forKey: .waterGoal) ?? d.waterGoal
        waterReminder = try c.decodeIfPresent(Bool.self, forKey: .waterReminder) ?? d.waterReminder
        waterStartHour = try c.decodeIfPresent(Int.self, forKey: .waterStartHour) ?? d.waterStartHour
        waterEndHour = try c.decodeIfPresent(Int.self, forKey: .waterEndHour) ?? d.waterEndHour
        waterEveryHours = try c.decodeIfPresent(Int.self, forKey: .waterEveryHours) ?? d.waterEveryHours
    }

    /// Horas dos lembretes de água.
    var waterHours: [Int] {
        guard waterEveryHours > 0, waterStartHour <= waterEndHour else { return [] }
        return Array(stride(from: waterStartHour, through: waterEndHour, by: waterEveryHours))
    }
}

struct AppData: Codable {
    var logs: [String: DayLog] = [:]
    var shopping: [ShoppingItem] = Plan.shopping
    var settings = AppSettings()

    init() {}

    enum CodingKeys: String, CodingKey { case logs, shopping, settings }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        logs = try c.decodeIfPresent([String: DayLog].self, forKey: .logs) ?? [:]
        shopping = try c.decodeIfPresent([ShoppingItem].self, forKey: .shopping) ?? Plan.shopping
        settings = try c.decodeIfPresent(AppSettings.self, forKey: .settings) ?? AppSettings()
    }
}

// MARK: - Plano (conteúdo da folha)

struct Meal: Identifiable {
    let id: Int
    let name: String
    let icon: String
}

enum Plan {
    static let meals: [Meal] = [
        Meal(id: 0, name: "Pequeno-almoço", icon: "sunrise"),
        Meal(id: 1, name: "Lanche da manhã", icon: "cup.and.saucer"),
        Meal(id: 2, name: "Almoço", icon: "fork.knife"),
        Meal(id: 3, name: "Lanche da tarde", icon: "carrot"),
        Meal(id: 4, name: "Jantar", icon: "moon.stars")
    ]

    static let dayNames = ["Segunda", "Terça", "Quarta (bola)", "Quinta", "Sexta", "Sábado", "Domingo"]

    /// menu[diaDaSemana 0…6][refeição 0…4]
    static let menu: [[String]] = [
        [
            "Papas de aveia: 40 g aveia + 250 ml leite meio-gordo + 1 banana",
            "Skyr natural + 1 maçã",
            "Sopa de legumes + frango grelhado (170 g) com 1 chávena de arroz cozido e brócolos",
            "2 fatias de pão integral + queijo fresco",
            "Sopa + omelete de 3 ovos com espinafres + salada"
        ],
        [
            "3 ovos mexidos + 1 fatia de pão integral + 1 kiwi",
            "Iogurte grego natural + 1 pera",
            "Sopa + bacalhau com grão (150 g bacalhau, 4 c. sopa de grão), ovo cozido e salada",
            "1 fatia de pão integral + fiambre de peru + 1 peça de fruta",
            "Sopa + peito de peru grelhado (150 g) + legumes salteados"
        ],
        [
            "Papas de aveia: 40 g aveia + 250 ml leite + 1 banana",
            "Skyr natural + 1 maçã",
            "Sopa + esparguete à bolonhesa (150 g carne picada magra, 80 g massa crua) + salada",
            "Antes do jogo: 1 fatia de pão integral + manteiga de amendoim (1 c. chá) + 1 banana",
            "Sopa + atum ao natural com feijão-frade, cebola e ovo cozido. Se beberes cerveja, sem pão nem batata"
        ],
        [
            "3 ovos mexidos + 1 fatia de pão integral + 1 kiwi",
            "Iogurte grego natural + 1 pera",
            "Sopa + salmão no forno (150 g) com 2 batatas cozidas médias e legumes",
            "2 fatias de pão integral + queijo fresco",
            "Sopa + wrap integral com frango desfiado e legumes salteados"
        ],
        [
            "Papas de aveia: 40 g aveia + 250 ml leite + 1 banana",
            "Skyr natural + 1 maçã",
            "Sopa + lombo de porco grelhado (150 g) + 1 chávena de arroz + salada",
            "1 fatia de pão integral + fiambre de peru + 1 peça de fruta",
            "Sopa + pescada cozida com legumes e 1 batata"
        ],
        [
            "2 ovos + 2 fatias de pão integral + tomate",
            "1 peça de fruta + 1 punhado pequeno de frutos secos (30 g)",
            "Refeição livre com moderação: come a sopa primeiro, um prato só, sem repetir",
            "Iogurte grego natural + 1 peça de fruta",
            "Sopa + hambúrguer caseiro de vaca magra (150 g) em pão integral com salada"
        ],
        [
            "Panquecas de aveia: 1 banana + 2 ovos + 30 g aveia",
            "Skyr natural + 1 peça de fruta",
            "Sopa + frango assado sem pele + 2 batatas assadas médias + salada",
            "2 fatias de pão integral + queijo fresco",
            "Sopa + tosta mista em pão integral + salada. Preparar marmitas e sopa para a semana"
        ]
    ]

    static func menu(for date: Date) -> [String] { menu[Day.isoWeekday(date) - 1] }

    static let rules: [String] = [
        "Sopa sempre primeiro, ao almoço e ao jantar.",
        "Sirvo o prato uma vez e não repito. A travessa não fica na mesa.",
        "Cerveja só à quarta (depois da bola) e num dia do fim de semana, no máximo 2 de cada vez. Nos outros dias, cerveja sem álcool.",
        "Um copo de água entre cada cerveja, e nada de batatas fritas ou amendoins a acompanhar.",
        "Um doce planeado por semana, num dia que escolho. Em casa não há gulodices.",
        "Quando me apetece um doce fora do plano, espero 10 minutos e como fruta, um iogurte ou 2 quadrados de chocolate negro.",
        "Caminho 30 minutos por dia, todos os dias.",
        "Peso-me só à segunda-feira de manhã, em jejum, e registo na app.",
        "Se falhar uma refeição, a seguinte é normal: não compenso, não desisto.",
        "Ao domingo preparo a sopa e as marmitas para a semana.",
        "Preencho o registo todas as noites antes de dormir. A meta é pelo menos 22 pontos por semana."
    ]

    private static let shoppingRaw: [(String, String)] = [
        ("Aveia em flocos", "500 g"),
        ("Leite meio-gordo", "2 L"),
        ("Bananas", "7"),
        ("Fruta variada (maçãs, peras, kiwis)", "14 peças"),
        ("Skyr ou iogurte grego natural", "10"),
        ("Ovos", "2 dúzias"),
        ("Pão integral", "1 pão de forma grande"),
        ("Queijo fresco", "3"),
        ("Fiambre de peru", "200 g"),
        ("Peito de frango", "500 g"),
        ("Frango para assar", "1 pequeno"),
        ("Peito de peru", "150 g"),
        ("Bacalhau demolhado", "150 g"),
        ("Salmão", "1 posta"),
        ("Pescada", "1 posta"),
        ("Lombo de porco", "150 g"),
        ("Carne picada de vaca magra", "300 g"),
        ("Atum ao natural", "3 latas"),
        ("Grão cozido", "1 frasco"),
        ("Feijão-frade cozido", "1 frasco"),
        ("Arroz", "500 g"),
        ("Esparguete integral", "500 g"),
        ("Batatas", "2 kg"),
        ("Legumes para sopa (abóbora, cenoura, courgette, alho-francês, cebola)", "para 2 panelas"),
        ("Brócolos", "1"),
        ("Espinafres", "1 saco"),
        ("Alface ou salada pronta", "2 sacos"),
        ("Tomate", "6"),
        ("Wraps integrais", "1 pacote"),
        ("Manteiga de amendoim 100%", "1 frasco pequeno"),
        ("Frutos secos (nozes ou amêndoas)", "200 g"),
        ("Chocolate negro 70%", "1 tablete (para o doce planeado)"),
        ("Cerveja sem álcool", "6"),
        ("Azeite", "se faltar")
    ]

    static var shopping: [ShoppingItem] {
        shoppingRaw.map { ShoppingItem(name: $0.0, quantity: $0.1) }
    }
}
