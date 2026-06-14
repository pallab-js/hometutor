import SwiftUI

public struct AssignmentViews: View {
    @EnvironmentObject var store: StorageManager
    @State private var showingAddAssignment = false
    @State private var statusFilter: AssignmentStatusFilter = .all
    @State private var editingAssignment: Assignment? = nil
    
    public init() {}
    
    enum AssignmentStatusFilter: String, CaseIterable, Identifiable {
        case all = "All Tasks"
        case pending = "Pending"
        case submitted = "Submitted (Needs Grading)"
        case graded = "Graded"
        
        var id: String { self.rawValue }
    }
    
    private var filteredAssignments: [Assignment] {
        switch statusFilter {
        case .all:
            return store.assignments
        case .pending:
            return store.assignments.filter { $0.status == .pending }
        case .submitted:
            return store.assignments.filter { $0.status == .submitted }
        case .graded:
            return store.assignments.filter { $0.status == .graded }
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Homework & Assignments")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("Centralized dashboard to set worksheets, check statuses, and record grades.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: { showingAddAssignment = true }) {
                    Label("Assign Homework", systemImage: "doc.badge.plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding([.top, .horizontal], 25)
            
            // Picker filter
            Picker("Status Filter", selection: $statusFilter) {
                ForEach(AssignmentStatusFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 25)
            
            // List / Table
            ScrollView {
                VStack(spacing: 12) {
                    if filteredAssignments.isEmpty {
                        Spacer()
                        VStack(spacing: 15) {
                            Image(systemName: "doc.text")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No assignments matching the selected category.")
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 50)
                        Spacer()
                    } else {
                        ForEach(filteredAssignments) { assignment in
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(assignment.title)
                                            .font(.headline)
                                        
                                        // Student badge
                                        if let student = store.students.first(where: { $0.id == assignment.studentId }) {
                                            Text(student.name)
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.purple.opacity(0.1))
                                                .foregroundColor(.purple)
                                                .cornerRadius(4)
                                        }
                                    }
                                    
                                    if !assignment.description.isEmpty {
                                        Text(assignment.description)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 15) {
                                        Text("Assigned: \(assignment.assignedDate, style: .date)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                        Text("Due: \(assignment.dueDate, style: .date)")
                                            .font(.caption2)
                                            .foregroundColor(assignment.dueDate < Date() && assignment.status != .graded ? .red : .secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                // Status Controls
                                HStack(spacing: 15) {
                                    StatusBadge(status: assignment.status)
                                    
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
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(String(format: "Grade: %.1f / %.1f", assignment.score, assignment.maxScore))
                                                .fontWeight(.bold)
                                                .foregroundColor(.green)
                                            if !assignment.notes.isEmpty {
                                                Text(assignment.notes)
                                                    .font(.system(size: 8))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                    
                                    Button(action: { editingAssignment = assignment }) {
                                        Image(systemName: "pencil")
                                            .foregroundColor(.blue)
                                    }
                                    .buttonStyle(.plain)
                                    
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
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.01), radius: 3, x: 0, y: 1)
                        }
                    }
                }
                .padding([.horizontal, .bottom], 25)
            }
        }
        .sheet(isPresented: $showingAddAssignment) {
            AddAssignmentSheet()
        }
        .sheet(item: $editingAssignment) { assignment in
            EditAssignmentSheet(assignment: assignment)
        }
    }
}

// MARK: - Status Badge Component
struct StatusBadge: View {
    let status: AssignmentStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.15))
            .foregroundColor(badgeColor)
            .cornerRadius(6)
    }
    
    private var badgeColor: Color {
        switch status {
        case .pending: return .orange
        case .submitted: return .blue
        case .graded: return .green
        }
    }
}

struct EditAssignmentSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: StorageManager
    let assignment: Assignment
    
    @State private var selectedStudentId: UUID
    @State private var title: String
    @State private var description: String
    @State private var dueDate: Date
    @State private var status: AssignmentStatus
    @State private var scoreString: String
    @State private var maxScoreString: String
    @State private var notes: String
    @State private var validationError: String? = nil
    
    init(assignment: Assignment) {
        self.assignment = assignment
        _selectedStudentId = State(initialValue: assignment.studentId)
        _title = State(initialValue: assignment.title)
        _description = State(initialValue: assignment.description)
        _dueDate = State(initialValue: assignment.dueDate)
        _status = State(initialValue: assignment.status)
        _scoreString = State(initialValue: String(assignment.score))
        _maxScoreString = State(initialValue: String(assignment.maxScore))
        _notes = State(initialValue: assignment.notes)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Assignment")
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
                
                TextField("Assignment Title", text: $title)
                TextField("Description", text: $description)
                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
                
                Picker("Status", selection: $status) {
                    ForEach(AssignmentStatus.allCases) { statusOption in
                        Text(statusOption.rawValue).tag(statusOption)
                    }
                }
                .pickerStyle(.segmented)
                
                if status == .graded {
                    TextField("Score", text: $scoreString)
                    TextField("Max Score", text: $maxScoreString)
                    TextField("Tutor Feedback", text: $notes)
                }
            }
            .formStyle(.columns)
            .padding(.horizontal)
            .frame(width: 460, height: status == .graded ? 280 : 200)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Save Changes") {
                    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedTitle.isEmpty {
                        validationError = "Assignment title is required."
                        return
                    }
                    
                    var scoreVal = Double(scoreString) ?? 0.0
                    var maxScoreVal = Double(maxScoreString) ?? 100.0
                    
                    if status == .graded {
                        guard let s = Double(scoreString), s >= 0 else {
                            validationError = "Please enter a valid positive score."
                            return
                        }
                        guard let m = Double(maxScoreString), m > 0 else {
                            validationError = "Please enter a valid positive max score."
                            return
                        }
                        scoreVal = s
                        maxScoreVal = m
                    }
                    
                    var updated = assignment
                    updated.studentId = selectedStudentId
                    updated.title = trimmedTitle
                    updated.description = description
                    updated.dueDate = dueDate
                    updated.status = status
                    updated.score = scoreVal
                    updated.maxScore = maxScoreVal
                    updated.notes = notes
                    
                    store.updateAssignment(updated)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding([.horizontal, .bottom])
        }
    }
}
