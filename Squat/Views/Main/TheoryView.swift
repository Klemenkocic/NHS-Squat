import SwiftUI
import UIKit

struct TheoryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedCategory: SquatCategory = .basics
    @State private var showingArticle: SquatArticle? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with app icon and title
                HStack {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.blue)
                    
                    Text("NHS Squat Guide")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Featured article card
                featuredArticleCard
                .padding(.horizontal)
                
                // Category selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(SquatCategory.allCases) { category in
                            CategoryButton(
                                title: category.title,
                                systemImage: category.icon,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Articles for selected category
                articlesForCategory(selectedCategory)
                    .padding(.horizontal)
                
                // Tips section
                tipsSection
                    .padding(.horizontal)
                
                // Resources section
                resourcesSection
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
        .navigationTitle("Squat Theory")
        .background(Color(.systemGroupedBackground))
        .sheet(item: $showingArticle) { article in
            ArticleDetailView(article: article)
        }
    }
    
    private var featuredArticleCard: some View {
        Button(action: {
            showingArticle = SquatArticle.featured
        }) {
            ZStack(alignment: .bottomLeading) {
                // Use a gradient background with icon
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [.blue.opacity(0.7), .blue.opacity(0.5)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(height: 200)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.clear, .black.opacity(0.7)]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("MUST READ")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    
                    Text("The 5 Absolutes of Squatting")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Master the fundamentals for perfect form")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(16)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func articlesForCategory(_ category: SquatCategory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(category.title)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.top, 8)
            
            ForEach(category.articles) { article in
                ArticleCard(article: article) {
                    showingArticle = article
                }
            }
        }
    }
    
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Tips")
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                ForEach(SquatTip.tips) { tip in
                    TipCard(tip: tip)
                }
            }
        }
    }
    
    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resources")
                .font(.title3)
                .fontWeight(.bold)
            
            HStack(spacing: 12) {
                ResourceCard(
                    title: "NHS Website",
                    description: "Visit our official website",
                    systemImage: "globe",
                    color: .blue
                )
                
                ResourceCard(
                    title: "Video Tutorials",
                    description: "Watch technique guides",
                    systemImage: "play.rectangle.fill",
                    color: .red
                )
            }
        }
    }
}

// MARK: - Helper Views

struct CategoryButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : (colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground)))
                    .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), radius: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorScheme == .dark && !isSelected ? Color(.systemGray5) : Color.clear, lineWidth: 1)
            )
        }
    }
}

struct ArticleCard: View {
    let article: SquatArticle
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: article.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.blue)
                    .frame(width: 50, height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.1))
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(article.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                    .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), radius: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorScheme == .dark ? Color(.systemGray5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TipCard: View {
    let tip: SquatTip
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tip.icon)
                .font(.system(size: 18))
                .foregroundColor(.orange)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tip.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(tip.description)
                    .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), radius: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color(.systemGray5) : Color.clear, lineWidth: 1)
        )
    }
}

struct ResourceCard: View {
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 24))
                .foregroundColor(color)
            
                Text(title)
                    .font(.headline)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
                .shadow(color: colorScheme == .dark ? .clear : .black.opacity(0.1), radius: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colorScheme == .dark ? Color(.systemGray5) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Article Detail View

struct ArticleDetailView: View {
    let article: SquatArticle
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Article header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(article.title)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(article.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Article content
                    ForEach(article.contentSections, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            if !section.title.isEmpty {
                                Text(section.title)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            
                            Text(section.content)
                                .font(.body)
                                .foregroundColor(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    
                    // Related articles
                    if !article.relatedArticles.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Related Topics")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ForEach(article.relatedArticles) { relatedArticle in
                                HStack {
                                    Text(relatedArticle.title)
                                        .font(.subheadline)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.right")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                    .padding()
                    .background(
                                    RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 2)
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

// MARK: - Data Models

enum SquatCategory: String, CaseIterable, Identifiable {
    case basics
    case technique
    case variations
    case mobility
    case mistakes
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .basics: return "Basics"
        case .technique: return "Technique"
        case .variations: return "Variations"
        case .mobility: return "Mobility"
        case .mistakes: return "Common Mistakes"
        }
    }
    
    var icon: String {
        switch self {
        case .basics: return "1.circle.fill"
        case .technique: return "figure.walk"
        case .variations: return "square.stack.3d.up.fill"
        case .mobility: return "figure.walk.motion"
        case .mistakes: return "exclamationmark.triangle.fill"
        }
    }
    
    var articles: [SquatArticle] {
        switch self {
        case .basics:
            return [
                SquatArticle(
                    id: "basics_setup",
                    title: "Squat Setup",
                    subtitle: "Proper positioning before you begin",
                    icon: "figure.stand",
                    contentSections: [
                        ContentSection(
                            title: "Foot Position",
                            content: "• Feet shoulder-width apart\n• Toes pointed slightly out (5-7°)\n• Weight distributed evenly across the 'tripod foot'"
                        ),
                        ContentSection(
                            title: "Upper Body",
                            content: "• Chest up and proud\n• Core braced\n• Neutral spine position\n• Eyes focused straight ahead"
                        )
                    ]
                ),
                SquatArticle(
                    id: "basics_movement",
                    title: "Movement Pattern",
                    subtitle: "The fundamental squat motion",
                    icon: "arrow.down.circle",
                    contentSections: [
                        ContentSection(
                            title: "The Descent",
                            content: "Start with a Kee cave by moving your knees forward and outwards while maintaining a neutral spine. Keep your knees tracking over your toes as you descend. Maintain balance with your weight distributed evenly across your feet."
                        ),
                        ContentSection(
                            title: "The Bottom Position",
                            content: "At the bottom of the squat, your weight should be evenly distributed between the front and back of your foot. Your depth should be determined by your mobility and goals."
                        ),
                        ContentSection(
                            title: "The Ascent",
                            content: "Drive through your heels and midfoot, pushing your hips forward and up. Keep your chest up and maintain tension throughout your body with an emphasis on your Quadriceps muscles."
                        )
                    ]
                )
            ]
        case .technique:
            return [
                SquatArticle(
                    id: "technique_cues",
                    title: "Essential Cues",
                    subtitle: "Mental cues for perfect form",
                    icon: "brain",
                    contentSections: [
                        ContentSection(
                            title: "External Rotation Torque",
                            content: "Create tension at the hips by 'screwing your feet into the ground' or imagining you're trying to spread the floor apart. This engages the external rotators and helps maintain proper knee alignment."
                        ),
                        ContentSection(
                            title: "Bracing",
                            content: "Take a deep breath into your belly and brace your core as if you're about to be punched in the stomach. This creates intra-abdominal pressure that stabilizes your spine."
                        ),
                        ContentSection(
                            title: "Hip Drive",
                            content: "Think about driving your hips forward and up when ascending from the bottom position. This properly engages your posterior chain and creates power."
                        )
                    ]
                ),
                SquatArticle(
                    id: "technique_breathing",
                    title: "Breathing Technique",
                    subtitle: "Proper breathing for stability and power",
                    icon: "lungs",
                    contentSections: [
                        ContentSection(
                            title: "The Valsalva Maneuver",
                            content: "Take a deep breath into your belly before descending. Hold this breath throughout the descent and initial drive out of the bottom position. This creates intra-abdominal pressure that stabilizes your spine."
                        ),
                        ContentSection(
                            title: "When to Exhale",
                            content: "Exhale slowly through pursed lips as you pass the sticking point during the ascent. Never exhale at the bottom of the squat, as this reduces core stability when you need it most."
                        )
                    ]
                )
            ]
        case .variations:
            return [
                SquatArticle(
                    id: "variations_highbar",
                    title: "High-Bar Back Squat",
                    subtitle: "Olympic weightlifting style",
                    icon: "figure.strengthtraining.traditional",
                    contentSections: [
                        ContentSection(
                            title: "Bar Position",
                            content: "The bar rests on the trapezius muscles at the top of the shoulders. This creates a more upright torso position compared to low-bar."
                        ),
                        ContentSection(
                            title: "Benefits",
                            content: "• Greater quadriceps development\n• More upright posture\n• Better carryover to Olympic lifts\n• Often allows for greater depth"
                        ),
                        ContentSection(
                            title: "Technique Considerations",
                            content: "Requires good ankle mobility to maintain an upright torso. Knees will travel further forward over the toes compared to low-bar."
                        )
                    ]
                ),
                SquatArticle(
                    id: "variations_lowbar",
                    title: "Low-Bar Back Squat",
                    subtitle: "Powerlifting style",
                    icon: "figure.strengthtraining.traditional",
                    contentSections: [
                        ContentSection(
                            title: "Bar Position",
                            content: "The bar rests across the posterior deltoids and middle trapezius, below the spine of the scapula. This creates a more horizontal back angle."
                        ),
                        ContentSection(
                            title: "Benefits",
                            content: "• Allows for heavier loads\n• Greater posterior chain engagement\n• Shorter range of motion\n• Preferred by powerlifters"
                        ),
                        ContentSection(
                            title: "Technique Considerations",
                            content: "Requires good shoulder mobility and a more pronounced hip hinge. The torso will be more inclined forward compared to high-bar."
                        )
                    ]
                ),
                SquatArticle(
                    id: "variations_front",
                    title: "Front Squat",
                    subtitle: "Anterior loading variation",
                    icon: "figure.strengthtraining.functional",
                    contentSections: [
                        ContentSection(
                            title: "Bar Position",
                            content: "The bar rests on the front of the shoulders, either in a clean grip position (fingers under the bar) or with arms crossed."
                        ),
                        ContentSection(
                            title: "Benefits",
                            content: "• Greatest quadriceps development\n• Most upright torso position\n• Reduced spinal loading\n• Excellent core strengthening"
                        ),
                        ContentSection(
                            title: "Technique Considerations",
                            content: "Requires excellent thoracic mobility and wrist flexibility. The elbows must stay high throughout the movement to prevent the bar from rolling forward."
                        )
                    ]
                )
            ]
        case .mobility:
            return [
                SquatArticle(
                    id: "mobility_ankle",
                    title: "Ankle Mobility",
                    subtitle: "Essential for proper depth",
                    icon: "figure.walk",
                    contentSections: [
                        ContentSection(
                            title: "Importance",
                            content: "Limited ankle dorsiflexion is one of the most common restrictions preventing proper squat depth. Without adequate ankle mobility, you may compensate by lifting your heels, leaning too far forward, or experiencing knee pain."
                        ),
                        ContentSection(
                            title: "Assessment",
                            content: "Kneel with one knee on the ground and the other foot flat. Try to push your knee forward over your toes without lifting your heel. Your knee should be able to track 6cm to 10cm past your toes."
                        ),
                        ContentSection(
                            title: "Exercises",
                            content: "• Banded ankle mobilizations\n• Weighted ankle stretches\n• Foam rolling the calves\n• Wall ankle mobilizations"
                        )
                    ]
                ),
                SquatArticle(
                    id: "mobility_hip",
                    title: "Hip Mobility",
                    subtitle: "For depth and proper alignment",
                    icon: "figure.walk.motion",
                    contentSections: [
                        ContentSection(
                            title: "Importance",
                            content: "Hip mobility is crucial for achieving proper depth while maintaining a neutral spine. Limited hip mobility can lead to butt wink, knee valgus, or excessive forward lean."
                        ),
                        ContentSection(
                            title: "Key Areas",
                            content: "• Hip flexors\n• Adductors\n• External rotators\n• Hamstrings"
                        ),
                        ContentSection(
                            title: "Exercises",
                            content: "• 90/90 stretches\n• Pigeon pose\n• Frog stretch\n• Banded hip rotations\n• Deep squat holds"
                        )
                    ]
                )
            ]
        case .mistakes:
            return [
                SquatArticle(
                    id: "mistakes_knees",
                    title: "Knee Valgus",
                    subtitle: "Knees caving inward",
                    icon: "exclamationmark.circle",
                    contentSections: [
                        ContentSection(
                            title: "The Problem",
                            content: "Knee valgus (knees caving inward) during the squat places excessive stress on the knee ligaments and can lead to injury. It also reduces power output and efficiency."
                        ),
                        ContentSection(
                            title: "Causes",
                            content: "• Weak glute medius and external rotators\n• Poor motor control\n• Tight adductors\n• Flat feet or poor foot positioning"
                        ),
                        ContentSection(
                            title: "Solutions",
                            content: "• Strengthen glutes with band walks and clamshells\n• Practice 'screwing the feet into the ground'\n• Use a resistance band around the knees as a reminder\n• Temporarily reduce load and focus on form"
                        )
                    ]
                ),
                SquatArticle(
                    id: "mistakes_buttwink",
                    title: "Butt Wink",
                    subtitle: "Posterior pelvic tilt at depth",
                    icon: "exclamationmark.circle",
                    contentSections: [
                        ContentSection(
                            title: "The Problem",
                            content: "Butt wink refers to the posterior tilting of the pelvis at the bottom of a squat, causing the lower back to round. This can place stress on the lumbar spine and potentially lead to injury."
                        ),
                        ContentSection(
                            title: "Causes",
                            content: "• Limited hip mobility\n• Poor core stability\n• Attempting to squat too deep for current mobility\n• Anatomical limitations"
                        ),
                        ContentSection(
                            title: "Solutions",
                            content: "• Improve hip mobility with targeted stretches\n• Strengthen core stability\n• Temporarily limit depth to where form can be maintained\n• Consider stance width adjustments"
                        )
                    ]
                ),
                SquatArticle(
                    id: "mistakes_forward_lean",
                    title: "Excessive Forward Lean",
                    subtitle: "Torso angle too horizontal",
                    icon: "exclamationmark.circle",
                    contentSections: [
                        ContentSection(
                            title: "The Problem",
                            content: "While some forward lean is normal (especially in low-bar squats), excessive forward lean can place undue stress on the lower back and reduce squat efficiency."
                        ),
                        ContentSection(
                            title: "Causes",
                            content: "• Limited ankle mobility\n• Weak core or upper back\n• Poor bar positioning\n• Improper breathing technique"
                        ),
                        ContentSection(
                            title: "Solutions",
                            content: "• Improve ankle mobility\n• Strengthen core and upper back muscles\n• Check bar position\n• Practice proper bracing technique\n• Consider heel-elevated shoes or small plates under heels temporarily"
                        )
                    ]
                )
            ]
        }
    }
}

struct SquatArticle: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let contentSections: [ContentSection]
    var relatedArticles: [SquatArticle] = []
    
    static var featured: SquatArticle {
        SquatArticle(
            id: "featured_absolutes",
            title: "The 5 Absolutes of Squatting",
            subtitle: "Master the fundamentals for perfect form",
            icon: "star.fill",
            contentSections: [
                ContentSection(
                    title: "Introduction",
                    content: "The squat is a fundamental human movement pattern that we all should be able to perform correctly. Before adding weight, it's essential to master these five absolutes of the bodyweight squat."
                ),
                ContentSection(
                    title: "1. Toe Angle",
                    content: "For the bodyweight squat, a near straight-forward foot position with a slight 5-7° out-toe angle is ideal. This position allows for optimal force transfer and carries over to athletic movements."
                ),
                ContentSection(
                    title: "2. The Tripod Foot",
                    content: "Distribute your weight evenly across three points: the heel, the base of the 1st toe, and the base of the 5th toe. This creates a stable base and maintains proper arch support."
                ),
                ContentSection(
                    title: "3. Hip Hinge",
                    content: "Every squat must start with a hip-hinge. By driving your hips backward and bringing the chest forward in a hinging movement, you properly engage the posterior chain (glutes and hamstrings)."
                ),
                ContentSection(
                    title: "4. External Rotation Torque",
                    content: "Create tension at the hips by 'screwing your feet into the ground' or imagining you're trying to spread the floor apart. This engages the external rotators and helps maintain proper knee alignment."
                ),
                ContentSection(
                    title: "5. Neutral Spine",
                    content: "Maintain a neutral spine position throughout the entire movement. This means no excessive arching or rounding of the back, which protects your spine and allows for optimal force transfer."
                )
            ]
        )
    }
}

struct ContentSection {
    let title: String
    let content: String
}

struct SquatTip: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    
    static let tips: [SquatTip] = [
        SquatTip(
            title: "Warm Up Properly",
            description: "Always perform dynamic stretches and mobility work before squatting to prepare your joints and muscles.",
            icon: "flame.fill"
        ),
        SquatTip(
            title: "Eyes Forward",
            description: "Keep your gaze fixed on a point directly in front of you to help maintain a neutral spine position.",
            icon: "eye.fill"
        ),
        SquatTip(
            title: "Start Light",
            description: "Master form with bodyweight or light loads before progressing to heavier weights.",
            icon: "arrow.up.right"
        )
    ]
}

// Preview
struct TheoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            TheoryView()
        }
    }
}
