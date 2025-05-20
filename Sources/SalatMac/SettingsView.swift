import SwiftUI
import CoreLocation
import Adhan

struct SettingsView: View {
    @EnvironmentObject private var prayerTimeManager: PrayerTimeManager
    @State private var locationName: String = ""
    @State private var isSearching = false
    @State private var searchResults: [CLPlacemark] = []
    @State private var searchText: String = ""
    @State private var searchTask: Task<Void, Never>? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Prayer Times Settings")
                .font(.headline)
            
            VStack(alignment: .leading) {
                Text("Location")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Search location...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: searchText) { _ in
                        searchLocation()
                    }
                
                if isSearching {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if !searchResults.isEmpty {
                    List(searchResults, id: \.self) { placemark in
                        Button(action: {
                            selectLocation(placemark)
                        }) {
                            Text(placemarkString(for: placemark))
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(height: min(CGFloat(searchResults.count) * 30, 150))
                }
                
                if prayerTimeManager.coordinates != nil {
                    Text("Current: \(locationName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !locationName.isEmpty {
                        Text(locationName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Picker("Calculation Method", selection: $prayerTimeManager.calculationMethod) {
                ForEach(CalculationMethod.allCases) { method in
                    Text(method.rawValue).tag(method)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .onChange(of: prayerTimeManager.calculationMethod) { _ in
                prayerTimeManager.calculatePrayerTimes()
                prayerTimeManager.saveSettings()
            }
            
            Toggle("Play Adhan Sound", isOn: $prayerTimeManager.isAdhanEnabled)
                .onChange(of: prayerTimeManager.isAdhanEnabled) { _ in
                    prayerTimeManager.saveSettings()
                }
            
            if !prayerTimeManager.nextPrayerName.isEmpty {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Next Prayer:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(prayerTimeManager.nextPrayerName)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text(prayerTimeManager.nextPrayerTime)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
            }
            
            Button("Apply") {
                NSApplication.shared.keyWindow?.close()
            }
        }
        .padding()
        .frame(width: 300, height: 400)
        .onAppear {
            updateLocationName()
        }
    }
    
    private func searchLocation() {
        searchTask?.cancel()
        
        // Don't search if text is empty
        guard !searchText.isEmpty else {
            isSearching = false
            searchResults = []
            return
        }
        
        isSearching = true
        
        searchTask = Task {
            // Add a small delay to avoid too many requests while typing
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            guard !Task.isCancelled else { return }
            
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.geocodeAddressString(searchText)
                if !Task.isCancelled {
                    await MainActor.run {
                        searchResults = placemarks
                        isSearching = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    await MainActor.run {
                        searchResults = []
                        isSearching = false
                    }
                }
            }
        }
    }
    
    private func selectLocation(_ placemark: CLPlacemark) {
        guard let location = placemark.location else { return }
        
        prayerTimeManager.setLocation(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        searchText = ""
        searchResults = []
        locationName = placemarkString(for: placemark)
    }
    
    private func placemarkString(for placemark: CLPlacemark) -> String {
        let components = [placemark.locality, placemark.administrativeArea, placemark.country]
        return components.compactMap { $0 }.joined(separator: ", ")
    }
    
    private func updateLocationName() {
        guard let coords = prayerTimeManager.coordinates else { return }
        
        // Extract coordinates using reflection since properties are internal
        var lat = 0.0
        var lon = 0.0
        
        let mirror = Mirror(reflecting: coords)
        for child in mirror.children {
            if child.label == "latitude", let latitude = child.value as? Double {
                lat = latitude
            }
            if child.label == "longitude", let longitude = child.value as? Double {
                lon = longitude
            }
        }
        
        let location = CLLocation(latitude: lat, longitude: lon)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { [self] placemarks, error in
            if let placemark = placemarks?.first {
                Task { @MainActor in
                    self.locationName = self.placemarkString(for: placemark)
                }
            }
        }
    }
}
