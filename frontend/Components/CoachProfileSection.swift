import SwiftUI

struct CoachProfileSection: View {
    var body: some View {
        VStack(spacing: 24) {
            // Coach profile
            coachProfileCard
        }
    }
    
    // Coach profile section
    private var coachProfileCard: some View {
        ZStack {
            // Белый фон вместо стеклянного/серого
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
            
            VStack(spacing: 24) {
                // Avatar and name
                HStack(spacing: 16) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue, .purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Personal Coach")
                            .font(.title2.bold())
                        
                        Text("AI Self-Discovery Guide")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text("Premium Coach")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Statistics
                HStack(spacing: 24) {
                    statItem(count: "24", title: "Sessions")
                    statItem(count: "12", title: "Hours")
                    statItem(count: "98%", title: "Success")
                }
                
                // Description
                Text("I'll help you discover your true potential through personalized guidance and proven coaching techniques for personal growth and self-awareness.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
            }
            .padding(24)
        }
        .padding(.horizontal, 16)
    }
    
    // Helper statistics item
    private func statItem(count: String, title: String) -> some View {
        VStack(spacing: 4) {
            Text(count)
                .font(.title3.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// Preview
#Preview {
    ScrollView {
        CoachProfileSection()
            .padding(.vertical)
    }
} 