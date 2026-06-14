import SwiftUI

public struct ScheduleViews: View {
    @EnvironmentObject var store: StorageManager
    @State private var showingAddSession = false
    @State private var editingSession: ScheduleSession? = nil
    
    public init() {}
    
    // Day names mapping (using standard Sunday = 1 to Saturday = 7 calendar format)
    private let weekDays = [
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday"),
        (1, "Sunday")
    ]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Schedule")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("Organize and view your weekly tutoring sessions and timing.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: { showingAddSession = true }) {
                    Label("Add Session", systemImage: "calendar.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding([.top, .horizontal], 25)
            
            // Weekly planner content
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(weekDays, id: \.0) { dayNum, dayName in
                        DayScheduleRow(dayNum: dayNum, dayName: dayName, editingSession: $editingSession)
                    }
                }
                .padding([.horizontal, .bottom], 25)
            }
        }
        .sheet(isPresented: $showingAddSession) {
            AddScheduleSessionSheet()
        }
        .sheet(item: $editingSession) { session in
            EditScheduleSessionSheet(session: session)
        }
    }
}

// MARK: - Day Schedule Row
struct DayScheduleRow: View {
    let dayNum: Int
    let dayName: String
    @Binding var editingSession: ScheduleSession?
    @EnvironmentObject var store: StorageManager
    
    private var daySessions: [(Student, ScheduleSession)] {
        let sessions = store.scheduleSessions.filter { $0.dayOfWeek == dayNum }
        var list: [(Student, ScheduleSession)] = []
        for session in sessions {
            if let student = store.students.first(where: { $0.id == session.studentId }) {
                list.append((student, session))
            }
        }
        // Sort chronologically by start time
        return list.sorted(by: { $0.1.startTime < $1.1.startTime })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(dayName)
                .font(.headline)
                .foregroundColor(.blue)
                .padding(.bottom, 2)
            
            if daySessions.isEmpty {
                Text("No tutoring sessions scheduled.")
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(daySessions, id: \.1.id) { student, session in
                        HStack(spacing: 15) {
                            // Time Slot
                            VStack(alignment: .leading) {
                                Text("\(session.startTime) - \(session.endTime)")
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                Text(student.subject)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(width: 120, alignment: .leading)
                            
                            // Student Profile Details
                            VStack(alignment: .leading, spacing: 2) {
                                Text(student.name)
                                    .fontWeight(.semibold)
                                if !session.notes.isEmpty {
                                    Text(session.notes)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Grade & Rate details
                            HStack(spacing: 10) {
                                Text(student.grade)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(6)
                                
                                Button(action: {
                                    editingSession = session
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 4)
                                
                                Button(action: {
                                    store.deleteScheduleSession(id: session.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.01), radius: 3, x: 0, y: 1)
                    }
                }
            }
        }
    }
}

// MARK: - Add Schedule Session Modal
struct AddScheduleSessionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: StorageManager
    
    @State private var selectedStudentId = UUID()
    @State private var selectedDayNum = 2 // Monday by default
    @State private var startTimeDate = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var endTimeDate = Calendar.current.date(bySettingHour: 17, minute: 30, second: 0, of: Date()) ?? Date()
    @State private var notes = ""
    @State private var validationError: String? = nil
    
    private let days = [
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday"),
        (1, "Sunday")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Schedule Tutoring Session")
                .font(.headline)
                .padding(.top)
            
            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Form {
                Picker("Student", selection: $selectedStudentId) {
                    Text("Select Student").tag(UUID())
                    ForEach(store.students) { student in
                        Text(student.name).tag(student.id)
                    }
                }
                
                Picker("Day of Week", selection: $selectedDayNum) {
                    ForEach(days, id: \.0) { num, name in
                        Text(name).tag(num)
                    }
                }
                
                DatePicker("Start Time", selection: $startTimeDate, displayedComponents: [.hourAndMinute])
                DatePicker("End Time", selection: $endTimeDate, displayedComponents: [.hourAndMinute])
                
                TextField("Notes / Topic Focus", text: $notes)
            }
            .formStyle(.columns)
            .padding(.horizontal)
            .frame(width: 420, height: 200)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Schedule Class") {
                    if selectedStudentId == UUID() {
                        validationError = "Please select a student."
                        return
                    }
                    
                    if endTimeDate <= startTimeDate {
                        validationError = "End time must be after start time."
                        return
                    }
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    
                    let startStr = formatter.string(from: startTimeDate)
                    let endStr = formatter.string(from: endTimeDate)
                    
                    let session = ScheduleSession(
                        studentId: selectedStudentId,
                        dayOfWeek: selectedDayNum,
                        startTime: startStr,
                        endTime: endStr,
                        notes: notes
                    )
                    
                    store.addScheduleSession(session)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding([.horizontal, .bottom])
        }
        .onAppear {
            if let firstStudent = store.students.first {
                selectedStudentId = firstStudent.id
            }
        }
    }
}

struct EditScheduleSessionSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: StorageManager
    let session: ScheduleSession
    
    @State private var selectedStudentId: UUID
    @State private var selectedDayNum: Int
    @State private var startTimeDate: Date
    @State private var endTimeDate: Date
    @State private var notes: String
    @State private var validationError: String? = nil
    
    private let days = [
        (2, "Monday"),
        (3, "Tuesday"),
        (4, "Wednesday"),
        (5, "Thursday"),
        (6, "Friday"),
        (7, "Saturday"),
        (1, "Sunday")
    ]
    
    init(session: ScheduleSession) {
        self.session = session
        _selectedStudentId = State(initialValue: session.studentId)
        _selectedDayNum = State(initialValue: session.dayOfWeek)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let start = formatter.date(from: session.startTime) ?? Date()
        let end = formatter.date(from: session.endTime) ?? Date()
        
        _startTimeDate = State(initialValue: start)
        _endTimeDate = State(initialValue: end)
        _notes = State(initialValue: session.notes)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Scheduled Session")
                .font(.headline)
                .padding(.top)
            
            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Form {
                Picker("Student", selection: $selectedStudentId) {
                    ForEach(store.students) { student in
                        Text(student.name).tag(student.id)
                    }
                }
                
                Picker("Day of Week", selection: $selectedDayNum) {
                    ForEach(days, id: \.0) { num, name in
                        Text(name).tag(num)
                    }
                }
                
                DatePicker("Start Time", selection: $startTimeDate, displayedComponents: [.hourAndMinute])
                DatePicker("End Time", selection: $endTimeDate, displayedComponents: [.hourAndMinute])
                
                TextField("Notes / Topic Focus", text: $notes)
            }
            .formStyle(.columns)
            .padding(.horizontal)
            .frame(width: 420, height: 200)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save Changes") {
                    if selectedStudentId == UUID() {
                        validationError = "Please select a student."
                        return
                    }
                    
                    if endTimeDate <= startTimeDate {
                        validationError = "End time must be after start time."
                        return
                    }
                    
                    let formatter = DateFormatter()
                    formatter.dateFormat = "HH:mm"
                    
                    let startStr = formatter.string(from: startTimeDate)
                    let endStr = formatter.string(from: endTimeDate)
                    
                    var updated = session
                    updated.studentId = selectedStudentId
                    updated.dayOfWeek = selectedDayNum
                    updated.startTime = startStr
                    updated.endTime = endStr
                    updated.notes = notes
                    
                    store.updateScheduleSession(updated)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding([.horizontal, .bottom])
        }
    }
}
