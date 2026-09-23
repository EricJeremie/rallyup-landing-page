import SwiftUI

enum RallyTheme {
    static let tennis = Color(red: 167.0 / 255.0, green: 230.0 / 255.0, blue: 50.0 / 255.0)
    static let authLime = Color(red: 184.0 / 255.0, green: 1, blue: 0)
    static let authForest = Color(red: 8.0 / 255.0, green: 46.0 / 255.0, blue: 32.0 / 255.0)
    static let authForestSoft = Color(red: 14.0 / 255.0, green: 58.0 / 255.0, blue: 43.0 / 255.0)
    static let authPanel = Color(red: 26.0 / 255.0, green: 26.0 / 255.0, blue: 28.0 / 255.0)
    static let authIvory = Color(red: 244.0 / 255.0, green: 243.0 / 255.0, blue: 236.0 / 255.0)
    static let authMuted = Color(red: 188.0 / 255.0, green: 204.0 / 255.0, blue: 194.0 / 255.0)
    static let darkGreen = Color(red: 15.0 / 255.0, green: 43.0 / 255.0, blue: 31.0 / 255.0)
    static let secondaryAction = Color(red: 50.0 / 255.0, green: 74.0 / 255.0, blue: 60.0 / 255.0)
    static let ink = Color(red: 31.0 / 255.0, green: 31.0 / 255.0, blue: 31.0 / 255.0)
    static let secondaryInk = Color(red: 138.0 / 255.0, green: 138.0 / 255.0, blue: 138.0 / 255.0)
    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)
    static let separator = Color(uiColor: .separator).opacity(0.35)

    static let pagePadding: CGFloat = 20
    static let cardRadius: CGFloat = 20
}

enum RallyInterWeight: String {
    case regular = "Regular"
    case medium = "Medium"
    case semibold = "SemiBold"
    case bold = "Bold"
    case black = "Black"
}

extension Font {
    static func inter(
        _ size: CGFloat,
        weight: RallyInterWeight = .regular,
        relativeTo textStyle: Font.TextStyle = .body
    ) -> Font {
        .custom("Inter-\(weight.rawValue)", size: size, relativeTo: textStyle)
    }
}

extension View {
    func rallyCard() -> some View {
        padding(18)
            .background(RallyTheme.card, in: RoundedRectangle(cornerRadius: RallyTheme.cardRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: RallyTheme.cardRadius, style: .continuous)
                    .strokeBorder(RallyTheme.separator, lineWidth: 1)
            }
    }
}
