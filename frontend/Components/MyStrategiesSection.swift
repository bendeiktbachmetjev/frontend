import SwiftUI

struct MyGoalSection: View {
    let goal: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Goal")
                .font(.title2.bold())
                .padding(.horizontal, 16)
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "target")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.blue)
                Text(goal.isEmpty || goal == "Find your goal" ? "Find your goal" : goal)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(goal.isEmpty || goal == "Find your goal" ? .secondary : .primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
            )
            .padding(.horizontal, 8)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 32) {
        MyGoalSection(goal: "Become a senior developer at a top tech company.")
        MyGoalSection(goal: "")
    }
    .background(Color(UIColor.systemGroupedBackground))
} 
