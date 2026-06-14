import SwiftUI
import Charts

struct DashboardView: View {
    @EnvironmentObject var store: StorageManager
    let onNavigateToStudent: (UUID) -> Void
    
    @State private var showingAddPaymentSheet = false
    @State private var showingAddStudentSheet = false
    @State private var showingAddAssignmentSheet = false
    
    // Helpers to calculate metrics
    private var totalEarnings: Double {
        store.payments.reduce(0) { $0 + $1.amount }
    }
    
    private var earningsThisMonth: Double {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        return store.payments.filter { payment in
            let month = calendar.component(.month, from: payment.date)
            let year = calendar.component(.year, from: payment.date)
            return month == currentMonth && year == currentYear
        }.reduce(0) { $0 + $1.amount }
    }
    
    private var activeStudentsCount: Int {
        store.students.filter { $0.isActive }.count
    }
    
    private var totalHoursTaught: Double {
        store.payments.reduce(0) { $0 + $1.hoursTaught }
    }
    
    private var pendingAssignmentsCount: Int {
        store.assignments.filter { $0.status == .pending }.count
    }
    
    // Monthly Earnings Chart Data Structure
    struct MonthlyEarnings: Identifiable {
        let id = UUID()
        let monthName: String
        let date: Date
        let amount: Double
    }
    
    private var monthlyEarningsData: [MonthlyEarnings] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.payments) { (payment) -> Date in
            let components = calendar.dateComponents([.year, .month], from: payment.date)
            return calendar.date(from: components) ?? Date()
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yy"
        
        return grouped.map { (key, payments) in
            let total = payments.reduce(0) { $0 + $1.amount }
            return MonthlyEarnings(monthName: formatter.string(from: key), date: key, amount: total)
        }.sorted(by: { $0.date < $1.date })
    }
    
    // Student Breakdown Chart Data
    struct StudentEarnings: Identifiable {
        let id = UUID()
        let name: String
        let amount: Double
    }
    
    private var studentEarningsData: [StudentEarnings] {
        let grouped = Dictionary(grouping: store.payments) { $0.studentId }
        return grouped.map { (studentId, payments) in
            let name = store.students.first(where: { $0.id == studentId })?.name ?? "Unknown"
            let total = payments.reduce(0) { $0 + $1.amount }
            return StudentEarnings(name: name, amount: total)
        }.sorted(by: { $0.amount > $1.amount })
    }
    
    // Today's schedule sessions
    private var todaysSchedule: [(Student, ScheduleSession)] {
        let calendar = Calendar.current
        let todayDayOfWeek = calendar.component(.weekday, from: Date()) // 1 = Sun, 2 = Mon ... 7 = Sat
        
        let sessions = store.scheduleSessions.filter { $0.dayOfWeek == todayDayOfWeek }
        var result: [(Student, ScheduleSession)] = []
        
        for session in sessions {
            if let student = store.students.first(where: { $0.id == session.studentId }) {
                result.append((student, session))
            }
        }
        
        // Sort by start time
        return result.sorted(by: { $0.1.startTime < $1.1.startTime })
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Track your earnings, student schedules, and academic milestones.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Quick Action Menu
                    Menu {
                        Button(action: { showingAddPaymentSheet = true }) {
                            Label("Log Payment", systemImage: "indianrupeesign.circle")
                        }
                        Button(action: { showingAddStudentSheet = true }) {
                            Label("Add Student", systemImage: "person.badge.plus")
                        }
                        Button(action: { showingAddAssignmentSheet = true }) {
                            Label("Assign Homework", systemImage: "doc.badge.plus")
                        }
                    } label: {
                        Label("Quick Actions", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .foregroundColor(.white)
                            .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .cornerRadius(10)
                    }
                    .menuStyle(.borderlessButton)
                }
                .padding(.bottom, 5)
                
                // KPI Row
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    MetricCard(title: "Active Students", value: "\(activeStudentsCount)", subtitle: "Currently enrolled", icon: "person.2.fill", color: .purple)
                    MetricCard(title: "Monthly Revenue", value: store.formatCurrency(earningsThisMonth), subtitle: "Current month earnings", icon: "indianrupeesign.circle.fill", color: .green)
                    MetricCard(title: "Cumulative Revenue", value: store.formatCurrency(totalEarnings), subtitle: "Life-time earnings", icon: "banknote.fill", color: .blue)
                    MetricCard(title: "Pending Tasks", value: "\(pendingAssignmentsCount)", subtitle: "Assignments to review", icon: "doc.text.fill", color: .orange)
                }
                
                // Target Progress and Projections Row
                HStack(spacing: 20) {
                    // Progress Gauge
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Monthly Target Progress")
                            .font(.headline)
                        
                        HStack(spacing: 20) {
                            Gauge(value: earningsThisMonth, in: 0...max(1, store.settings.monthlyTargetEarnings)) {
                                Text("Monthly Target")
                            } currentValueLabel: {
                                Text(store.formatCurrency(earningsThisMonth))
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                            .gaugeStyle(.accessoryCircular)
                            .scaleEffect(1.2)
                            .padding(.trailing, 10)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Goal: \(store.formatCurrency(store.settings.monthlyTargetEarnings))")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                let percentage = (earningsThisMonth / max(1, store.settings.monthlyTargetEarnings)) * 100
                                Text(String(format: "%.0f%% of goal achieved", percentage))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
                    
                    // Revenue Projection Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Current Month Projection")
                            .font(.headline)
                        
                        let projectionRemaining = store.projectedEarningsRemaining
                        let projectedTotal = earningsThisMonth + projectionRemaining
                        
                        Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 6) {
                            GridRow {
                                Text("Current Earnings:")
                                    .foregroundColor(.secondary)
                                Text(store.formatCurrency(earningsThisMonth))
                                    .fontWeight(.semibold)
                            }
                            GridRow {
                                Text("Scheduled (Remaining):")
                                    .foregroundColor(.secondary)
                                Text(store.formatCurrency(projectionRemaining))
                                    .foregroundColor(.blue)
                            }
                            GridRow {
                                Text("Projected Total:")
                                    .foregroundColor(.secondary)
                                Text(store.formatCurrency(projectedTotal))
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }
                        }
                        .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
                }
                
                // Graphs and Charts Row
                HStack(spacing: 20) {
                    // Chart 1: Monthly Earnings
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Revenue Trend")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if monthlyEarningsData.isEmpty {
                            Spacer()
                            Text("No revenue recorded yet.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                        } else {
                            Chart(monthlyEarningsData) { data in
                                BarMark(
                                    x: .value("Month", data.monthName),
                                    y: .value("Revenue", data.amount)
                                )
                                .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .bottom, endPoint: .top))
                                .cornerRadius(4)
                            }
                            .frame(height: 220)
                            .chartYAxis {
                                AxisMarks(format: .currency(code: store.settings.currencyCode).precision(.fractionLength(0)))
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Chart 2: Student Share
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Revenue by Student")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if studentEarningsData.isEmpty {
                            Spacer()
                            Text("No student earnings recorded.")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                            Spacer()
                        } else {
                            Chart(studentEarningsData) { data in
                                BarMark(
                                    x: .value("Amount", data.amount),
                                    y: .value("Student", data.name)
                                )
                                .foregroundStyle(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                                .cornerRadius(4)
                            }
                            .frame(height: 220)
                            .chartXAxis {
                                AxisMarks(format: .currency(code: store.settings.currencyCode).precision(.fractionLength(0)))
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                
                // Today's Agenda & Recent Activity
                HStack(alignment: .top, spacing: 20) {
                    // Today's Lessons
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Today's Tutoring Schedule")
                            .font(.headline)
                        
                        if todaysSchedule.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary)
                                    Text("No sessions scheduled for today.")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 30)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(todaysSchedule, id: \.1.id) { student, session in
                                    Button(action: { onNavigateToStudent(student.id) }) {
                                        HStack(spacing: 15) {
                                            VStack(alignment: .leading) {
                                                Text("\(session.startTime) - \(session.endTime)")
                                                    .font(.headline)
                                                    .foregroundColor(.blue)
                                                Text(student.subject)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(width: 110, alignment: .leading)
                                            
                                            VStack(alignment: .leading) {
                                                Text(student.name)
                                                    .font(.body)
                                                    .fontWeight(.semibold)
                                                if !session.notes.isEmpty {
                                                    Text(session.notes)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Text(student.grade)
                                                .font(.caption2)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.purple.opacity(0.1))
                                                .foregroundColor(.purple)
                                                .cornerRadius(6)
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                        .cornerRadius(8)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // Recent Payments Log
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Payments")
                            .font(.headline)
                        
                        if store.payments.isEmpty {
                            HStack {
                                Spacer()
                                Text("No payments logged.")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 30)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(store.payments.prefix(4)) { payment in
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(store.students.first(where: { $0.id == payment.studentId })?.name ?? "Unknown")
                                                .font(.body)
                                                .fontWeight(.semibold)
                                            Text(payment.date, style: .date)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text("+" + store.formatCurrency(payment.amount))
                                            .font(.body)
                                            .fontWeight(.bold)
                                            .foregroundColor(.green)
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(NSColor.windowBackgroundColor))
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
            }
            .padding(25)
        }
        // Sheets
        .sheet(isPresented: $showingAddPaymentSheet) {
            AddPaymentSheet()
        }
        .sheet(isPresented: $showingAddStudentSheet) {
            AddStudentSheet()
        }
        .sheet(isPresented: $showingAddAssignmentSheet) {
            AddAssignmentSheet()
        }
    }
}

// MARK: - MetricCard Component
struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 1)
    }
}

// MARK: - Quick Action Sheets (Basic Forms)
struct AddPaymentSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: StorageManager
    
    @State private var selectedStudentId = UUID()
    @State private var amountString = ""
    @State private var hoursString = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var validationError: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Log Payment")
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
                
                TextField("Amount (\(store.settings.currencyCode))", text: $amountString)
                TextField("Hours Taught (Optional)", text: $hoursString)
                DatePicker("Date", selection: $date, displayedComponents: [.date])
                TextField("Notes", text: $notes)
            }
            .formStyle(.grouped)
            .frame(width: 400, height: 220)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Log Payment") {
                    if selectedStudentId == UUID() {
                        validationError = "Please select a student."
                        return
                    }
                    guard let amount = Double(amountString), amount > 0 else {
                        validationError = "Please enter a valid positive payment amount."
                        return
                    }
                    let hours = Double(hoursString) ?? 0.0
                    if hours < 0 {
                        validationError = "Hours taught cannot be negative."
                        return
                    }
                    
                    let payment = Payment(studentId: selectedStudentId, amount: amount, date: date, hoursTaught: hours, notes: notes)
                    store.addPayment(payment)
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

struct AddStudentSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: StorageManager
    
    @State private var name = ""
    @State private var subject = ""
    @State private var grade = ""
    @State private var rateType: RateType = .hourly
    @State private var rateValueString = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var scheduleNotes = ""
    @State private var notes = ""
    @State private var validationError: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add New Student")
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
                
                Picker("Rate Type", selection: $rateType) {
                    ForEach(RateType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                
                TextField("Rate (\(store.settings.currencyCode))", text: $rateValueString)
                TextField("Email", text: $email)
                TextField("Phone", text: $phone)
                TextField("Schedule Time", text: $scheduleNotes, prompt: Text("e.g. Mon & Wed 4 PM"))
                TextField("Notes / Focus Area", text: $notes)
            }
            .formStyle(.grouped)
            .frame(width: 450, height: 350)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Add Student") {
                    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedName.isEmpty {
                        validationError = "Student name is required."
                        return
                    }
                    guard let rateValue = Double(rateValueString), rateValue >= 0 else {
                        validationError = "Please enter a valid billing rate (positive number)."
                        return
                    }
                    
                    let student = Student(name: trimmedName, subject: subject, grade: grade, rateType: rateType, rateValue: rateValue, contactEmail: email, contactPhone: phone, scheduleNotes: scheduleNotes, notes: notes)
                    store.addStudent(student)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding([.horizontal, .bottom])
        }
    }
}

struct AddAssignmentSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: StorageManager
    
    @State private var selectedStudentId = UUID()
    @State private var title = ""
    @State private var description = ""
    @State private var dueDate = Date().addingTimeInterval(86400 * 7)
    @State private var validationError: String? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Assign Homework")
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
                
                TextField("Assignment Title", text: $title)
                TextField("Description (Optional)", text: $description)
                DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date])
            }
            .formStyle(.grouped)
            .frame(width: 400, height: 200)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Assign") {
                    if selectedStudentId == UUID() {
                        validationError = "Please select a student."
                        return
                    }
                    let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmedTitle.isEmpty {
                        validationError = "Assignment title is required."
                        return
                    }
                    
                    let assignment = Assignment(studentId: selectedStudentId, title: trimmedTitle, description: description, dueDate: dueDate)
                    store.addAssignment(assignment)
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
