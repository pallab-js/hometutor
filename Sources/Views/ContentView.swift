import SwiftUI

public enum SidebarSelection: Hashable {
    case dashboard
    case students
    case payments
    case schedule
    case assignments
    case sessionTimer
    case settings
}

public struct ContentView: View {
    @State private var selection: SidebarSelection = .dashboard
    @State private var selectedStudentId: UUID? = nil
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section("Home") {
                    NavigationLink(value: SidebarSelection.dashboard) {
                        Label("Dashboard", systemImage: "chart.bar.doc.horizontal.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Section("Management") {
                    NavigationLink(value: SidebarSelection.students) {
                        Label("Students", systemImage: "person.2.fill")
                            .foregroundColor(.purple)
                    }
                    
                    NavigationLink(value: SidebarSelection.sessionTimer) {
                        Label("Session Timer", systemImage: "timer")
                            .foregroundColor(.cyan)
                    }
                    
                    NavigationLink(value: SidebarSelection.payments) {
                        Label("Earnings", systemImage: "indianrupeesign.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    NavigationLink(value: SidebarSelection.schedule) {
                        Label("Schedule", systemImage: "calendar")
                            .foregroundColor(.orange)
                    }
                    
                    NavigationLink(value: SidebarSelection.assignments) {
                        Label("Assignments", systemImage: "book.closed.fill")
                            .foregroundColor(.red)
                    }
                }
                
                Section("Application") {
                    NavigationLink(value: SidebarSelection.settings) {
                        Label("Settings", systemImage: "gearshape.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
            
        } detail: {
            Group {
                switch selection {
                case .dashboard:
                    DashboardView(onNavigateToStudent: { studentId in
                        self.selectedStudentId = studentId
                        self.selection = .students
                    })
                case .students:
                    StudentListView(selectedStudentId: $selectedStudentId)
                case .sessionTimer:
                    SessionTimerView()
                case .payments:
                    PaymentViews()
                case .schedule:
                    ScheduleViews()
                case .assignments:
                    AssignmentViews()
                case .settings:
                    SettingsView()
                }
            }
            .frame(minWidth: 700)
        }
    }
}
