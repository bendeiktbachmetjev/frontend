import SwiftUI

struct CourseUnit {
    let id: String
    let title: String
    let description: String
    let weekNumber: Int
    var isCompleted: Bool
    var isLocked: Bool
}

struct CourseStructureSection: View {
    let courseName: String
    let progress: Double // From 0.0 to 1.0
    let units: [CourseUnit]
    let topics: [String] // <-- добавлен новый параметр
    let goal: String // <-- новый параметр
    let onboardingManager: OnboardingManager // Новый проп
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
     
            // Course card
            courseCard
            
            // Course progress
            progressSection
            
            // My goal section (теперь внутри)
            MyGoalSection(goal: goal)
            
            // List of course units
            unitsList
        }
    }
    
    // Course card
    private var courseCard: some View {
        ZStack {
            // Белый фон вместо стеклянного/серого
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            
            VStack(alignment: .leading, spacing: 16) {
                // Title
                Text(courseName)
                    .font(.title.bold())
                    .foregroundColor(.primary)
                
                // Progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(progress * 100))%")
                            .font(.subheadline.bold())
                            .foregroundColor(.blue)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Progress bar background
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            // Filled part
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.blue, .purple]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(progress), height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                
                // Info
                HStack(spacing: 24) {
                    infoItem(count: "\(units.count)", title: "Units")
                    infoItem(count: "\(units.filter { $0.isCompleted }.count)", title: "Completed")
                    infoItem(count: "\(units.filter { !$0.isLocked && !$0.isCompleted }.count)", title: "Available")
                }
            }
            .padding(24)
        }
        .padding(.horizontal, 16)
    }
    
    // Progress section
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Progress")
                .font(.title2.bold())
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(1...12, id: \.self) { week in
                        let hasUnit = units.contains { $0.weekNumber == week }
                        let completed = units.filter { $0.weekNumber == week && $0.isCompleted }.count
                        let total = units.filter { $0.weekNumber == week }.count
                        let topic = topics.indices.contains(week-1) ? topics[week-1] : "No topic"
                        WeekProgressCard(
                            weekNumber: week,
                            hasContent: hasUnit,
                            completed: completed,
                            total: total,
                            topic: topic // <-- передаём тему
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
    }
    
    // List of units
    private var unitsList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Course Units")
                .font(.title2.bold())
                .padding(.horizontal, 16)
            
            ForEach(units.sorted(by: { $0.weekNumber < $1.weekNumber }), id: \.id) { unit in
                let topic = topics.indices.contains(unit.weekNumber - 1) ? topics[unit.weekNumber - 1] : unit.title
                // Блокируем 2 и 3 неделю
                let isLocked = unit.weekNumber == 2 || unit.weekNumber == 3 ? true : unit.isLocked
                CourseUnitCard(
                    unit: CourseUnit(
                        id: unit.id,
                        title: unit.title,
                        description: unit.description,
                        weekNumber: unit.weekNumber,
                        isCompleted: unit.isCompleted,
                        isLocked: isLocked
                    ),
                    topic: topic,
                    onboardingManager: onboardingManager
                )
            }
            .padding(.horizontal, 16)
        }
    }
    
    // Helper statistics item
    private func infoItem(count: String, title: String) -> some View {
        VStack(spacing: 4) {
            Text(count)
                .font(.title3.bold())
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
        )
    }
}

// Week progress card
struct WeekProgressCard: View {
    let weekNumber: Int
    let hasContent: Bool
    let completed: Int
    let total: Int
    let topic: String // <-- оставляем для совместимости, но не отображаем
    
    var body: some View {
        VStack(spacing: 8) {
            Text("Week \(weekNumber)")
                .font(.subheadline.bold())
                .foregroundColor(weekNumber == 1 ? .blue : .gray)
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                if weekNumber == 1 {
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [.blue, .purple]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .fill(Color.yellow)
                        .frame(width: 14, height: 14)
                } else {
                    // Серый кружок для остальных недель
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 44, height: 44)
                }
            }
        }
        .frame(width: 90)
    }
}

// Course unit card
struct CourseUnitCard: View {
    let unit: CourseUnit
    let topic: String
    var onboardingManager: OnboardingManager? = nil
    @State private var showChatView = false
    
    var body: some View {
        Button(action: {
            showChatView = true
        }) {
            HStack(alignment: .center, spacing: 16) {
                // Status indicator
                ZStack {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 40, height: 40)
                    if unit.weekNumber == 2 || unit.weekNumber == 3 {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white)
                    } else if unit.isCompleted {
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                    } else if unit.isLocked {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.white)
                    } else {
                        Text("\(unit.weekNumber)")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                
                // Unit info
                VStack(alignment: .leading, spacing: 6) {
                    Text(topic)
                        .font(.headline)
                        .foregroundColor(unit.isLocked ? .gray : .primary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .multilineTextAlignment(.leading)
                    // Описание больше не отображаем
                }
                .padding(.vertical, 2)
                
                Spacer()
                
                // Arrow icon
                if !unit.isLocked {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.systemGray6)) // Явно серый фон для контраста на белом экране
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
        }
        .disabled(unit.isLocked)
        .fullScreenCover(isPresented: $showChatView) {
            NavigationView {
                if let manager = onboardingManager {
                    WeekChatView(unitTitle: topic, onboardingManager: manager)
                } else {
                    Text("Chat is available only for the first week.")
                        .font(.title)
                        .foregroundColor(.gray)
                        .padding()
                }
            }
        }
    }
    
    private var statusColor: Color {
        if unit.weekNumber == 2 || unit.weekNumber == 3 {
            return .gray
        } else if unit.isCompleted {
            return .green
        } else if unit.isLocked {
            return .gray
        } else {
            return .blue
        }
    }
}

#Preview {
    let authService = AuthService()
    ScrollView {
        CourseStructureSection(
            courseName: "Public Speaking Mastery",
            progress: 0.45,
            units: [
                CourseUnit(
                    id: "1",
                    title: "Introduction to Public Speaking",
                    description: "Learn the basics of effective public speaking",
                    weekNumber: 1,
                    isCompleted: true,
                    isLocked: false
                ),
                CourseUnit(
                    id: "2",
                    title: "Voice Projection Techniques",
                    description: "Master techniques to project your voice clearly",
                    weekNumber: 2,
                    isCompleted: true,
                    isLocked: false
                ),
                CourseUnit(
                    id: "3",
                    title: "Eliminating Filler Words",
                    description: "Strategies to reduce um, uh, like in your speech",
                    weekNumber: 3,
                    isCompleted: false,
                    isLocked: false
                ),
                CourseUnit(
                    id: "4",
                    title: "Persuasive Speaking",
                    description: "Learn to speak persuasively in any situation",
                    weekNumber: 4,
                    isCompleted: false,
                    isLocked: true
                ),
                CourseUnit(
                    id: "5",
                    title: "Self-Discovery Fundamentals",
                    description: "Use storytelling to enhance your presentations",
                    weekNumber: 5,
                    isCompleted: false,
                    isLocked: false
                )
            ],
            topics: [
                "Introduction to Public Speaking",
                "Voice Projection Techniques",
                "Eliminating Filler Words",
                "Persuasive Speaking",
                "Self-Discovery Fundamentals"
            ],
            goal: "Master public speaking skills and become a confident communicator.",
            onboardingManager: OnboardingManager(authService: authService)
        )
        .padding(.vertical)
    }
    .background(Color(UIColor.systemGroupedBackground))
} 
