import Foundation

public enum RateType: String, Codable, CaseIterable, Identifiable, Sendable {
    case hourly = "Hourly"
    case monthly = "Monthly"
    
    public var id: String { self.rawValue }
}

public struct Student: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    public var subject: String
    public var grade: String
    public var rateType: RateType
    public var rateValue: Double
    public var contactEmail: String
    public var contactPhone: String
    public var scheduleNotes: String
    public var notes: String
    public var isActive: Bool
    public var createdAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        subject: String,
        grade: String,
        rateType: RateType,
        rateValue: Double,
        contactEmail: String = "",
        contactPhone: String = "",
        scheduleNotes: String = "",
        notes: String = "",
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.subject = subject
        self.grade = grade
        self.rateType = rateType
        self.rateValue = rateValue
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.scheduleNotes = scheduleNotes
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
    }
}

public struct Payment: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var studentId: UUID
    public var amount: Double
    public var date: Date
    public var hoursTaught: Double // 0 if monthly flat rate
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        studentId: UUID,
        amount: Double,
        date: Date = Date(),
        hoursTaught: Double = 0.0,
        notes: String = ""
    ) {
        self.id = id
        self.studentId = studentId
        self.amount = amount
        self.date = date
        self.hoursTaught = hoursTaught
        self.notes = notes
    }
}

public enum AssignmentStatus: String, Codable, CaseIterable, Identifiable, Sendable {
    case pending = "Pending"
    case submitted = "Submitted"
    case graded = "Graded"
    
    public var id: String { self.rawValue }
}

public struct Assignment: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var studentId: UUID
    public var title: String
    public var description: String
    public var assignedDate: Date
    public var dueDate: Date
    public var status: AssignmentStatus
    public var score: Double
    public var maxScore: Double
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        studentId: UUID,
        title: String,
        description: String = "",
        assignedDate: Date = Date(),
        dueDate: Date = Date().addingTimeInterval(86400 * 7), // 1 week later default
        status: AssignmentStatus = .pending,
        score: Double = 0.0,
        maxScore: Double = 100.0,
        notes: String = ""
    ) {
        self.id = id
        self.studentId = studentId
        self.title = title
        self.description = description
        self.assignedDate = assignedDate
        self.dueDate = dueDate
        self.status = status
        self.score = score
        self.maxScore = maxScore
        self.notes = notes
    }
}

public struct ProgressLog: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var studentId: UUID
    public var date: Date
    public var topicCovered: String
    public var understandingLevel: Int // 1-5 rating
    public var homeworkAssigned: String
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        studentId: UUID,
        date: Date = Date(),
        topicCovered: String,
        understandingLevel: Int = 3,
        homeworkAssigned: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.studentId = studentId
        self.date = date
        self.topicCovered = topicCovered
        self.understandingLevel = understandingLevel
        self.homeworkAssigned = homeworkAssigned
        self.notes = notes
    }
}

public struct ScheduleSession: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var studentId: UUID
    public var dayOfWeek: Int // 1 = Sunday, 2 = Monday, ..., 7 = Saturday
    public var startTime: String // Format: "HH:mm" (e.g., "16:30")
    public var endTime: String // Format: "HH:mm" (e.g., "18:00")
    public var notes: String
    
    public init(
        id: UUID = UUID(),
        studentId: UUID,
        dayOfWeek: Int,
        startTime: String,
        endTime: String,
        notes: String = ""
    ) {
        self.id = id
        self.studentId = studentId
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
    }
}

public struct AppSettings: Codable, Hashable, Sendable {
    public var currencyCode: String
    public var monthlyTargetEarnings: Double
    public var remindersEnabled: Bool
    
    public init(
        currencyCode: String = "INR",
        monthlyTargetEarnings: Double = 50000.0,
        remindersEnabled: Bool = true
    ) {
        self.currencyCode = currencyCode
        self.monthlyTargetEarnings = monthlyTargetEarnings
        self.remindersEnabled = remindersEnabled
    }
}
