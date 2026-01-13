import Foundation

// MARK: - Step Model
struct Step: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var durationMinutes: Int

    init(id: UUID = UUID(), name: String, durationMinutes: Int) {
        self.id = id
        self.name = name
        self.durationMinutes = durationMinutes
    }
}

// MARK: - Routine Statistics
struct RoutineStatistics: Codable, Equatable {
    var timesSelected: Int
    var timesCompleted: Int
    var totalTimeSpentSeconds: Int

    init(timesSelected: Int = 0, timesCompleted: Int = 0, totalTimeSpentSeconds: Int = 0) {
        self.timesSelected = timesSelected
        self.timesCompleted = timesCompleted
        self.totalTimeSpentSeconds = totalTimeSpentSeconds
    }

    var averageTimeSeconds: Int {
        guard timesCompleted > 0 else { return 0 }
        return totalTimeSpentSeconds / timesCompleted
    }

    var formattedTotalTime: String {
        formatTime(totalTimeSpentSeconds)
    }

    var formattedAverageTime: String {
        formatTime(averageTimeSeconds)
    }

    private func formatTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, secs)
        } else {
            return String(format: "%ds", secs)
        }
    }
}

// MARK: - Routine Model
struct Routine: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var steps: [Step]
    var statistics: RoutineStatistics
    let createdAt: Date

    init(id: UUID = UUID(), name: String, steps: [Step] = [], statistics: RoutineStatistics = RoutineStatistics(), createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.steps = steps
        self.statistics = statistics
        self.createdAt = createdAt
    }

    var totalEstimatedMinutes: Int {
        steps.reduce(0) { $0 + $1.durationMinutes }
    }

    var formattedEstimatedTime: String {
        let hours = totalEstimatedMinutes / 60
        let minutes = totalEstimatedMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Timer Session
struct TimerSession: Codable {
    let routineId: UUID
    let startTime: Date
    var endTime: Date?
    var completedStepIds: [UUID]

    init(routineId: UUID, startTime: Date = Date()) {
        self.routineId = routineId
        self.startTime = startTime
        self.completedStepIds = []
    }

    var elapsedSeconds: Int {
        let end = endTime ?? Date()
        return Int(end.timeIntervalSince(startTime))
    }
}

// MARK: - App State
enum AppTab: String, CaseIterable {
    case today = "Today"
    case routines = "Routines"
    case statistics = "Statistics"

    var icon: String {
        switch self {
        case .today: return "house.fill"
        case .routines: return "sun.horizon.fill"
        case .statistics: return "chart.bar.fill"
        }
    }
}

// MARK: - Completion Record (for streak tracking)
struct CompletionRecord: Codable, Equatable {
    let date: Date
    let routineId: UUID
    let routineName: String
    let timeSpentSeconds: Int

    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
