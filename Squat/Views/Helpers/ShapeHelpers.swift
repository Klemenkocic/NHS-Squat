import SwiftUI

struct Line: Shape {
    var from: CGPoint
    var to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }
}

struct GridBackground: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    // Helper to determine if we're on iPhone
    private var isPhone: Bool {
        horizontalSizeClass == .compact
    }
    
    // Grid density based on device
    private var gridDensity: CGFloat {
        isPhone ? 25 : 20
    }
    
    // Grid color based on color scheme - more pronounced
    private var gridColor: Color {
        colorScheme == .dark ? .gray.opacity(0.6) : .gray.opacity(0.5)
    }
    
    // Main grid line color (for center lines) - more pronounced
    private var mainGridColor: Color {
        colorScheme == .dark ? .gray.opacity(0.8) : .gray.opacity(0.7)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Regular grid lines
                Path { path in
                    let stepX = geometry.size.width / gridDensity
                    let stepY = geometry.size.height / gridDensity
                    
                    // Vertical lines
                    for x in stride(from: 0, through: geometry.size.width, by: stepX) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    }
                    
                    // Horizontal lines
                    for y in stride(from: 0, through: geometry.size.height, by: stepY) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    }
                }
                .stroke(gridColor, lineWidth: isPhone ? 0.5 : 0.7) // Thicker lines
                
                // Main center lines
                Path { path in
                    // Vertical center line
                    path.move(to: CGPoint(x: geometry.size.width / 2, y: 0))
                    path.addLine(to: CGPoint(x: geometry.size.width / 2, y: geometry.size.height))
                    
                    // Horizontal center line
                    path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                }
                .stroke(mainGridColor, lineWidth: isPhone ? 0.8 : 1.0) // Thicker center lines
            }
        }
    }
}

// Preview
struct ShapeHelpers_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            GridBackground()
                .frame(width: 300, height: 300)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Light Mode")
            
            GridBackground()
                .frame(width: 300, height: 300)
                .environment(\.colorScheme, .dark)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("Dark Mode")
            
            GridBackground()
                .frame(width: 300, height: 300)
                .environment(\.horizontalSizeClass, .compact)
                .previewLayout(.sizeThatFits)
                .previewDisplayName("iPhone")
        }
    }
} 