import SwiftUI

// MARK: - Separator

struct Separator: View {
    let orientation: Orientation
    let thickness: CGFloat
    let color: Color

    enum Orientation {
        case horizontal
        case vertical
    }

    init(
        orientation: Orientation = .horizontal,
        thickness: CGFloat = 1,
        color: Color = DesignTokens.Colors.borderSubtle
    ) {
        self.orientation = orientation
        self.thickness = thickness
        self.color = color
    }

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(
                width: orientation == .horizontal ? nil : thickness,
                height: orientation == .vertical ? nil : thickness
            )
    }
}
