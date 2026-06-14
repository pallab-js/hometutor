import SwiftUI
import UniformTypeIdentifiers

public struct PaymentViews: View {
    @EnvironmentObject var store: StorageManager
    @State private var showingAddPayment = false
    @State private var selectedStudentFilter: UUID? = nil
    
    public init() {}
    
    private var filteredPayments: [Payment] {
        if let studentId = selectedStudentFilter {
            return store.payments.filter { $0.studentId == studentId }
        }
        return store.payments
    }
    
    private var totalFilteredRevenue: Double {
        filteredPayments.reduce(0.0) { $0 + $1.amount }
    }
    
    private var totalHoursTaught: Double {
        filteredPayments.reduce(0.0) { $0 + $1.hoursTaught }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Earnings & Billings")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("Manage transaction logs, hourly billings, and export accounts.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: exportCSVFile) {
                    Label("Export to CSV", systemImage: "square.and.arrow.up")
                }
                .disabled(store.payments.isEmpty)
                
                Button(action: { showingAddPayment = true }) {
                    Label("Record Payment", systemImage: "indianrupeesign.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding([.top, .horizontal], 25)
            
            // Filters & Quick Summaries
            HStack(spacing: 20) {
                // Filter dropdown
                Picker("Filter by Student", selection: $selectedStudentFilter) {
                    Text("All Students").tag(UUID?.none)
                    ForEach(store.students) { student in
                        Text(student.name).tag(UUID?.some(student.id))
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 280)
                
                Spacer()
                
                // Live Aggregations
                HStack(spacing: 30) {
                    VStack(alignment: .leading) {
                        Text("TOTAL REVENUE")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(store.formatCurrency(totalFilteredRevenue))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("HOURS LOGGED")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f Hrs", totalHoursTaught))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.horizontal, 25)
            
            // Payments Table
            VStack {
                if filteredPayments.isEmpty {
                    Spacer()
                    VStack(spacing: 15) {
                        Image(systemName: "banknote")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No payment entries match the selected filters.")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    Table(filteredPayments) {
                        TableColumn("Payment Date") { payment in
                            Text(payment.date, style: .date)
                        }
                        
                        TableColumn("Student Name") { payment in
                            let studentName = store.students.first(where: { $0.id == payment.studentId })?.name ?? "Archived Student"
                            Text(studentName)
                                .fontWeight(.semibold)
                        }
                        
                        TableColumn("Hours Taught") { payment in
                            Text(payment.hoursTaught > 0 ? String(format: "%.1f Hrs", payment.hoursTaught) : "Flat Rate")
                        }
                        
                        TableColumn("Earnings") { payment in
                            Text(store.formatCurrency(payment.amount))
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        
                        TableColumn("Memo / Notes") { payment in
                            Text(payment.notes.isEmpty ? "--" : payment.notes)
                        }
                        
                        TableColumn("Action") { payment in
                            Button(action: { store.deletePayment(id: payment.id) }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding([.horizontal, .bottom], 25)
        }
        .sheet(isPresented: $showingAddPayment) {
            AddPaymentSheet()
        }
    }
    
    // NSSavePanel for native file exporting
    private func exportCSVFile() {
        guard let csvContent = store.exportToCSV() else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.commaSeparatedText]
        savePanel.nameFieldStringValue = "hometutor_earnings_\(DateFormatter.fileDateString(from: Date())).csv"
        savePanel.title = "Save Earnings Report"
        savePanel.message = "Choose where to save your local CSV workbook."
        
        savePanel.begin { response in
            if response == .OK, let saveURL = savePanel.url {
                do {
                    try csvContent.write(to: saveURL, atomically: true, encoding: .utf8)
                    print("✅ CSV Exported successfully to \(saveURL.path)")
                } catch {
                    print("❌ Failed to write CSV file: \(error)")
                }
            }
        }
    }
}

// Date formatter helper
extension DateFormatter {
    static func fileDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
}
