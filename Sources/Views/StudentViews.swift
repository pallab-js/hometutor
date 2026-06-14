import SwiftUI

public struct StudentListView: View {
    @EnvironmentObject var store: StorageManager
    @State private var searchText = ""
    @Binding private var selectedStudentId: UUID?
    @State private var showingAddStudent = false
    
    public init(selectedStudentId: Binding<UUID?>) {
        self._selectedStudentId = selectedStudentId
    }
    
    private var filteredStudents: [Student] {
        if searchText.isEmpty {
            return store.students
        } else {
            return store.students.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.subject.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    public var body: some View {
        NavigationSplitView {
            // Sidebar List of Students
            List(selection: $selectedStudentId) {
                let activeFiltered = filteredStudents.filter { $0.isActive }
                let archivedFiltered = filteredStudents.filter { !$0.isActive }
                
                if !activeFiltered.isEmpty {
                    Section("Active Students") {
                        ForEach(activeFiltered) { student in
                            NavigationLink(value: student.id) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(student.name)
                                            .font(.headline)
                                        Text(student.subject)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(student.grade)
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(4)
                                }
                            }
                            .tag(student.id)
                        }
                    }
                }
                
                if !archivedFiltered.isEmpty {
                    Section("Archived Students") {
                        ForEach(archivedFiltered) { student in
                            NavigationLink(value: student.id) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(student.name)
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                        Text(student.subject)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text(student.grade)
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.secondary.opacity(0.1))
                                            .foregroundColor(.secondary)
                                            .cornerRadius(4)
                                        
                                        Text("Inactive")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            .tag(student.id)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search students...")
            .navigationTitle("Students")
            .toolbar {
                ToolbarItem {
                    Button(action: { showingAddStudent = true }) {
                        Label("Add Student", systemImage: "person.badge.plus")
                    }
                }
            }
        } detail: {
            if let studentId = selectedStudentId, let student = store.students.first(where: { $0.id == studentId }) {
                StudentDetailView(student: student)
            } else {
                VStack(spacing: 15) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select a student to view their academic profile")
                        .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showingAddStudent) {
            AddStudentSheet()
        }
    }
}

// MARK: - Student Detail View
struct StudentDetailView: View {
    let student: Student
    @EnvironmentObject var store: StorageManager
    @State private var activeTab = 0
    @State private var showingEditProfile = false
    @State private var showingAddLog = false
    @State private var showingAddAssignment = false
    
    // Calculated Student-specific Metrics
    private var studentPayments: [Payment] {
        store.payments.filter { $0.studentId == student.id }
    }
    
    private var totalBilled: Double {
        studentPayments.reduce(0) { $0 + $1.amount }
    }
    
    private var studentAssignments: [Assignment] {
        store.assignments.filter { $0.studentId == student.id }
    }
    
    private var studentLogs: [ProgressLog] {
        store.progressLogs.filter { $0.studentId == student.id }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Student Profile Header
            HStack(spacing: 20) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(student.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text(student.isActive ? "Active" : "Inactive")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(student.isActive ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                            .foregroundColor(student.isActive ? .green : .red)
                            .cornerRadius(6)
                    }
                    
                    Text("\(student.subject)  •  \(student.grade)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingEditProfile = true }) {
                    Label("Edit Profile", systemImage: "pencil")
                }
            }
            .padding(25)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Tabs
            Picker("", selection: $activeTab) {
                Text("Overview").tag(0)
                Text("Progress Logs").tag(1)
                Text("Assignments").tag(2)
                Text("Billing & Payments").tag(3)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 25)
            .padding(.bottom, 10)
            
            // Tab Content
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch activeTab {
                    case 0:
                        OverviewTab(student: student, totalBilled: totalBilled, totalHours: studentPayments.reduce(0) { $0 + $1.hoursTaught })
                    case 1:
                        ProgressLogsTab(student: student, logs: studentLogs, showingAddLog: $showingAddLog)
                    case 2:
                        AssignmentsTab(student: student, assignments: studentAssignments, showingAddAssignment: $showingAddAssignment)
                    case 3:
                        BillingTab(student: student, payments: studentPayments)
                    default:
                        EmptyView()
                    }
                }
                .padding(25)
            }
        }
        .sheet(isPresented: $showingEditProfile) {
            EditStudentSheet(student: student)
        }
        .sheet(isPresented: $showingAddLog) {
            AddProgressLogSheet(student: student)
        }
        .sheet(isPresented: $showingAddAssignment) {
            AddAssignmentSheetForStudent(student: student)
        }
    }
}

// MARK: - Tab 0: Overview
struct OverviewTab: View {
    let student: Student
    let totalBilled: Double
    let totalHours: Double
    @EnvironmentObject var store: StorageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 20) {
                // Info Card 1: Rate
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate Structure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(student.rateType == .hourly ? "\(store.formatCurrency(student.rateValue)) / Hour" : "\(store.formatCurrency(student.rateValue)) / Month")
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                
                // Info Card 2: Cumulative Hours/Amount
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Revenue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(store.formatCurrency(totalBilled))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
                
                // Info Card 3: Total Hours
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f Hrs", totalHours))
                        .font(.title3)
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 15) {
                Text("Contact & Schedule Information")
                    .font(.headline)
                
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 10) {
                    GridRow {
                        Text("Email:")
                            .fontWeight(.semibold)
                        if student.contactEmail.isEmpty {
                            Text("Not provided").italic().foregroundColor(.secondary)
                        } else {
                            Text(student.contactEmail)
                        }
                    }
                    
                    GridRow {
                        Text("Phone:")
                            .fontWeight(.semibold)
                        if student.contactPhone.isEmpty {
                            Text("Not provided").italic().foregroundColor(.secondary)
                        } else {
                            Text(student.contactPhone)
                        }
                    }
                    
                    GridRow {
                        Text("Schedule Time:")
                            .fontWeight(.semibold)
                        if student.scheduleNotes.isEmpty {
                            Text("No schedule specified").italic().foregroundColor(.secondary)
                        } else {
                            Text(student.scheduleNotes)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Tutor Focus & Student Notes")
                    .font(.headline)
                
                Text(student.notes.isEmpty ? "No notes added yet." : student.notes)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
            }
        }
    }
}

// MARK: - Tab 1: Progress Logs
struct ProgressLogsTab: View {
    let student: Student
    let logs: [ProgressLog]
    @Binding var showingAddLog: Bool
    @EnvironmentObject var store: StorageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Progress Timeline")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddLog = true }) {
                    Label("Log Session", systemImage: "clock.badge.checkmark")
                }
            }
            
            if logs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No sessions logged for this student yet.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(logs) { log in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(log.date, style: .date)
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                // Star Rating
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { star in
                                        Image(systemName: star <= log.understandingLevel ? "star.fill" : "star")
                                            .foregroundColor(.yellow)
                                            .font(.caption)
                                    }
                                }
                                
                                Button(action: {
                                    store.deleteProgressLog(id: log.id)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Text("Topic: \(log.topicCovered)")
                                .fontWeight(.semibold)
                            
                            if !log.notes.isEmpty {
                                Text(log.notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !log.homeworkAssigned.isEmpty {
                                HStack(alignment: .top) {
                                    Image(systemName: "book.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                    Text("Homework: \(log.homeworkAssigned)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

// MARK: - Tab 2: Assignments
struct AssignmentsTab: View {
    let student: Student
    let assignments: [Assignment]
    @Binding var showingAddAssignment: Bool
    @EnvironmentObject var store: StorageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Assignments")
                    .font(.headline)
                Spacer()
                Button(action: { showingAddAssignment = true }) {
                    Label("Assign Homework", systemImage: "doc.badge.plus")
                }
            }
            
            if assignments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No homework assignments recorded.")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(assignments) { assignment in
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(assignment.title)
                                    .font(.headline)
                                
                                if !assignment.description.isEmpty {
                                    Text(assignment.description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Text("Due: \(assignment.dueDate, style: .date)")
                                    .font(.caption)
                                    .foregroundColor(assignment.dueDate < Date() && assignment.status != .graded ? .red : .secondary)
                            }
                            
                            Spacer()
                            
                            // Status & Grade Actions
                            HStack(spacing: 15) {
                                switch assignment.status {
                                case .pending:
                                    Button("Mark Submitted") {
                                        var updated = assignment
                                        updated.status = .submitted
                                        store.updateAssignment(updated)
                                    }
                                    .buttonStyle(.bordered)
                                case .submitted:
                                    GradeAssignmentMenu(assignment: assignment)
                                case .graded:
                                    VStack(alignment: .trailing) {
                                        Text(String(format: "Grade: %.1f / %.1f", assignment.score, assignment.maxScore))
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                        if !assignment.notes.isEmpty {
                                            Text(assignment.notes)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Button(action: { store.deleteAssignment(id: assignment.id) }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
}

// Sub-component to grade assignment
struct GradeAssignmentMenu: View {
    let assignment: Assignment
    @EnvironmentObject var store: StorageManager
    @State private var score = ""
    @State private var showingPopover = false
    
    var body: some View {
        Button("Grade") {
            showingPopover = true
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
        .popover(isPresented: $showingPopover) {
            VStack(spacing: 12) {
                Text("Enter Score")
                    .font(.headline)
                
                HStack {
                    TextField("Score", text: $score)
                        .frame(width: 60)
                    Text("/ \(Int(assignment.maxScore))")
                }
                
                Button("Submit Grade") {
                    if let scoreVal = Double(score) {
                        var updated = assignment
                        updated.status = .graded
                        updated.score = scoreVal
                        store.updateAssignment(updated)
                        showingPopover = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(Double(score) == nil)
            }
            .padding()
        }
    }
}

// MARK: - Tab 3: Billing & Payments
struct BillingTab: View {
    let student: Student
    let payments: [Payment]
    @EnvironmentObject var store: StorageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Payment History")
                .font(.headline)
            
            if payments.isEmpty {
                Text("No payments logged for this student.")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                Table(payments) {
                    TableColumn("Date") { payment in
                        Text(payment.date, style: .date)
                    }
                    TableColumn("Hours Taught") { payment in
                        Text(payment.hoursTaught > 0 ? String(format: "%.1f Hrs", payment.hoursTaught) : "--")
                    }
                    TableColumn("Amount") { payment in
                        Text(store.formatCurrency(payment.amount))
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    TableColumn("Notes") { payment in
                        Text(payment.notes.isEmpty ? "--" : payment.notes)
                    }
                    TableColumn("Actions") { payment in
                        Button(action: { store.deletePayment(id: payment.id) }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(height: 250)
            }
        }
    }
}

// MARK: - Modals & Editors
struct EditStudentSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: StorageManager
    let student: Student
    
    @State private var name: String
    @State private var subject: String
    @State private var grade: String
    @State private var rateType: RateType
    @State private var rateValueString: String
    @State private var email: String
    @State private var phone: String
    @State private var scheduleNotes: String
    @State private var notes: String
    @State private var isActive: Bool
    @State private var validationError: String? = nil
    
    init(student: Student) {
        self.student = student
        _name = State(initialValue: student.name)
        _subject = State(initialValue: student.subject)
        _grade = State(initialValue: student.grade)
        _rateType = State(initialValue: student.rateType)
        _rateValueString = State(initialValue: String(student.rateValue))
        _email = State(initialValue: student.contactEmail)
        _phone = State(initialValue: student.contactPhone)
        _scheduleNotes = State(initialValue: student.scheduleNotes)
        _notes = State(initialValue: student.notes)
        _isActive = State(initialValue: student.isActive)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Student Profile")
                .font(.headline)
                .padding(.top)
            
            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Form {
                TextField("Student Name", text: $name)
                TextField("Subject", text: $subject)
                TextField("Grade / Class", text: $grade)
                Toggle("Enrolled & Active", isOn: $isActive)
                
                Picker("Rate Type", selection: $rateType) {
                    ForEach(RateType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                
                TextField("Rate (\(store.settings.currencyCode))", text: $rateValueString)
                TextField("Email", text: $email)
                TextField("Phone", text: $phone)
                TextField("Schedule Time", text: $scheduleNotes)
                TextField("Focus Notes", text: $notes)
            }
            .formStyle(.grouped)
            .frame(width: 450, height: 350)
            
            HStack {
                Button("Delete Student", role: .destructive) {
                    store.deleteStudent(id: student.id)
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Save Changes") {
                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedName.isEmpty {
                        validationError = "Student name is required."
                        return
                    }
                    guard let rateVal = Double(rateValueString), rateVal >= 0 else {
                        validationError = "Please enter a valid billing rate (positive number)."
                        return
                    }
                    
                    var updated = student
                    updated.name = trimmedName
                    updated.subject = subject
                    updated.grade = grade
                    updated.isActive = isActive
                    updated.rateType = rateType
                    updated.rateValue = rateVal
                    updated.contactEmail = email
                    updated.contactPhone = phone
                    updated.scheduleNotes = scheduleNotes
                    updated.notes = notes
                    
                    store.updateStudent(updated)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding([.horizontal, .bottom])
        }
    }
}

struct AddProgressLogSheet: View {
    let student: Student
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: StorageManager
    
    @State private var topicCovered = ""
    @State private var understandingLevel = 3
    @State private var homework = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var validationError: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Log Student Session")
                .font(.headline)
                .padding(.top)
            
            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Form {
                DatePicker("Session Date", selection: $date, displayedComponents: [.date])
                TextField("Topic Covered", text: $topicCovered)
                
                Picker("Understanding", selection: $understandingLevel) {
                    Text("1 - Struggling").tag(1)
                    Text("2 - Basic").tag(2)
                    Text("3 - Satisfactory").tag(3)
                    Text("4 - Good").tag(4)
                    Text("5 - Excellent").tag(5)
                }
                
                TextField("Homework Assigned", text: $homework)
                TextField("Session notes", text: $notes)
            }
            .formStyle(.grouped)
            .frame(width: 400, height: 220)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Log Session") {
                    let trimmedTopic = topicCovered.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedTopic.isEmpty {
                        validationError = "Topic covered is required."
                        return
                    }
                    let log = ProgressLog(studentId: student.id, date: date, topicCovered: trimmedTopic, understandingLevel: understandingLevel, homeworkAssigned: homework, notes: notes)
                    store.addProgressLog(log)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding([.horizontal, .bottom])
        }
    }
}

struct AddAssignmentSheetForStudent: View {
    let student: Student
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: StorageManager
    
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date().addingTimeInterval(86400 * 7)
    @State private var validationError: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Assign Homework to \(student.name)")
                .font(.headline)
                .padding(.top)
            
            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Form {
                TextField("Assignment Title", text: $title)
                TextField("Description (Optional)", text: $description)
                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
            }
            .formStyle(.grouped)
            .frame(width: 400, height: 160)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Button("Assign") {
                    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedTitle.isEmpty {
                        validationError = "Assignment title is required."
                        return
                    }
                    let assignment = Assignment(studentId: student.id, title: trimmedTitle, description: description, dueDate: dueDate)
                    store.addAssignment(assignment)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding([.horizontal, .bottom])
        }
    }
}
