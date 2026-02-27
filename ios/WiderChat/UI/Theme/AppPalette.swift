import SwiftUI

enum AppPalette {
    static let primary = Color(red: 0.07, green: 0.60, blue: 0.42)
    static let background = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.06, green: 0.08, blue: 0.11, alpha: 1) : UIColor(red: 0.97, green: 0.98, blue: 0.99, alpha: 1) })
    static let surface = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.11, green: 0.14, blue: 0.18, alpha: 1) : UIColor.white })
    static let secondarySoft = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.22, green: 0.25, blue: 0.30, alpha: 1) : UIColor(red: 0.89, green: 0.93, blue: 0.97, alpha: 1) })
    static let card = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.16, green: 0.19, blue: 0.24, alpha: 1) : UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1) })
    static let textPrimary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.95, green: 0.97, blue: 0.99, alpha: 1) : UIColor(red: 0.06, green: 0.09, blue: 0.16, alpha: 1) })
    static let textSecondary = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.82, green: 0.86, blue: 0.90, alpha: 1) : UIColor(red: 0.20, green: 0.25, blue: 0.33, alpha: 1) })
    static let textMuted = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.58, green: 0.63, blue: 0.70, alpha: 1) : UIColor(red: 0.40, green: 0.46, blue: 0.54, alpha: 1) })
    static let border = Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.14) : UIColor(red: 0.88, green: 0.91, blue: 0.94, alpha: 1) })
}
