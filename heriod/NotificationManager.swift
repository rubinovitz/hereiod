import UserNotifications
import Foundation

// MARK: - Notification Manager

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    // MARK: - Permission Handling
    
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func checkPermissionStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    // MARK: - Period Prediction Notifications
    
    func schedulePeriodPredictionNotification(for predictedDate: Date) {
        Task {
            let status = await checkPermissionStatus()
            guard status == .authorized else {
                print("Notifications not authorized")
                return
            }
            
            // Clear existing period prediction notifications
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["period-prediction-2day", "period-prediction-1day"])
            
            // Schedule notification 2 days before
            scheduleNotification(
                id: "period-prediction-2day",
                title: "Period Coming Soon",
                body: "Your period is predicted to start in 2 days",
                triggerDate: Calendar.current.date(byAdding: .day, value: -2, to: predictedDate)
            )
            
            // Schedule notification 1 day before
            scheduleNotification(
                id: "period-prediction-1day",
                title: "Period Tomorrow",
                body: "Your period is predicted to start tomorrow. Time to prepare!",
                triggerDate: Calendar.current.date(byAdding: .day, value: -1, to: predictedDate)
            )
        }
    }
    
    private func scheduleNotification(id: String, title: String, body: String, triggerDate: Date?) {
        guard let triggerDate = triggerDate,
              triggerDate > Date() else {
            print("Invalid trigger date for notification \(id)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "PERIOD_PREDICTION"
        
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification \(id): \(error)")
            } else {
                print("Scheduled notification \(id) for \(triggerDate)")
            }
        }
    }
    
    // MARK: - Update Notifications
    
    func updatePredictionNotifications(for periods: [Period]) {
        guard let predictedDate = PeriodCalculations.nextPredictedPeriod(from: periods) else {
            print("No predicted date available")
            return
        }
        
        schedulePeriodPredictionNotification(for: predictedDate)
    }
    
    // MARK: - Clear Notifications
    
    func clearAllPredictionNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "period-prediction-2day",
            "period-prediction-1day"
        ])
    }
}