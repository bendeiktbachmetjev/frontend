import SwiftUI

struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "house.fill",
                title: "Dashboard",
                isSelected: selectedTab == 0,
                action: { withAnimation(.easeInOut) { selectedTab = 0 } }
            )
            
            TabBarButton(
                icon: "person.fill",
                title: "MyCoach",
                isSelected: selectedTab == 1,
                action: { withAnimation(.easeInOut) { selectedTab = 1 } }
            )
            
            TabBarButton(
                icon: "gear",
                title: "Settings",
                isSelected: selectedTab == 2,
                action: { withAnimation(.easeInOut) { selectedTab = 2 } }
            )
        }
        .frame(height: 60)
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(30)
        .shadow(radius: 5)
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .blue : .gray)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
    }
} 
