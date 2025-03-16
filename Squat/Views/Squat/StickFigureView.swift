import SwiftUI

struct StickFigureView: View {
    @ObservedObject var viewModel: SquatAnalysisViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("showGridLines") private var showGridLines = true
    
    // Responsive sizing based on device
    private var segmentLength: CGFloat {
        isPhone ? 55 : 100 // Reduced from 70 to 55 for iPhone
    }
    
    private var jointRadius: CGFloat {
        isPhone ? 5 : 8 // Slightly smaller joints on iPhone
    }
    
    // Dynamic colors based on color scheme
    private var primaryColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var accentColor: Color {
        .blue
    }
    
    private var boardColor: Color {
        .orange
    }
    
    private var barbellColor: Color {
        .yellow
    }
    
    // Helper to determine if we're on iPhone
    private var isPhone: Bool {
        horizontalSizeClass == .compact
    }
    
    // Fixed animation duration
    private let animationDuration: Double = 0.3
    
    // Function to determine torso line color based on hip angle
    private func torsoLineColor(hipAngle: CGFloat) -> Color {
        if hipAngle >= 80 && hipAngle <= 90 {
            return .green
        } else if hipAngle >= 70 && hipAngle < 80 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Background Grid - only show if enabled and with higher opacity
                if showGridLines {
                    GridBackground()
                        .opacity(colorScheme == .dark ? 0.3 : 0.25) // More pronounced
                }
                
                // Angle Display - Position it properly
                AngleDisplay(angles: viewModel.jointAngles)
                    .padding(.top, isPhone ? 12 : 20)
                    .padding(.leading, isPhone ? 12 : 20)
                
                Canvas { context, size in
                    // Set the origin to the bottom center, adjusted to leave more space at the top
                    let verticalOffset = isPhone ? 0.75 : 0.8 // Reduced from 0.8 to 0.75 for iPhone
                    context.translateBy(x: size.width/2, y: size.height * verticalOffset)
                    
                    let angles = viewModel.jointAngles
                    
                    // Calculate board dimensions
                    let width = segmentLength * 0.8
                    let boardAngleRad = viewModel.boardHeight.angle * Double.pi / 180.0
                    
                    // Draw the board at ground level (y = 0)
                    drawBoard(context: context, 
                             at: .zero,  // Board stays at origin
                             boardHeight: viewModel.boardHeight, 
                             segmentLength: segmentLength)
                    
                    // Calculate ankle position to be on the hypotenuse of the board
                    let anklePoint: CGPoint
                    if viewModel.boardHeight != .none {
                        // Calculate the height of the ankle based on its position on the hypotenuse
                        let halfWidth = width / 2
                        let heightAtAnkle = halfWidth * tan(boardAngleRad)  // Height at the middle of the board
                        anklePoint = CGPoint(
                            x: 0,  // Center horizontally
                            y: -heightAtAnkle  // Lift the ankle to the board height at center
                        )
                    } else {
                        anklePoint = .zero
                    }
                    
                    // Calculate joint positions using different lengths for femur and tibia
                    let femurLength = segmentLength * viewModel.femurLength.lengthMultiplier
                    let tibiaLength = segmentLength  // Keep tibia length constant
                    
                    let ankleAngleRad = angles.ankle * Double.pi / 180
                    let kneePoint = CGPoint(
                        x: anklePoint.x + tibiaLength * cos(ankleAngleRad),
                        y: anklePoint.y - tibiaLength * sin(ankleAngleRad)
                    )
                    
                    let kneeAngleRad = angles.knee * Double.pi / 180
                    let hipPoint = CGPoint(
                        x: kneePoint.x + femurLength * cos(kneeAngleRad),
                        y: kneePoint.y - femurLength * sin(kneeAngleRad)
                    )
                    
                    let hipAngleRad = angles.hip * Double.pi / 180
                    let shoulderPoint = CGPoint(
                        x: hipPoint.x + segmentLength * cos(hipAngleRad),
                        y: hipPoint.y - segmentLength * sin(hipAngleRad)
                    )
                    
                    // Draw segments (bones) with gradient
                    // Draw ankle to knee and knee to hip with normal gradient
                    let lowerSegments = [(anklePoint, kneePoint), (kneePoint, hipPoint)]
                    for (start, end) in lowerSegments {
                        // Create a linear gradient for the bone
                        let gradient = Gradient(colors: [accentColor, primaryColor])
                        _ = GraphicsContext.Shading.linearGradient(
                            gradient,
                            startPoint: start,
                            endPoint: end
                        )
                        
                        context.stroke(
                            Path { path in
                                path.move(to: start)
                                path.addLine(to: end)
                            },
                            with: .linearGradient(
                                gradient,
                                startPoint: start,
                                endPoint: end
                            ),
                            lineWidth: isPhone ? 2.0 : 3.5
                        )
                    }
                    
                    // Draw hip to shoulder with color based on hip angle
                    let torsoColor = torsoLineColor(hipAngle: angles.hip)
                    context.stroke(
                        Path { path in
                            path.move(to: hipPoint)
                            path.addLine(to: shoulderPoint)
                        },
                        with: .color(torsoColor),
                        lineWidth: isPhone ? 2.0 : 3.5
                    )
                    
                    // Draw joints with shadow effect
                    for point in [anklePoint, kneePoint, hipPoint, shoulderPoint] {
                        // Draw shadow
                        context.fill(
                            Path(ellipseIn: CGRect(
                                x: point.x - jointRadius + CGFloat(1),
                                y: point.y - jointRadius + CGFloat(1),
                                width: jointRadius * 2,
                                height: jointRadius * 2
                            )),
                            with: .color(.black.opacity(0.3))
                        )
                        
                        // Draw joint
                        context.fill(
                            Path(ellipseIn: CGRect(
                                x: point.x - jointRadius,
                                y: point.y - jointRadius,
                                width: jointRadius * 2,
                                height: jointRadius * 2
                            )),
                            with: .color(accentColor)
                        )
                    }
                    
                    // Draw head with more detail - adjusted position
                    let headRadius = jointRadius * 2
                    let headOffset = isPhone ? CGFloat(2.0) : CGFloat(3.0) // Reduced vertical offset for head on iPhone
                    
                    // Head shadow
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: shoulderPoint.x - headRadius + CGFloat(1),
                            y: shoulderPoint.y - headRadius * headOffset + CGFloat(1),
                            width: headRadius * 2,
                            height: headRadius * 2
                        )),
                        with: .color(.black.opacity(0.3))
                    )
                    
                    // Head
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: shoulderPoint.x - headRadius,
                            y: shoulderPoint.y - headRadius * headOffset,
                            width: headRadius * 2,
                            height: headRadius * 2
                        )),
                        with: .color(primaryColor)
                    )
                    
                    // Draw barbell with gradient - adjusted position
                    let barbellRadius = jointRadius * 3.5 // Slightly smaller barbell
                    let barbellOffset = isPhone ? CGFloat(2.5) : CGFloat(3.0) // Position barbell above the head
                    
                    // Barbell shadow
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: shoulderPoint.x - barbellRadius + CGFloat(2),
                            y: shoulderPoint.y - jointRadius * barbellOffset - barbellRadius/2 + CGFloat(2),
                            width: barbellRadius * 2,
                            height: barbellRadius * 2
                        )),
                        with: .color(.black.opacity(0.3))
                    )
                    
                    // Barbell with gradient
                    let barbellGradient = Gradient(colors: [barbellColor, barbellColor.opacity(0.7)])
                    context.fill(
                        Path(ellipseIn: CGRect(
                            x: shoulderPoint.x - barbellRadius,
                            y: shoulderPoint.y - jointRadius * barbellOffset - barbellRadius/2,
                            width: barbellRadius * 2,
                            height: barbellRadius * 2
                        )),
                        with: .linearGradient(
                            barbellGradient,
                            startPoint: CGPoint(x: shoulderPoint.x - barbellRadius, y: shoulderPoint.y - jointRadius * barbellOffset),
                            endPoint: CGPoint(x: shoulderPoint.x + barbellRadius, y: shoulderPoint.y - jointRadius * barbellOffset)
                        )
                    )
                }
            }
        }
        .animation(.spring(response: animationDuration, dampingFraction: 0.7), value: viewModel.squatDepth)
        .animation(.spring(response: animationDuration, dampingFraction: 0.7), value: viewModel.femurLength)
        .animation(.spring(response: animationDuration, dampingFraction: 0.7), value: viewModel.boardHeight)
    }
    
    // Add this function to draw the board triangle
    private func drawBoard(context: GraphicsContext, at anklePoint: CGPoint, boardHeight: SquatMechanics.BoardHeight, segmentLength: CGFloat) {
        guard boardHeight != .none else { return }
        
        // Board dimensions based on segmentLength
        let width = segmentLength * 0.8
        let angleInRadians = boardHeight.angle * Double.pi / 180.0
        let height = width * tan(angleInRadians)
        
        // Calculate triangle points (flipped upward)
        let leftPoint = CGPoint(x: anklePoint.x - width/2, y: anklePoint.y)
        let rightPoint = CGPoint(x: anklePoint.x + width/2, y: anklePoint.y)
        let bottomPoint = CGPoint(x: anklePoint.x - width/2, y: anklePoint.y - height)
        
        // Draw shadow
        let shadowPath = Path { path in
            path.move(to: CGPoint(x: leftPoint.x + CGFloat(2), y: leftPoint.y + CGFloat(2)))
            path.addLine(to: CGPoint(x: rightPoint.x + CGFloat(2), y: rightPoint.y + CGFloat(2)))
            path.addLine(to: CGPoint(x: bottomPoint.x + CGFloat(2), y: bottomPoint.y + CGFloat(2)))
            path.closeSubpath()
        }
        context.fill(shadowPath, with: .color(.black.opacity(0.2)))
        
        // Draw filled triangle with gradient
        let boardGradient = Gradient(colors: [boardColor.opacity(0.7), boardColor.opacity(0.3)])
        context.fill(
            Path { path in
                path.move(to: leftPoint)
                path.addLine(to: rightPoint)
                path.addLine(to: bottomPoint)
                path.closeSubpath()
            },
            with: .linearGradient(
                boardGradient,
                startPoint: leftPoint,
                endPoint: rightPoint
            )
        )
        
        // Draw triangle outline
        context.stroke(
            Path { path in
                path.move(to: leftPoint)
                path.addLine(to: rightPoint)
                path.addLine(to: bottomPoint)
                path.closeSubpath()
            },
            with: .color(boardColor),
            lineWidth: isPhone ? 1.5 : 2
        )
    }
}

private struct AngleDisplay: View {
    let angles: SquatMechanics.JointAngles
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    // Helper to determine if we're on iPhone
    private var isPhone: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: isPhone ? 6 : 8) {
            Text("Joint Angles")
                .font(isPhone ? .subheadline : .headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Group {
                AngleRow(title: "Hip", value: angles.hip, color: .blue)
                AngleRow(title: "Knee", value: angles.knee, color: .green)
                AngleRow(title: "Ankle", value: angles.ankle, color: .orange)
            }
        }
        .padding(isPhone ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(.systemBackground))
                .shadow(
                    color: .black.opacity(0.1),
                    radius: 8,
                    x: 0,
                    y: 2
                )
        )
        .frame(width: isPhone ? 130 : 160)
    }
}

private struct AngleRow: View {
    let title: String
    let value: CGFloat
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .foregroundColor(.secondary)
                .font(.caption)
            Spacer()
            Text("\(Int(value))°")
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundColor(color)
        }
    }
}

// Preview
struct StickFigureView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StickFigureView(viewModel: SquatAnalysisViewModel())
                .frame(height: 400)
                .previewDevice("iPhone 14 Pro")
                .previewDisplayName("iPhone")
            
            StickFigureView(viewModel: SquatAnalysisViewModel())
                .frame(height: 400)
                .environment(\.colorScheme, .dark)
                .previewDevice("iPhone 14 Pro")
                .previewDisplayName("iPhone (Dark)")
            
            StickFigureView(viewModel: SquatAnalysisViewModel())
                .frame(height: 400)
                .previewDevice("iPad Pro (11-inch) (4th generation)")
                .previewDisplayName("iPad")
        }
    }
} 
