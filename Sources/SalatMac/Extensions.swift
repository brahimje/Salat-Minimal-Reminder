import Foundation
import Adhan

// Note: There's a warning about conforming an imported type to an imported protocol
// but we can't use @retroactive as it's not supported in this context.
extension Prayer: Identifiable {
    public var id: Self { self }
    
    public var name: String {
        switch self {
        case .fajr:
            return "Fajr"
        case .sunrise:
            return "Sunrise"
        case .dhuhr:
            return "Dhuhr"
        case .asr:
            return "Asr"
        case .maghrib:
            return "Maghrib"
        case .isha:
            return "Isha"
        }
    }
}

enum CalculationMethod: String, CaseIterable, Identifiable {
    case muslimWorldLeague = "Muslim World League"
    case egyptian = "Egyptian"
    case karachi = "Karachi"
    case ummAlQura = "Umm Al-Qura"
    case dubai = "Dubai"
    case qatar = "Qatar"
    case kuwait = "Kuwait"
    case moonsightingCommittee = "Moonsighting Committee"
    case singapore = "Singapore"
    case turkey = "Turkey"
    case tehran = "Tehran"
    case northAmerica = "North America (ISNA)"
    
    var id: String { self.rawValue }
}
