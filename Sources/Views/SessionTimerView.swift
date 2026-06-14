import SwiftUI

public struct SessionTimerView: View {
    @EnvironmentObject var store: StorageManager
    
    @State private var selectedStudentId: UUID = UUID()
    
    @State private var showingBillingSheet = false
    @State private var billingAmount: Double = 0.0
    @State private var billingHours: Double = 0.0
    @State private var billingNotes: String = ""
    @State private var isPulsing = false
    
    public init() {}
    
    // Filter only active students who are paid hourly
    private var hourlyActiveStudents: [Student] {
        store.students.filter { $0.isActive && $0.rateType == .hourly }
    }
    
    private var selectedStudent: Student? {
        if store.isTimerRunning {
            return store.students.first(where: { $0.id == store.activeTimerStudentId })
        } else {
            return store.students.first(where: { $0.id == selectedStudentId })
        }
    }
    
    private var liveEarnings: Double {
        guard let student = selectedStudent else { return 0.0 }
        let hours = Double(store.timerElapsedSeconds) / 3600.0
        return hours * student.rateValue
    }
    
    private var timeString: String {
        let elapsed = store.timerElapsedSeconds
        let hours = elapsed / 3600
        let minutes = (elapsed % 3600) / 60
        let seconds = elapsed % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    public var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Lesson Session Timer")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text("Track your lesson durations in real-time. The application will automatically calculate fees based on student hourly rates.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding([.top, .horizontal], 25)
            
            Spacer()
            
            // Timer Control Box
            VStack(spacing: 25) {
                // Selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Select Hourly Student")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Picker("", selection: $selectedStudentId) {
                        Text("Select Student").tag(UUID())
                        ForEach(hourlyActiveStudents) { student in
                            Text("\(student.name) (\(store.formatCurrency(student.rateValue))/hr)").tag(student.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 320)
                    .disabled(store.isTimerRunning)
                }
                
                // Status Indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(store.isTimerRunning ? Color.green : Color.secondary)
                        .frame(width: 8, height: 8)
                        .scaleEffect(store.isTimerRunning && isPulsing ? 1.3 : 1.0)
                        .opacity(store.isTimerRunning && isPulsing ? 1.0 : 0.6)
                        .animation(store.isTimerRunning ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default, value: isPulsing)
                    Text(store.isTimerRunning ? "SESSION IN PROGRESS" : "SESSION PAUSED")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(store.isTimerRunning ? .green : .secondary)
                        .tracking(1.5)
                }
                .onAppear {
                    isPulsing = true
                }
                
                // Clock widget
                Text(timeString)
                    .font(.system(size: 72, weight: .semibold, design: .monospaced))
                    .foregroundColor(store.isTimerRunning ? .green : .primary)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 40)
                    .background(Color.primary.opacity(0.02))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                    )
                
                // Live Earnings Indicator
                if (store.isTimerRunning ? store.activeTimerStudentId : selectedStudentId) != UUID(), let student = selectedStudent {
                    VStack(spacing: 4) {
                        Text("ACCUMULATED FEES")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .tracking(1)
                        Text(store.formatCurrency(liveEarnings))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Rate: \(store.formatCurrency(student.rateValue)) / hr")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .transition(.opacity)
                }
                
                // Control Buttons
                HStack(spacing: 20) {
                    // Start / Pause
                    Button(action: toggleTimer) {
                        Label(
                            store.isTimerRunning ? "Pause Session" : "Start Session",
                            systemImage: store.isTimerRunning ? "pause.fill" : "play.fill"
                        )
                        .font(.headline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(store.isTimerRunning ? .orange : .blue)
                    .disabled(selectedStudentId == UUID() && !store.isTimerRunning)
                    
                    // Reset
                    Button(action: resetTimer) {
                        Label("Reset", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.bordered)
                    .disabled(store.timerElapsedSeconds == 0 || store.isTimerRunning)
                    
                    // Stop & Bill
                    Button(action: stopAndBillSession) {
                        Label("Stop & Record", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(store.timerElapsedSeconds == 0)
                }
            }
            .padding(40)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 10, x: 0, y: 4)
            
            Spacer()
        }
        .onAppear {
            if let preselected = store.preselectedTimerStudentId {
                selectedStudentId = preselected
                store.preselectedTimerStudentId = nil // Clear it
            } else if store.isTimerRunning, let activeId = store.activeTimerStudentId {
                selectedStudentId = activeId
            } else if hourlyActiveStudents.isEmpty == false && (selectedStudentId == UUID() || !hourlyActiveStudents.contains(where: { $0.id == selectedStudentId })) {
                selectedStudentId = hourlyActiveStudents.first?.id ?? UUID()
            }
        }
        .sheet(isPresented: $showingBillingSheet) {
            AddPaymentSheetWithPreFill(
                studentId: selectedStudentId,
                amount: billingAmount,
                hours: billingHours,
                notes: billingNotes
            )
        }
    }
    
    // Timer Mechanics
    private func toggleTimer() {
        if store.isTimerRunning {
            store.pauseTimer()
        } else {
            store.startTimer(studentId: selectedStudentId)
        }
    }
    
    private func resetTimer() {
        store.resetTimer()
    }
    
    private func stopAndBillSession() {
        if store.isTimerRunning {
            store.pauseTimer()
        }
        
        guard let student = selectedStudent else { return }
        
        let calculatedHours = Double(store.timerElapsedSeconds) / 3600.0
        billingHours = calculatedHours
        billingAmount = calculatedHours * student.rateValue
        
        let roundedMinutes = store.timerElapsedSeconds / 60
        billingNotes = "Automated session timer log: \(roundedMinutes) minutes"
        
        let currentStudentId = student.id
        showingBillingSheet = true
        store.resetTimer()
        selectedStudentId = currentStudentId
    }
}

// Custom specialized Add Payment sheet for Timer completion pre-fills
struct AddPaymentSheetWithPreFill: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: StorageManager
    
    let studentId: UUID
    @State private var amountString: String
    @State private var hoursString: String
    @State private var notes: String
    @State private var date = Date()
    @State private var validationError: String? = nil
    
    init(studentId: UUID, amount: Double, hours: Double, notes: String) {
        self.studentId = studentId
        _amountString = State(initialValue: String(format: "%.2f", amount))
        _hoursString = State(initialValue: String(format: "%.1f", hours))
        _notes = State(initialValue: notes)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Confirm Session Payment Record")
                .font(.headline)
                .padding(.top)
            
            if let error = validationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Form {
                Picker("Student", selection: .constant(studentId)) {
                    if let student = store.students.first(where: { $0.id == studentId }) {
                        Text(student.name).tag(student.id)
                    }
                }
                .disabled(true)
                
                TextField("Calculated Amount", text: $amountString)
                TextField("Logged Duration (Hours)", text: $hoursString)
                DatePicker("Session Date", selection: $date, displayedComponents: [.date])
                TextField("Notes", text: $notes)
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
                
                Button("Save Record") {
                    guard let amount = Double(amountString), amount > 0 else {
                        validationError = "Please enter a valid positive amount."
                        return
                    }
                    guard let hours = Double(hoursString), hours >= 0 else {
                        validationError = "Please enter a valid numeric hour count."
                        return
                    }
                    
                    let payment = Payment(
                        studentId: studentId,
                        amount: amount,
                        date: date,
                        hoursTaught: hours,
                        notes: notes
                    )
                    store.addPayment(payment)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding([.horizontal, .bottom])
        }
    }
}
