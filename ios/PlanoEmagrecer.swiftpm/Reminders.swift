import Foundation
import UserNotifications

enum Reminders {
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func apply(_ s: AppSettings) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let wantsAny = s.nightlyReminder || s.weighInReminder || s.walkReminder || s.waterReminder
        guard wantsAny, await requestAuthorization() else { return }

        if s.nightlyReminder {
            schedule(id: "nightly",
                     title: "Hora do registo 📝",
                     body: "Marca o dia antes de dormir: ementa, doces, cerveja e caminhada.",
                     hour: s.nightlyHour)
        }
        if s.weighInReminder {
            schedule(id: "weighin",
                     title: "Pesagem de segunda ⚖️",
                     body: "Em jejum, antes do pequeno-almoço. Regista o peso na app.",
                     hour: 8, weekday: 2)
        }
        if s.walkReminder {
            schedule(id: "walk",
                     title: "Caminhada de 30 minutos 🚶",
                     body: "Ainda não caminhaste hoje? Bora!",
                     hour: s.walkHour)
        }
        if s.waterReminder {
            let goal = s.waterGoal.formatted(.number.precision(.fractionLength(0...2)).locale(Locale(identifier: "pt_PT")))
            for h in s.waterHours {
                schedule(id: "water-\(h)",
                         title: "Beber água 💧",
                         body: "Um copo de 250 ml. A meta de hoje é \(goal) L — regista na app.",
                         hour: h)
            }
        }
        // Domingo: preparar sopa e marmitas
        if s.nightlyReminder {
            schedule(id: "prep",
                     title: "Domingo de preparação 🥣",
                     body: "Prepara a sopa e as marmitas para a semana, e revê a lista de compras.",
                     hour: 11, weekday: 1)
        }
    }

    /// weekday: 1 = domingo, 2 = segunda … (Calendar do sistema)
    private static func schedule(id: String, title: String, body: String, hour: Int, weekday: Int? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = 0
        comps.weekday = weekday

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
