import SwiftUI

public struct SessionTimerView: View {
    @EnvironmentObject var store: StorageManager
    
    @State private var selectedStudentId: UUID = UUID()
    @State private var elapsedSeconds: Int = 0
    @State private var isRunning = false
    @State private var timer: Timer? = nil
    
    @State private var showingBillingSheet = false
    @State private var billingAmount: Double = 0.0
    @State private var billingHours: Double = 0.0
    @State private var billingNotes: String = ""
    
    public init() {}
    
    // Filter only active students who are paid hourly
    private var hourlyActiveStudents: [Student] {
        store.students.filter { $0.isActive && $0.rateType == .hourly }
    }
    
    private var selectedStudent: Student? {
        store.students.first(where: { $0.id == selectedStudentId })
    }
    
    private var liveEarnings: Double {
        guard let student = selectedStudent else { return 0.0 }
        let hours = Double(elapsedSeconds) / 3600.0
        return hours * student.rateValue
    }
    
    private var timeString: String {
        let hours = elapsedSeconds / 3600
        let minutes = (elapsedSeconds % 3600) / 60
        let seconds = elapsedSeconds % 60
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
                    .disabled(isRunning)
                }
                
                // Clock widget
                Text(timeString)
                    .font(.system(size: 72, weight: .semibold, design: .monospaced))
                    .foregroundColor(isRunning ? .blue : .primary)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                
                // Live Earnings Indicator
                if selectedStudentId != UUID(), let student = selectedStudent {
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
                            isRunning ? "Pause Session" : "Start Session",
                            systemImage: isRunning ? "pause.fill" : "play.fill"
                        )
                        .font(.headline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(isRunning ? .orange : .blue)
                    .disabled(selectedStudentId == UUID())
                    
                    // Reset
                    Button(action: resetTimer) {
                        Label("Reset", systemImage: "arrow.clockwise")
                            .font(.headline)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.bordered)
                    .disabled(elapsedSeconds == 0 || isRunning)
                    
                    // Stop & Bill
                    Button(action: stopAndBillSession) {
                        Label("Stop & Record", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .disabled(elapsedSeconds == 0 || selectedStudentId == UUID())
                }
            }
            .padding(40)
            .background(Color(NSColor.windowBackgroundColor))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
            
            Spacer()
        }
        .onAppear {
            if hourlyActiveStudents.isEmpty == false && selectedStudentId == UUID() {
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
        if isRunning {
            isRunning = false
            timer?.invalidate()
            timer = nil
        } else {
            isRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                Task { @MainActor in
                    elapsedSeconds += 1
                }
            }
        }
    }
    
    private func resetTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        elapsedSeconds = 0
    }
    
    private func stopAndBillSession() {
        // Pause timer if running
        if isRunning {
            toggleTimer()
        }
        
        guard let student = selectedStudent else { return }
        
        let calculatedHours = Double(elapsedSeconds) / 3600.0
        billingHours = calculatedHours
        billingAmount = calculatedHours * student.rateValue
        
        let roundedMinutes = elapsedSeconds / 60
        billingNotes = "Automated session timer log: \(roundedMinutes) minutes"
        
        showingBillingSheet = true
        resetTimer()
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
            .formStyle(.grouped)
            .frame(width: 400, height: 220)
            
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
