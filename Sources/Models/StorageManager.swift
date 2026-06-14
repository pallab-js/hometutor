import Foundation
import Combine

@MainActor
public class StorageManager: ObservableObject {
    public static let shared = StorageManager()
    
    @Published public var students: [Student] = []
    @Published public var payments: [Payment] = []
    @Published public var assignments: [Assignment] = []
    @Published public var progressLogs: [ProgressLog] = []
    @Published public var scheduleSessions: [ScheduleSession] = []
    
    private let fileManager = FileManager.default
    private var baseDirectory: URL
    
    private init() {
        // Find Application Support Directory
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        baseDirectory = appSupport.appendingPathComponent("HomeTutor", isDirectory: true)
        
        // Ensure directory exists
        try? fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true, attributes: nil)
        
        loadAllData()
        
        // If empty, populate with rich sample data to show analytics immediately
        if students.isEmpty {
            loadSampleData()
        }
    }
    
    // MARK: - File Paths
    private var studentsURL: URL { baseDirectory.appendingPathComponent("students.json") }
    private var paymentsURL: URL { baseDirectory.appendingPathComponent("payments.json") }
    private var assignmentsURL: URL { baseDirectory.appendingPathComponent("assignments.json") }
    private var progressURL: URL { baseDirectory.appendingPathComponent("progress.json") }
    private var scheduleURL: URL { baseDirectory.appendingPathComponent("schedule.json") }
    
    // MARK: - Save/Load Implementation
    private func loadAllData() {
        students = loadJSON(from: studentsURL) ?? []
        payments = loadJSON(from: paymentsURL) ?? []
        assignments = loadJSON(from: assignmentsURL) ?? []
        progressLogs = loadJSON(from: progressURL) ?? []
        scheduleSessions = loadJSON(from: scheduleURL) ?? []
    }
    
    private func saveJSON<T: Encodable>(_ data: T, to url: URL) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let encodedData = try encoder.encode(data)
            try encodedData.write(to: url, options: .atomic)
        } catch {
            print("❌ Error saving to \(url.lastPathComponent): \(error)")
        }
    }
    
    private func loadJSON<T: Decodable>(from url: URL) -> T? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Error loading from \(url.lastPathComponent): \(error)")
            return nil
        }
    }
    
    public func saveAllData() {
        saveJSON(students, to: studentsURL)
        saveJSON(payments, to: paymentsURL)
        saveJSON(assignments, to: assignmentsURL)
        saveJSON(progressLogs, to: progressURL)
        saveJSON(scheduleSessions, to: scheduleURL)
    }
    
    // MARK: - Student Operations
    public func addStudent(_ student: Student) {
        students.append(student)
        saveAllData()
    }
    
    public func updateStudent(_ student: Student) {
        if let index = students.firstIndex(where: { $0.id == student.id }) {
            students[index] = student
            saveAllData()
        }
    }
    
    public func deleteStudent(id: UUID) {
        students.removeAll { $0.id == id }
        payments.removeAll { $0.studentId == id }
        assignments.removeAll { $0.studentId == id }
        progressLogs.removeAll { $0.studentId == id }
        scheduleSessions.removeAll { $0.studentId == id }
        saveAllData()
    }
    
    // MARK: - Payment Operations
    public func addPayment(_ payment: Payment) {
        payments.append(payment)
        // Re-sort payments chronologically
        payments.sort(by: { $0.date > $1.date })
        saveAllData()
    }
    
    public func updatePayment(_ payment: Payment) {
        if let index = payments.firstIndex(where: { $0.id == payment.id }) {
            payments[index] = payment
            payments.sort(by: { $0.date > $1.date })
            saveAllData()
        }
    }
    
    public func deletePayment(id: UUID) {
        payments.removeAll { $0.id == id }
        saveAllData()
    }
    
    // MARK: - Assignment Operations
    public func addAssignment(_ assignment: Assignment) {
        assignments.append(assignment)
        assignments.sort(by: { $0.dueDate < $1.dueDate })
        saveAllData()
    }
    
    public func updateAssignment(_ assignment: Assignment) {
        if let index = assignments.firstIndex(where: { $0.id == assignment.id }) {
            assignments[index] = assignment
            assignments.sort(by: { $0.dueDate < $1.dueDate })
            saveAllData()
        }
    }
    
    public func deleteAssignment(id: UUID) {
        assignments.removeAll { $0.id == id }
        saveAllData()
    }
    
    // MARK: - Progress Log Operations
    public func addProgressLog(_ log: ProgressLog) {
        progressLogs.append(log)
        progressLogs.sort(by: { $0.date > $1.date })
        saveAllData()
    }
    
    public func updateProgressLog(_ log: ProgressLog) {
        if let index = progressLogs.firstIndex(where: { $0.id == log.id }) {
            progressLogs[index] = log
            progressLogs.sort(by: { $0.date > $1.date })
            saveAllData()
        }
    }
    
    public func deleteProgressLog(id: UUID) {
        progressLogs.removeAll { $0.id == id }
        saveAllData()
    }
    
    // MARK: - Schedule Operations
    public func addScheduleSession(_ session: ScheduleSession) {
        scheduleSessions.append(session)
        saveAllData()
    }
    
    public func updateScheduleSession(_ session: ScheduleSession) {
        if let index = scheduleSessions.firstIndex(where: { $0.id == session.id }) {
            scheduleSessions[index] = session
            saveAllData()
        }
    }
    
    public func deleteScheduleSession(id: UUID) {
        scheduleSessions.removeAll { $0.id == id }
        saveAllData()
    }
    
    // MARK: - Database Actions
    public func clearAllData() {
        students.removeAll()
        payments.removeAll()
        assignments.removeAll()
        progressLogs.removeAll()
        scheduleSessions.removeAll()
        saveAllData()
    }
    
    public func resetToSampleData() {
        clearAllData()
        loadSampleData()
    }
    
    public func exportToCSV() -> String? {
        guard !payments.isEmpty else { return nil }
        
        var csvString = "Date,Student Name,Amount ($),Hours Taught,Notes\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        for payment in payments {
            let studentName = students.first(where: { $0.id == payment.studentId })?.name ?? "Unknown Student"
            let dateStr = formatter.string(from: payment.date)
            let escapedNotes = payment.notes.replacingOccurrences(of: "\"", with: "\"\"")
            
            csvString += "\(dateStr),\"\(studentName)\",\(payment.amount),\(payment.hoursTaught),\"\(escapedNotes)\"\n"
        }
        
        return csvString
    }
    
    // MARK: - Populate Sample Data
    private func loadSampleData() {
        let calendar = Calendar.current
        let today = Date()
        
        // 1. Create Students
        let s1 = Student(name: "Alexander Mercer", subject: "Advanced Physics", grade: "12th Grade", rateType: .hourly, rateValue: 50.0, contactEmail: "alex@mercer.family", contactPhone: "+1 (555) 123-4567", scheduleNotes: "Mondays & Wednesdays 4:00 PM - 5:30 PM", notes: "Prefers conceptual explanations. Working towards AP Physics exams.")
        let s2 = Student(name: "Sophia Martinez", subject: "Calculus BC", grade: "11th Grade", rateType: .hourly, rateValue: 45.0, contactEmail: "martinez.sophia@gmail.com", contactPhone: "+1 (555) 987-6543", scheduleNotes: "Tuesdays & Thursdays 5:00 PM - 6:30 PM", notes: "Very methodical but needs confidence boost with integration methods.")
        let s3 = Student(name: "Daniel Chen", subject: "AP Computer Science A", grade: "10th Grade", rateType: .monthly, rateValue: 350.0, contactEmail: "dchen@student.io", contactPhone: "+1 (555) 345-6789", scheduleNotes: "Saturdays 10:00 AM - 12:00 PM", notes: "Enthusiastic coder. Covering Java OOP concepts, recursion, and search algorithms.")
        let s4 = Student(name: "Emily Watson", subject: "Algebra 2", grade: "9th Grade", rateType: .hourly, rateValue: 40.0, contactEmail: "ewatson@outlook.com", contactPhone: "+1 (555) 456-7890", scheduleNotes: "Fridays 3:30 PM - 5:00 PM", notes: "Needs focus on quadratic equations and factoring.")
        
        students = [s1, s2, s3, s4]
        
        // 2. Create Schedule Sessions
        // Day numbers: 1 = Sun, 2 = Mon, 3 = Tue, 4 = Wed, 5 = Thu, 6 = Fri, 7 = Sat
        scheduleSessions = [
            ScheduleSession(studentId: s1.id, dayOfWeek: 2, startTime: "16:00", endTime: "17:30", notes: "Physics Theory & Problems"),
            ScheduleSession(studentId: s1.id, dayOfWeek: 4, startTime: "16:00", endTime: "17:30", notes: "Physics Lab Review"),
            ScheduleSession(studentId: s2.id, dayOfWeek: 3, startTime: "17:00", endTime: "18:30", notes: "Calc Derivatives"),
            ScheduleSession(studentId: s2.id, dayOfWeek: 5, startTime: "17:00", endTime: "18:30", notes: "Calc Integration"),
            ScheduleSession(studentId: s3.id, dayOfWeek: 7, startTime: "10:00", endTime: "12:00", notes: "Java Programming"),
            ScheduleSession(studentId: s4.id, dayOfWeek: 6, startTime: "15:30", endTime: "17:00", notes: "Algebra drills")
        ]
        
        // 3. Create Progress Logs
        progressLogs = [
            ProgressLog(studentId: s1.id, date: calendar.date(byAdding: .day, value: -6, to: today)!, topicCovered: "Electromagnetism - Maxwell's Equations", understandingLevel: 4, homeworkAssigned: "Solve worksheets 4 and 5", notes: "Alex understood Gauss's Law quickly. Struggled slightly with Faraday's Law math but got it by the end of the session."),
            ProgressLog(studentId: s1.id, date: calendar.date(byAdding: .day, value: -13, to: today)!, topicCovered: "Special Relativity - Time Dilation", understandingLevel: 5, homeworkAssigned: "Read chapter 15, solve odd-numbered problems", notes: "Incredible engagement! He loves relativity concepts. Discussed muons and twin paradox."),
            ProgressLog(studentId: s2.id, date: calendar.date(byAdding: .day, value: -5, to: today)!, topicCovered: "Calculus - Integration by Parts", understandingLevel: 3, homeworkAssigned: "Page 234: Problems 1 to 20", notes: "Sophia needs more drill on selecting 'u' and 'dv'. Will review LIATE rule next session."),
            ProgressLog(studentId: s2.id, date: calendar.date(byAdding: .day, value: -12, to: today)!, topicCovered: "Calculus - Substitution Method", understandingLevel: 4, homeworkAssigned: "Practice problems sheet B", notes: "Comfortable with U-substitution. Ready to move to integration by parts."),
            ProgressLog(studentId: s3.id, date: calendar.date(byAdding: .day, value: -1, to: today)!, topicCovered: "OOP - Inheritance and Polymorphism", understandingLevel: 5, homeworkAssigned: "Build a mini hierarchy for library database", notes: "Daniel grasped method overriding vs overloading effortlessly. Programmed a working prototype in class."),
            ProgressLog(studentId: s4.id, date: calendar.date(byAdding: .day, value: -2, to: today)!, topicCovered: "Algebra - Quadratic Formula", understandingLevel: 2, homeworkAssigned: "Solve 15 quadratic equations using formula", notes: "Emily gets confused with negative coefficients under the square root. Needs more manual math exercises.")
        ]
        
        // 4. Create Assignments
        assignments = [
            Assignment(studentId: s1.id, title: "Electrodynamics Worksheet", description: "Solve the 5 problems on circuits and induction.", assignedDate: calendar.date(byAdding: .day, value: -6, to: today)!, dueDate: calendar.date(byAdding: .day, value: 1, to: today)!, status: .pending),
            Assignment(studentId: s2.id, title: "Integration Drill 4", description: "20 integrals involving trigonometric substitution.", assignedDate: calendar.date(byAdding: .day, value: -5, to: today)!, dueDate: calendar.date(byAdding: .day, value: -1, to: today)!, status: .submitted),
            Assignment(studentId: s3.id, title: "Abstract Class Lab", description: "Implement Vehicle hierarchy with startEngine abstract methods.", assignedDate: calendar.date(byAdding: .day, value: -8, to: today)!, dueDate: calendar.date(byAdding: .day, value: -2, to: today)!, status: .graded, score: 95.0, maxScore: 100.0, notes: "Excellent OOP code, clean variable names, well-documented."),
            Assignment(studentId: s4.id, title: "Factoring Binomials Review", description: "Factor the given expressions.", assignedDate: calendar.date(byAdding: .day, value: -2, to: today)!, dueDate: calendar.date(byAdding: .day, value: 5, to: today)!, status: .pending)
        ]
        
        // 5. Create Payments (spanning March, April, May, June 2026)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        payments = [
            // June 2026 Payments
            Payment(studentId: s3.id, amount: 350.0, date: calendar.date(byAdding: .day, value: -10, to: today)!, notes: "Monthly payment for June"),
            Payment(studentId: s1.id, amount: 150.0, date: calendar.date(byAdding: .day, value: -4, to: today)!, hoursTaught: 3.0, notes: "Sessions on June 8 and June 10"),
            Payment(studentId: s2.id, amount: 135.0, date: calendar.date(byAdding: .day, value: -3, to: today)!, hoursTaught: 3.0, notes: "Sessions on June 9 and June 11"),
            Payment(studentId: s4.id, amount: 80.0, date: calendar.date(byAdding: .day, value: -2, to: today)!, hoursTaught: 2.0, notes: "Session on June 12"),
            
            // May 2026 Payments
            Payment(studentId: s3.id, amount: 350.0, date: formatter.date(from: "2026-05-01")!, notes: "Monthly payment for May"),
            Payment(studentId: s1.id, amount: 300.0, date: formatter.date(from: "2026-05-28")!, hoursTaught: 6.0, notes: "May sessions"),
            Payment(studentId: s2.id, amount: 270.0, date: formatter.date(from: "2026-05-29")!, hoursTaught: 6.0, notes: "May sessions"),
            Payment(studentId: s4.id, amount: 160.0, date: formatter.date(from: "2026-05-30")!, hoursTaught: 4.0, notes: "May sessions"),
            
            // April 2026 Payments
            Payment(studentId: s3.id, amount: 350.0, date: formatter.date(from: "2026-04-02")!, notes: "Monthly payment for April"),
            Payment(studentId: s1.id, amount: 400.0, date: formatter.date(from: "2026-04-29")!, hoursTaught: 8.0, notes: "April sessions"),
            Payment(studentId: s2.id, amount: 360.0, date: formatter.date(from: "2026-04-30")!, hoursTaught: 8.0, notes: "April sessions"),
            
            // March 2026 Payments
            Payment(studentId: s3.id, amount: 350.0, date: formatter.date(from: "2026-03-01")!, notes: "Monthly payment for March"),
            Payment(studentId: s1.id, amount: 250.0, date: formatter.date(from: "2026-03-28")!, hoursTaught: 5.0, notes: "March sessions")
        ]
        
        saveAllData()
    }
}
