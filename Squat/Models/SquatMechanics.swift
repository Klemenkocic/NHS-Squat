import SwiftUI

struct SquatMechanics {
    enum FemurLength: String, CaseIterable {
        case short = "Short"
        case long = "Long"
        
        // Femur length multiplier (long femur is 20% longer)
        var lengthMultiplier: CGFloat {
            switch self {
            case .short: return 1
            case .long: return 1.1  // 20% longer
            }
        }
    }
    
    enum BoardHeight: String, CaseIterable {
        case none = "No Board (0°)"
        case low = "Low (15°)"
        case medium = "Medium (25°)"
        case high = "High (35°)"
        
        var angle: CGFloat {
            switch self {
            case .none: return 0
            case .low: return 15
            case .medium: return 25
            case .high: return 35
            }
        }
        
        // Starting ankle angle (in new system where 90° is vertical)
        var startingAnkleAngle: CGFloat {
            switch self {
            case .none: return 90   // Vertical
            case .low: return 90   // 15° back from vertical
            case .medium: return 90 // 25° back from vertical
            case .high: return 90  // 35° back from vertical
            }
        }
    }
    
    struct JointAngles {
        var ankle: CGFloat
        var knee: CGFloat
        var hip: CGFloat
        
        static func calculateAngles(
            squatDepth: CGFloat,  // 0 to 1
            femurLength: FemurLength,
            boardHeight: BoardHeight
        ) -> JointAngles {
            // Starting angles
            let startAnkle = boardHeight.startingAnkleAngle
            let startKnee: CGFloat = 90   // Vertical
            let startHip: CGFloat = 90    // Vertical
            
            // End angles based on femur length and board height
            let (endHip, endKnee, endAnkle) = getEndAngles(femurLength: femurLength, boardHeight: boardHeight)
            
            // Calculate current angles based on squat depth
            let currentAnkle = startAnkle + (endAnkle - startAnkle) * squatDepth
            let currentKnee = startKnee + (endKnee - startKnee) * squatDepth
            let currentHip = startHip + (endHip - startHip) * squatDepth
            
            return JointAngles(
                ankle: currentAnkle,
                knee: currentKnee,
                hip: currentHip
            )
        }
        
        private static func getEndAngles(femurLength: FemurLength, boardHeight: BoardHeight) -> (hip: CGFloat, knee: CGFloat, ankle: CGFloat) {
            switch (femurLength, boardHeight) {
            // Short femur angles - more upright due to better leverages
            case (.short, .none):   return (hip: 80, knee: 185, ankle: 40)
            case (.short, .low):    return (hip: 83, knee: 188, ankle: 36)
            case (.short, .medium): return (hip: 86, knee: 190, ankle: 33)
            case (.short, .high):   return (hip: 88, knee: 192, ankle: 30)
            
            // Long femur angles - more forward lean required due to leverages
            case (.long, .none):    return (hip: 65, knee: 175, ankle: 50)
            case (.long, .low):     return (hip: 75, knee: 178, ankle: 40)
            case (.long, .medium):  return (hip: 80, knee: 180, ankle: 30)
            case (.long, .high):    return (hip: 85, knee: 183, ankle: 20)
            }
        }
    }
}

// Preview
struct SquatMechanics_Previews: PreviewProvider {
    static var previews: some View {
        StickFigureView(viewModel: SquatAnalysisViewModel())
            .frame(height: 400)
            .previewLayout()
    }
}
