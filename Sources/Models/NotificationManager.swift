import Foundation
import UserNotifications

@MainActor
public class NotificationManager {
    public static let shared = NotificationManager()
    
    private init() {}
    
    public func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("❌ Notification authorization error: \(error)")
            } else {
                print("🔔 Notification authorization granted: \(granted)")
            }
        }
    }
    
    public func syncSessionNotifications(students: [Student], scheduleSessions: [ScheduleSession], enabled: Bool) {
        let center = UNUserNotificationCenter.current()
        
        // Remove all pending notifications first to rebuild the schedule cleanly
        center.removeAllPendingNotificationRequests()
        
        guard enabled else {
            print("🔔 Reminders are disabled in Settings. Cleared all alerts.")
            return
        }
        
        for session in scheduleSessions {
            guard let student = students.first(where: { $0.id == session.studentId }), student.isActive else { continue }
            
            // Parse "HH:mm"
            let timeParts = session.startTime.split(separator: ":")
            guard timeParts.count == 2,
                  let hour = Int(timeParts[0]),
                  let minute = Int(timeParts[1]) else { continue }
            
            // Subtract 15 minutes
            var triggerHour = hour
            var triggerMinute = minute - 15
            
            if triggerMinute < 0 {
                triggerMinute += 60
                triggerHour -= 1
                if triggerHour < 0 {
                    triggerHour = 23
                }
            }
            
            // Set up calendar components trigger (weekday is 1-7, matching our dayOfWeek!)
            var components = DateComponents()
            components.weekday = session.dayOfWeek
            components.hour = triggerHour
            components.minute = triggerMinute
            
            let content = UNMutableNotificationContent()
            content.title = "Upcoming Session: \(student.name)"
            content.body = "\(student.subject) class starts in 15 minutes at \(session.startTime)."
            content.sound = .default
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "session_\(session.id.uuidString)", content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("❌ Failed to add notification for \(student.name): \(error.localizedDescription)")
                }
            }
        }
        print("🔔 Synchronized weekly reminders for \(scheduleSessions.count) schedule sessions.")
    }
}
