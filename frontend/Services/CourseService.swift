import Foundation
import SwiftUI

class CourseService: ObservableObject {
    @Published var courseUnits: [CourseUnit] = []
    @Published var courseName: String = "Personal Discovery Journey"
    
    // Calculate progress from 0.0 to 1.0
    var progress: Double {
        let totalCompleted = courseUnits.filter { $0.isCompleted }.count
        return courseUnits.isEmpty ? 0.0 : Double(totalCompleted) / Double(courseUnits.count)
    }
    
    init() {
        loadDefaultCourse()
    }
    
    // Load default course for demonstration
    private func loadDefaultCourse() {
        courseUnits = [
            CourseUnit(
                id: "1",
                title: "Self-Discovery Fundamentals",
                description: "Beginning the journey of self-discovery and core concepts",
                weekNumber: 1,
                isCompleted: true,
                isLocked: false
            ),
            CourseUnit(
                id: "2",
                title: "Wheel of Life Balance",
                description: "Analyzing key life areas and determining harmony",
                weekNumber: 2,
                isCompleted: true,
                isLocked: false
            ),
            CourseUnit(
                id: "3",
                title: "Finding Values and Motivation",
                description: "Identifying personal values and internal motivators",
                weekNumber: 3,
                isCompleted: false,
                isLocked: false
            ),
            CourseUnit(
                id: "4",
                title: "Comfort and Growth Zones",
                description: "Exploring boundaries and opportunities for personal development",
                weekNumber: 4,
                isCompleted: false,
                isLocked: true
            ),
            CourseUnit(
                id: "5",
                title: "Internal Limitations and Blocks",
                description: "Uncovering beliefs that limit your potential",
                weekNumber: 5,
                isCompleted: false,
                isLocked: true
            ),
            CourseUnit(
                id: "6",
                title: "Zones of Genius",
                description: "Discovering personal talents and unique abilities",
                weekNumber: 6,
                isCompleted: false,
                isLocked: true
            ),
            CourseUnit(
                id: "7",
                title: "Strengths and Resources",
                description: "Analyzing and activating internal resources to achieve goals",
                weekNumber: 7,
                isCompleted: false,
                isLocked: true
            ),
            CourseUnit(
                id: "8",
                title: "GROW Technique",
                description: "Systematic approach to goal setting and determining paths to achievement",
                weekNumber: 8,
                isCompleted: false,
                isLocked: true
            ),
            CourseUnit(
                id: "9",
                title: "Ikigai: Finding Purpose",
                description: "Japanese concept for finding meaning and purpose in life",
                weekNumber: 9,
                isCompleted: false,
                isLocked: true
            ),
            CourseUnit(
                id: "10",
                title: "Working with Inner Critic",
                description: "Transforming self-criticism into constructive inner dialogue",
                weekNumber: 10,
                isCompleted: false,
                isLocked: true
            ),
            CourseUnit(
                id: "11",
                title: "Mindfulness Techniques",
                description: "Awareness practices for deep connection with yourself",
                weekNumber: 11,
                isCompleted: false,
                isLocked: true
            ),
            CourseUnit(
                id: "12",
                title: "Integration and Life Plan",
                description: "Combining all insights into a complete picture and creating a development path",
                weekNumber: 12,
                isCompleted: false,
                isLocked: true
            )
        ]
    }
    
    // Update unit status
    func updateUnitStatus(id: String, isCompleted: Bool) {
        if let index = courseUnits.firstIndex(where: { $0.id == id }) {
            courseUnits[index].isCompleted = isCompleted
            
            // Unlock the next module if this one was completed
            if isCompleted {
                unlockNextUnit(currentWeek: courseUnits[index].weekNumber)
            }
        }
    }
    
    // Unlock the next module
    private func unlockNextUnit(currentWeek: Int) {
        // Find units with the next week
        let nextWeekUnits = courseUnits.filter { $0.weekNumber == currentWeek + 1 && $0.isLocked }
        
        // Unlock the first unit of the next week
        if let firstIndex = courseUnits.firstIndex(where: { $0.weekNumber == currentWeek + 1 && $0.isLocked }) {
            courseUnits[firstIndex].isLocked = false
        }
    }
} 