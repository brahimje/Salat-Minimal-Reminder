import Foundation
import Adhan
import AVFoundation
import OSLog

@MainActor
class PrayerTimeManager: ObservableObject {
    @Published var prayerTimes: PrayerTimes?
    @Published var coordinates: Coordinates?
    @Published var timezone: TimeZone = .current
    @Published var calculationMethod: CalculationMethod = .northAmerica
    @Published var nextPrayerName: String = ""
    @Published var nextPrayerTime: String = ""
    @Published var isAdhanEnabled: Bool = true
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    private var nextPrayerTimer: Timer?
    
    init() {
        loadSettings()
        calculatePrayerTimes()
        setupTimer()
    }
    
    func calculatePrayerTimes() {
        guard let coordinates = coordinates else { return }
        
        let calendar = Calendar.current
        let date = calendar.dateComponents([.year, .month, .day], from: Date())
        
        // Use the Adhan library's calculation parameters directly based on selected method
        var params: CalculationParameters
        
        switch calculationMethod {
        case .northAmerica:
            params = Adhan.CalculationMethod.northAmerica.params
        case .muslimWorldLeague:
            params = Adhan.CalculationMethod.muslimWorldLeague.params
        case .egyptian:
            params = Adhan.CalculationMethod.egyptian.params
        case .karachi:
            params = Adhan.CalculationMethod.karachi.params
        case .ummAlQura:
            params = Adhan.CalculationMethod.ummAlQura.params
        case .dubai:
            params = Adhan.CalculationMethod.dubai.params
        case .qatar:
            params = Adhan.CalculationMethod.qatar.params
        case .kuwait:
            params = Adhan.CalculationMethod.kuwait.params
        case .moonsightingCommittee:
            params = Adhan.CalculationMethod.moonsightingCommittee.params
        case .singapore:
            params = Adhan.CalculationMethod.singapore.params
        case .turkey:
            params = Adhan.CalculationMethod.turkey.params
        case .tehran:
            params = Adhan.CalculationMethod.tehran.params
        }
        
        // Using init without the try since the library doesn't actually throw
        let prayerTimes = PrayerTimes(coordinates: coordinates, date: date, calculationParameters: params)
        self.prayerTimes = prayerTimes
        updateNextPrayer()
    }
    
    func updateNextPrayer() {
        guard let prayerTimes = prayerTimes else { return }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let prayers = Prayer.allCases.filter { $0 != .sunrise }
        let date = Date()
        
        for prayer in prayers {
            let prayerTime = prayerTimes.time(for: prayer)
            if prayerTime > date {
                nextPrayerName = prayer.name
                nextPrayerTime = formatter.string(from: prayerTime)
                
                // Schedule adhan alert
                scheduleAdhanAlert(for: prayerTime, prayer: prayer)
                
                return
            }
        }
        
        // If all prayers for today have passed, calculate tomorrow's Fajr
        guard let coordinates = coordinates else { return }
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        let tomorrowComponents = Calendar.current.dateComponents([.year, .month, .day], from: tomorrow)
        
        // Get appropriate calculation parameters
        var params: CalculationParameters
        
        switch calculationMethod {
        case .northAmerica:
            params = Adhan.CalculationMethod.northAmerica.params
        case .muslimWorldLeague:
            params = Adhan.CalculationMethod.muslimWorldLeague.params
        case .egyptian:
            params = Adhan.CalculationMethod.egyptian.params
        case .karachi:
            params = Adhan.CalculationMethod.karachi.params
        case .ummAlQura:
            params = Adhan.CalculationMethod.ummAlQura.params
        case .dubai:
            params = Adhan.CalculationMethod.dubai.params
        case .qatar:
            params = Adhan.CalculationMethod.qatar.params
        case .kuwait:
            params = Adhan.CalculationMethod.kuwait.params
        case .moonsightingCommittee:
            params = Adhan.CalculationMethod.moonsightingCommittee.params
        case .singapore:
            params = Adhan.CalculationMethod.singapore.params
        case .turkey:
            params = Adhan.CalculationMethod.turkey.params
        case .tehran:
            params = Adhan.CalculationMethod.tehran.params
        }
        
        // Using init without the try since the library doesn't actually throw
        if let tomorrowPrayerTimes = PrayerTimes(coordinates: coordinates, date: tomorrowComponents, calculationParameters: params) {
            let fajrTime = tomorrowPrayerTimes.time(for: Prayer.fajr)
            nextPrayerName = "Fajr (Tomorrow)"
            nextPrayerTime = formatter.string(from: fajrTime)
            
            // Schedule adhan alert for tomorrow's fajr
            scheduleAdhanAlert(for: fajrTime, prayer: Prayer.fajr)
        }
    }
    
    private func scheduleAdhanAlert(for prayerTime: Date, prayer: Prayer) {
        // Cancel any existing timer
        nextPrayerTimer?.invalidate()
        
        // Calculate time interval until prayer time
        let timeInterval = prayerTime.timeIntervalSince(Date())
        
        // Only schedule if the prayer is in the future
        guard timeInterval > 0 else {
            Task { @MainActor in
                updateNextPrayer()
            }
            return
        }
        
        // Schedule new timer
        nextPrayerTimer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.playAdhan()
                // Recalculate next prayer after current one passes
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                self?.updateNextPrayer()
            }
        }
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        
        // Extract coordinates using reflection since properties are internal
        if let coords = coordinates {
            let mirror = Mirror(reflecting: coords)
            for child in mirror.children {
                if child.label == "latitude", let latitude = child.value as? Double {
                    defaults.set(latitude, forKey: "latitude")
                }
                if child.label == "longitude", let longitude = child.value as? Double {
                    defaults.set(longitude, forKey: "longitude")
                }
            }
        }
        
        defaults.set(timezone.identifier, forKey: "timezone")
        defaults.set(calculationMethod.rawValue, forKey: "calculationMethod")
        defaults.set(isAdhanEnabled, forKey: "isAdhanEnabled")
    }
    
    func loadSettings() {
        let defaults = UserDefaults.standard
        let latitude = defaults.double(forKey: "latitude")
        let longitude = defaults.double(forKey: "longitude")
        
        if latitude != 0 && longitude != 0 {
            coordinates = Coordinates(latitude: latitude, longitude: longitude)
        }
        
        if let timezoneIdentifier = defaults.string(forKey: "timezone"),
           let timezone = TimeZone(identifier: timezoneIdentifier) {
            self.timezone = timezone
        }
        
        if let methodValue = defaults.string(forKey: "calculationMethod"),
           let method = CalculationMethod(rawValue: methodValue) {
            calculationMethod = method
        }
        
        isAdhanEnabled = defaults.bool(forKey: "isAdhanEnabled")
    }
    
    func setLocation(latitude: Double, longitude: Double) {
        coordinates = Coordinates(latitude: latitude, longitude: longitude)
        calculatePrayerTimes()
        saveSettings()
    }
    
    private func setupTimer() {
        // Recalculate prayer times at midnight
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                let calendar = Calendar.current
                let currentComponents = calendar.dateComponents([.hour, .minute], from: Date())
                
                // Update at midnight
                if currentComponents.hour == 0 && currentComponents.minute == 0 {
                    self.calculatePrayerTimes()
                }
            }
        }
    }
    
    func playAdhan() {
        guard isAdhanEnabled else { return }
        
        if let adhanURL = Bundle.module.url(forResource: "adhan", withExtension: "mp3") {
            do {
                player = try AVAudioPlayer(contentsOf: adhanURL)
                player?.prepareToPlay()
                player?.play()
            } catch {
                let logger = Logger(subsystem: "com.salat.app", category: "Media")
                logger.error("Failed to play adhan: \(error.localizedDescription)")
            }
        } else {
            let logger = Logger(subsystem: "com.salat.app", category: "Media")
            logger.error("Could not find adhan.mp3 resource")
        }
    }
    
    // We need to add a cleanup method since deinit can't be marked with @MainActor
    func cleanup() {
        timer?.invalidate()
        timer = nil
        nextPrayerTimer?.invalidate()
        nextPrayerTimer = nil
    }
    
    deinit {
        // Can't directly access timers here due to actor isolation
        // Use cleanup() method instead before releasing this object
    }
}
