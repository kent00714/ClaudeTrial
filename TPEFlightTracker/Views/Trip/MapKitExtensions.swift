import Foundation
import MapKit
import Contacts

// MARK: - MKPlacemark Extensions

extension MKPlacemark {
    /// Returns a formatted address string using postal address formatter
    /// Falls back to manual formatting if postal address is not available
    var addressDescription: String? {
        // Try to use the postal address with CNPostalAddressFormatter
        if let postalAddress = postalAddress {
            return CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
                .replacingOccurrences(of: "\n", with: ", ")
        }
        
        // Fallback to manual formatting
        return manuallyFormattedAddress
    }
    
    /// Returns a compact formatted address (street + city only)
    var compactAddress: String? {
        var components: [String] = []
        
        if let thoroughfare = thoroughfare {
            components.append(thoroughfare)
        }
        
        if let locality = locality {
            components.append(locality)
        }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
    
    /// Manually formats address from components
    private var manuallyFormattedAddress: String? {
        var components: [String] = []
        
        // Street number and name
        if let subThoroughfare = subThoroughfare, let thoroughfare = thoroughfare {
            components.append("\(subThoroughfare) \(thoroughfare)")
        } else if let thoroughfare = thoroughfare {
            components.append(thoroughfare)
        }
        
        // Sub-locality (neighborhood/district)
        if let subLocality = subLocality {
            components.append(subLocality)
        }
        
        // City
        if let locality = locality {
            components.append(locality)
        }
        
        // Administrative area (state/province)
        if let administrativeArea = administrativeArea {
            components.append(administrativeArea)
        }
        
        // Postal code
        if let postalCode = postalCode {
            components.append(postalCode)
        }
        
        // Return joined string or nil if no components
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

// MARK: - CLLocationCoordinate2D Extensions

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

extension CLLocationCoordinate2D {
    /// Calculate distance to another coordinate in meters
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return from.distance(from: to)
    }
    
    /// Returns a human-readable string for the coordinate
    var coordinateString: String {
        let latDirection = latitude >= 0 ? "N" : "S"
        let lonDirection = longitude >= 0 ? "E" : "W"
        return String(format: "%.4f°%@ %.4f°%@", abs(latitude), latDirection, abs(longitude), lonDirection)
    }
}
