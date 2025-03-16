import SwiftUI

@preconcurrency protocol SquatViewModel: ObservableObject {
    var jointAngles: SquatMechanics.JointAngles { get }
    var femurLength: SquatMechanics.FemurLength { get }
    var boardHeight: SquatMechanics.BoardHeight { get }
    var squatDepth: CGFloat { get }
} 