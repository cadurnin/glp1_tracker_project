import Foundation

/// Pure unit conversion functions. No side effects — same input always gives same output.
struct UnitConverter {
    /// Converts pounds to kilograms.
    /// - Parameters:
    ///   - lbs: Weight in pounds (must be positive).
    /// - Returns: Weight in kilograms.
    static func kgFrom(lbs: Double) -> Double { lbs * 0.453592 }

    /// Converts kilograms to pounds.
    /// - Parameters:
    ///   - kg: Weight in kilograms (must be positive).
    /// - Returns: Weight in pounds.
    static func lbsFrom(kg: Double) -> Double { kg / 0.453592 }

    /// Converts fluid ounces to litres.
    /// - Parameters:
    ///   - oz: Volume in fluid ounces (must be positive).
    /// - Returns: Volume in litres.
    static func litresFrom(oz: Double) -> Double { oz * 0.0295735296 }

    /// Converts litres to fluid ounces.
    /// - Parameters:
    ///   - litres: Volume in litres (must be positive).
    /// - Returns: Volume in fluid ounces.
    static func ozFrom(litres: Double) -> Double { litres / 0.0295735296 }
}
