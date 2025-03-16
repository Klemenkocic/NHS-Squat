import SwiftUI
import Combine

@MainActor
final class SquatAnalysisViewModel: ObservableObject {
    @Published var femurLength: SquatMechanics.FemurLength = .short
    @Published var boardHeight: SquatMechanics.BoardHeight = .none
    @Published var squatDepth: CGFloat = 0  // 0 to 1
    
    var jointAngles: SquatMechanics.JointAngles {
        SquatMechanics.JointAngles.calculateAngles(
            squatDepth: squatDepth,
            femurLength: femurLength,
            boardHeight: boardHeight
        )
    }
}

extension SquatAnalysisViewModel: SquatViewModel { } 
