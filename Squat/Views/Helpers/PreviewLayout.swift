import SwiftUI

extension View {
    func previewLayout() -> some View {
        self.frame(maxWidth: .infinity, maxHeight: .infinity)
            .previewLayout(.sizeThatFits)
    }
} 