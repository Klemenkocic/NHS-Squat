import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SquatAnalysisViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    // Helper to determine if we're on iPhone
    private var isPhone: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: isPhone ? 12 : 16) {
                // Stick Figure Section
                StickFigureView(viewModel: viewModel)
                    .frame(height: isPhone ? 320 : 400)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(.systemBackground))
                            .shadow(
                                color: .black.opacity(0.1),
                                radius: 8,
                                x: 0,
                                y: 2
                            )
                    }
                    .padding(.horizontal, isPhone ? 12 : 16)
                    .padding(.top, isPhone ? 8 : 0)
                
                // Controls Section
                VStack(spacing: isPhone ? 12 : 16) {
                    // Title
                    Text("Squat Configuration")
                        .font(isPhone ? .headline : .title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, isPhone ? 12 : 16)
                        .padding(.top, isPhone ? 8 : 12)
                    
                    // Femur Length Control
                    ControlGroupBox(
                        title: "Femur Length",
                        systemImage: "figure.walk",
                        iconColor: .blue,
                        isPhone: isPhone
                    ) {
                        Picker("Femur Length", selection: $viewModel.femurLength) {
                            ForEach(SquatMechanics.FemurLength.allCases, id: \.self) { length in
                                Text(length.rawValue)
                                    .tag(length)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Board Height Control
                    ControlGroupBox(
                        title: "Heel Elevation",
                        systemImage: "square.stack.3d.up",
                        iconColor: .orange,
                        isPhone: isPhone
                    ) {
                        Picker("Board Height", selection: $viewModel.boardHeight) {
                            ForEach(SquatMechanics.BoardHeight.allCases, id: \.self) { height in
                                if isPhone {
                                    // Simplified labels for iPhone
                                    Text(height == .none ? "None" : "\(Int(height.angle))°")
                                        .tag(height)
                                } else {
                                    Text(height.rawValue.replacingOccurrences(of: " (", with: "\n("))
                                        .multilineTextAlignment(.center)
                                        .tag(height)
                                }
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Squat Depth Control
                    ControlGroupBox(
                        title: "Squat Depth",
                        systemImage: "arrow.down.circle",
                        iconColor: .green,
                        isPhone: isPhone
                    ) {
                        VStack(spacing: 4) {
                            Slider(value: $viewModel.squatDepth, in: 0...1) {
                                Text("Depth")
                            } minimumValueLabel: {
                                Image(systemName: "arrow.up")
                                    .foregroundColor(.blue)
                            } maximumValueLabel: {
                                Image(systemName: "arrow.down")
                                    .foregroundColor(.blue)
                            }
                            .tint(.blue)
                            
                            // Depth percentage indicator
                            Text("\(Int(viewModel.squatDepth * 100))% depth")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    
                    // Information section
                    if !isPhone {
                        SquatInfoSection()
                    }
                }
                .padding(.bottom, isPhone ? 12 : 16)
                .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(.secondarySystemBackground))
                .cornerRadius(16)
                .padding(.horizontal, isPhone ? 12 : 16)
                
                // Information section for iPhone (below controls)
                if isPhone {
                    SquatInfoSection()
                        .padding(.horizontal, 12)
                }
            }
            .padding(.vertical, isPhone ? 12 : 16)
        }
        .navigationTitle("Squat Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
}

// Information section about squats
struct SquatInfoSection: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    private var isPhone: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About Squat Mechanics")
                .font(isPhone ? .headline : .title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                InfoRow(
                    icon: "figure.walk",
                    title: "Femur Length",
                    description: "Longer femurs typically require more forward lean to maintain balance."
                )
                
                InfoRow(
                    icon: "square.stack.3d.up",
                    title: "Heel Elevation",
                    description: "Raising the heels can help with ankle mobility and allow for a more upright torso position."
                )
                
                InfoRow(
                    icon: "arrow.down.circle",
                    title: "Squat Depth",
                    description: "Deeper squats engage more muscle groups but require greater mobility."
                )
                
                Divider()
                    .padding(.vertical, 4)
                
                // Torso Angle Legend
                Text("Torso Angle Guide")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .padding(.bottom, 4)
                
                TorsoAngleLegendRow(
                    color: .green,
                    title: "90°-80°",
                    description: "Upright posture with low strain on lower back"
                )
                
                TorsoAngleLegendRow(
                    color: .orange,
                    title: "79°-70°",
                    description: "Semi-Upright posture with Medium strain on lower back"
                )
                
                TorsoAngleLegendRow(
                    color: .red,
                    title: "Below 70°",
                    description: "To much Forward lean with high amunt of strain on lower back"
                )
            }
        }
        .padding()
        .background(colorScheme == .dark ? Color(UIColor.systemGray6) : Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// Information row component
struct InfoRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// Torso angle legend row component
struct TorsoAngleLegendRow: View {
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Color indicator
            Rectangle()
                .fill(color)
                .frame(width: 24, height: 3)
                .cornerRadius(1.5)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}

// New reusable control group box component
private struct ControlGroupBox<Content: View>: View {
    let title: String
    let systemImage: String
    let iconColor: Color
    let isPhone: Bool
    let content: Content
    
    init(
        title: String,
        systemImage: String,
        iconColor: Color = .blue,
        isPhone: Bool,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.iconColor = iconColor
        self.isPhone = isPhone
        self.content = content()
    }
    
    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: isPhone ? 6 : 8) {
                Label {
                    Text(title)
                        .font(isPhone ? .subheadline : .headline)
                        .foregroundColor(.primary)
                } icon: {
                    Image(systemName: systemImage)
                        .foregroundColor(iconColor)
                }
                
                content
            }
        }
        .padding(.horizontal, isPhone ? 12 : 16)
    }
}

// Legend item component
struct LegendItem: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 16, height: 16)
                .cornerRadius(4)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                ContentView()
            }
            .navigationViewStyle(.stack)
            .previewDevice("iPhone 14 Pro")
            .previewDisplayName("iPhone")
            
            NavigationView {
                ContentView()
            }
            .navigationViewStyle(.stack)
            .environment(\.colorScheme, .dark)
            .previewDevice("iPhone 14 Pro")
            .previewDisplayName("iPhone (Dark)")
            
            NavigationView {
                ContentView()
            }
            .navigationViewStyle(.stack)
            .previewDevice("iPad Pro (11-inch) (4th generation)")
            .previewDisplayName("iPad")
        }
    }
}
