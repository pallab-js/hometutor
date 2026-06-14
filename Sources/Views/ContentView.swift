import SwiftUI

public enum SidebarSelection: Hashable {
    case dashboard
    case students
    case payments
    case schedule
    case assignments
    case settings
}

public struct ContentView: View {
    @State private var selection: SidebarSelection = .dashboard
    
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
                    
                    NavigationLink(value: SidebarSelection.payments) {
                        Label("Earnings", systemImage: "indianrupeesign.circle.fill") // Using standard Indian Rupee or generic currency
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
                    DashboardView()
                case .students:
                    StudentListView()
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
