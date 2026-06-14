import SwiftUI

public struct SettingsView: View {
    @EnvironmentObject var store: StorageManager
    @State private var showingResetAlert = false
    @State private var showingSampleAlert = false
    
    @State private var currencyCode = "INR"
    @State private var targetEarningsString = ""
    @State private var remindersEnabled = true
    
    public init() {}
    
    private var dbPath: String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("HomeTutor", isDirectory: true).path
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings & Maintenance")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("Manage offline databases, data locations, and application resets.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
                
                // Section 1: Data Location
                VStack(alignment: .leading, spacing: 12) {
                    Text("Local Database Location")
                        .font(.headline)
                    Text("This application is entirely offline. All data is saved on your hard drive in standard JSON formatting. You can navigate to the folder below to backup or copy these files.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text(dbPath)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        
                        Button("Open in Finder") {
                            let url = URL(fileURLWithPath: dbPath)
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
                
                // Section 1.5: Tutor Preferences
                VStack(alignment: .leading, spacing: 15) {
                    Text("Tutoring Preferences")
                        .font(.headline)
                    
                    Form {
                        Picker("Currency Code", selection: $currencyCode) {
                            Text("INR (₹)").tag("INR")
                            Text("USD ($)").tag("USD")
                            Text("EUR (€)").tag("EUR")
                            Text("GBP (£)").tag("GBP")
                            Text("AUD ($)").tag("AUD")
                            Text("CAD ($)").tag("CAD")
                        }
                        .pickerStyle(.menu)
                        
                        TextField("Monthly Target Earnings", text: $targetEarningsString)
                            .textFieldStyle(.roundedBorder)
                        
                        Toggle("Session Reminders (15 min prior)", isOn: $remindersEnabled)
                    }
                    .formStyle(.grouped)
                    .frame(height: 140)
                    .onChange(of: currencyCode) { _ in saveSettings() }
                    .onChange(of: targetEarningsString) { _ in saveSettings() }
                    .onChange(of: remindersEnabled) { newValue in
                        if newValue {
                            NotificationManager.shared.requestAuthorization()
                        }
                        saveSettings()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)

                // Section 2: Data Tools & Reset
                VStack(alignment: .leading, spacing: 15) {
                    Text("Database Management")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Restore Mock Sample Data")
                                    .fontWeight(.semibold)
                                Text("Prepopulate the application with dummy records to test features.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Load Samples") {
                                showingSampleAlert = true
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Erase All Database Content")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                                Text("Permanently delete all students, logs, schedules, and earnings.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Reset Database", role: .destructive) {
                                showingResetAlert = true
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
                
                // Section 3: App Information
                VStack(alignment: .leading, spacing: 10) {
                    Text("About HomeTutor")
                        .font(.headline)
                    
                    Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                        GridRow {
                            Text("App Version:")
                                .fontWeight(.semibold)
                            Text("1.0.0 (Offline Desktop)")
                        }
                        GridRow {
                            Text("Engine:")
                                .fontWeight(.semibold)
                            Text("SwiftUI + Swift Charts (Native macOS)")
                        }
                        GridRow {
                            Text("Sandbox Safety:")
                                .fontWeight(.semibold)
                            Text("Complies with macOS Sandbox local storage guidelines. Zero external telemetry.")
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.windowBackgroundColor))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 2)
            }
            .padding(25)
        }
        // Alerts
        .alert("Reset All Data?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Erase Everything", role: .destructive) {
                store.clearAllData()
            }
        } message: {
            Text("This action is permanent and cannot be undone. All offline tutoring records will be deleted.")
        }
        .alert("Reload Sample Data?", isPresented: $showingSampleAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reload") {
                store.resetToSampleData()
                currencyCode = store.settings.currencyCode
                targetEarningsString = String(format: "%.0f", store.settings.monthlyTargetEarnings)
                remindersEnabled = store.settings.remindersEnabled
            }
        } message: {
            Text("This will overwrite all your current entries with the mock sample dataset.")
        }
        .onAppear {
            currencyCode = store.settings.currencyCode
            targetEarningsString = String(format: "%.0f", store.settings.monthlyTargetEarnings)
            remindersEnabled = store.settings.remindersEnabled
        }
    }
    
    private func saveSettings() {
        let code = currencyCode
        let target = Double(targetEarningsString) ?? store.settings.monthlyTargetEarnings
        let reminders = remindersEnabled
        
        let newSettings = AppSettings(currencyCode: code, monthlyTargetEarnings: target, remindersEnabled: reminders)
        store.updateSettings(newSettings)
    }
}
