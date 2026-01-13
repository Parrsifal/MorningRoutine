import Foundation
import SwiftUI
import Combine

// MARK: - UserDefaults Keys
private enum StorageKeys {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let routines = "routines"
    static let activeSession = "activeSession"
    static let completionRecords = "completionRecords"
}

// MARK: - LocalStorage
@MainActor
class LocalStorage: ObservableObject {

    // MARK: - Published Properties
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: StorageKeys.hasCompletedOnboarding)
        }
    }

    @Published var routines: [Routine] {
        didSet {
            saveRoutines()
        }
    }

    @Published var activeSession: TimerSession? {
        didSet {
            saveActiveSession()
        }
    }

    @Published var completionRecords: [CompletionRecord] {
        didSet {
            saveCompletionRecords()
        }
    }

    @Published var selectedTab: AppTab = .today

    // MARK: - Computed Properties
    var totalStatistics: (selected: Int, completed: Int, timeSpent: Int) {
        let selected = routines.reduce(0) { $0 + $1.statistics.timesSelected }
        let completed = routines.reduce(0) { $0 + $1.statistics.timesCompleted }
        let timeSpent = routines.reduce(0) { $0 + $1.statistics.totalTimeSpentSeconds }
        return (selected, completed, timeSpent)
    }

    var currentStreak: Int {
        calculateStreak()
    }

    var completedToday: Bool {
        let todayString = dateString(for: Date())
        return completionRecords.contains { $0.dateString == todayString }
    }

    var todayCompletions: [CompletionRecord] {
        let todayString = dateString(for: Date())
        return completionRecords.filter { $0.dateString == todayString }
    }

    var thisWeekCompletions: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) ?? Date()
        return completionRecords.filter { $0.date >= startOfWeek }.count
    }

    // MARK: - Initialization
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: StorageKeys.hasCompletedOnboarding)
        self.routines = []
        self.activeSession = nil
        self.completionRecords = []

        loadRoutines()
        loadActiveSession()
        loadCompletionRecords()
    }

    // MARK: - Routines CRUD

    func createRoutine(name: String, steps: [Step]) {
        let routine = Routine(name: name, steps: steps)
        routines.append(routine)
    }

    func updateRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[index] = routine
        }
    }

    func deleteRoutine(id: UUID) {
        routines.removeAll { $0.id == id }
    }

    func getRoutine(by id: UUID) -> Routine? {
        routines.first { $0.id == id }
    }

    // MARK: - Timer Session

    func startSession(for routineId: UUID) {
        activeSession = TimerSession(routineId: routineId)

        // Increment times selected
        if let index = routines.firstIndex(where: { $0.id == routineId }) {
            routines[index].statistics.timesSelected += 1
        }
    }

    func completeSession(completedStepIds: [UUID]) {
        guard var session = activeSession,
              let index = routines.firstIndex(where: { $0.id == session.routineId }) else {
            activeSession = nil
            return
        }

        session.endTime = Date()
        session.completedStepIds = completedStepIds

        let routine = routines[index]

        // Update statistics
        routines[index].statistics.timesCompleted += 1
        routines[index].statistics.totalTimeSpentSeconds += session.elapsedSeconds

        // Add completion record
        let record = CompletionRecord(
            date: Date(),
            routineId: routine.id,
            routineName: routine.name,
            timeSpentSeconds: session.elapsedSeconds
        )
        completionRecords.append(record)

        activeSession = nil
    }

    func cancelSession() {
        activeSession = nil
    }

    // MARK: - Data Reset

    func resetAllData() {
        routines = []
        activeSession = nil
        completionRecords = []
        hasCompletedOnboarding = false
    }

    func resetStatistics() {
        for index in routines.indices {
            routines[index].statistics = RoutineStatistics()
        }
        completionRecords = []
    }

    // MARK: - Streak Calculation

    private func calculateStreak() -> Int {
        guard !completionRecords.isEmpty else { return 0 }

        let calendar = Calendar.current
        var uniqueDates = Set<String>()

        for record in completionRecords {
            uniqueDates.insert(record.dateString)
        }

        let sortedDates = uniqueDates.sorted().reversed()
        var streak = 0
        var expectedDate = calendar.startOfDay(for: Date())

        // Check if completed today
        let todayString = dateString(for: expectedDate)
        if !uniqueDates.contains(todayString) {
            // If not completed today, start from yesterday
            expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
        }

        for dateStr in sortedDates {
            let expectedDateString = dateString(for: expectedDate)

            if dateStr == expectedDateString {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate) ?? expectedDate
            } else if dateStr < expectedDateString {
                break
            }
        }

        return streak
    }

    private func dateString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    // MARK: - Private Methods

    private func saveRoutines() {
        if let encoded = try? JSONEncoder().encode(routines) {
            UserDefaults.standard.set(encoded, forKey: StorageKeys.routines)
        }
    }

    private func loadRoutines() {
        if let data = UserDefaults.standard.data(forKey: StorageKeys.routines),
           let decoded = try? JSONDecoder().decode([Routine].self, from: data) {
            routines = decoded
        }
    }

    private func saveActiveSession() {
        if let session = activeSession,
           let encoded = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(encoded, forKey: StorageKeys.activeSession)
        } else {
            UserDefaults.standard.removeObject(forKey: StorageKeys.activeSession)
        }
    }

    private func loadActiveSession() {
        if let data = UserDefaults.standard.data(forKey: StorageKeys.activeSession),
           let decoded = try? JSONDecoder().decode(TimerSession.self, from: data) {
            activeSession = decoded
        }
    }

    private func saveCompletionRecords() {
        if let encoded = try? JSONEncoder().encode(completionRecords) {
            UserDefaults.standard.set(encoded, forKey: StorageKeys.completionRecords)
        }
    }

    private func loadCompletionRecords() {
        if let data = UserDefaults.standard.data(forKey: StorageKeys.completionRecords),
           let decoded = try? JSONDecoder().decode([CompletionRecord].self, from: data) {
            completionRecords = decoded
        }
    }
}
