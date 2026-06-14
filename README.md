# HomeTutor - Offline macOS Desktop Application

**HomeTutor** is a native, offline-first macOS desktop application designed specifically for independent hometutors, coaches, and private instructors. It provides a central, private control center to manage student listings, schedule tutoring sessions, issue and grade homework, log student comprehension progress, and track monthly/lifetime earnings.

Because it runs completely locally, it does not require an internet connection, has zero server latency, and guarantees absolute privacy for sensitive client data.

---

## Key Features

1. **Dashboard & Analytics:** 
   - Instant visual KPI indicators showing active students, revenue this month, total revenue, and pending assignments.
   - Built-in data visualization using Swift Charts mapping monthly revenue trends and individual student billing shares.
   - Live agenda displaying today's lesson list and timing.

2. **Student Directory & Profiles:**
   - Dual-pane browser with fast keyword searching.
   - Full student logs including standard grade levels, hourly/monthly rates, email/phone contact cards, and pedagogical notes.
   - Timelines containing topic logs, subjective comprehension indexes (1-5 stars), and homework history.

3. **Earnings & Billings Log:**
   - Dynamic tabular listing of historical payments.
   - Search/filter controls sorted by student or duration.
   - One-click native **CSV Spreadsheet Export** (utilizing macOS `NSSavePanel`) for local accounting, taxes, or printouts.

4. **Weekly Class Planner:**
   - Weekday agenda rows (Monday through Sunday) showing calendar timing, student, and lesson focus.
   - Easy scheduler interface with minute-precision timing pickers.

5. **Assignment Tracker:**
   - central grid monitoring homework statuses: *Pending*, *Submitted*, and *Graded*.
   - Grading panel supporting numerical scores and customized tutor feedback.

6. **Local Backup & Restores:**
   - Settings control to open the local folder directory directly in macOS Finder.
   - Command to flush all databases or load pre-built demo records to explore interface features.

---

## Architectural Outline

- **Language:** Swift 6.0
- **Frameworks:** SwiftUI, Swift Charts, AppKit, UniformTypeIdentifiers
- **Persistence:** Local JSON data serialization (`Codable`) loaded synchronously on startup.
- **Data Location:** `~/Library/Application Support/HomeTutor/`
- **Minimum OS Support:** macOS Ventura (13.0) or newer (required for Swift Charts and modern navigation APIs).

---

## Setup & Compilation (No Xcode IDE Required)

This project is fully structured as a standard Swift Package Manager (SPM) executable target. It compiles and packages into a first-class macOS GUI application bundle (`HomeTutor.app`) purely through command-line utilities.

### Prerequisites

You need the macOS Command Line Tools installed (which provides `swift`, `clang`, and `codesign`). If you do not have them, run:
```bash
xcode-select --install
```
*Note: The full Xcode IDE is **not** required.*

### Compile and Build

Run the automated build script:
```bash
./build.sh
```
This script will:
1. Compile the Swift executable in `release` mode.
2. Construct the standard `.app` folder structure (`Contents/MacOS/`, `Contents/Info.plist`).
3. Copy the compiled binary and metadata.
4. Apply ad-hoc code-signing (`codesign`) so macOS allows the GUI executable to run locally.

### Compile and Launch

To compile and immediately open the application, pass the `run` parameter:
```bash
./build.sh run
```

---

## Local Database Files

All databases are saved locally in standard JSON files. Feel free to copy or backup this folder:
```text
~/Library/Application Support/HomeTutor/
├── students.json
├── payments.json
├── assignments.json
├── progress.json
└── schedule.json
```

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
