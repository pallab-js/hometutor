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
                    }
                }
                
                Section("Management") {
                    NavigationLink(value: SidebarSelection.students) {
                        Label("Students", systemImage: "person.2.fill")
                    }
                    
                    NavigationLink(value: SidebarSelection.sessionTimer) {
                        Label("Session Timer", systemImage: "timer")
                    }
                    
                    NavigationLink(value: SidebarSelection.payments) {
                        Label("Earnings", systemImage: "indianrupeesign.circle.fill")
                    }
                    
                    NavigationLink(value: SidebarSelection.schedule) {
                        Label("Schedule", systemImage: "calendar")
                    }
                    
                    NavigationLink(value: SidebarSelection.assignments) {
                        Label("Assignments", systemImage: "book.closed.fill")
                    }
                }
                
                Section("Application") {
                    NavigationLink(value: SidebarSelection.settings) {
                        Label("Settings", systemImage: "gearshape.fill")
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
                    StudentListView(selectedStudentId: $selectedStudentId, onNavigateToTimer: {
                        self.selection = .sessionTimer
                    })
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
