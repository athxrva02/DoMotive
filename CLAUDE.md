# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DoMotive is an iOS app built with SwiftUI that combines mood tracking, task management, journaling, and daily planning features. The app helps users track their emotional state and provides task suggestions based on their current mood.

## Development Environment

- **Platform**: iOS (minimum deployment target: iOS 18.5)
- **Language**: Swift 5.0
- **Framework**: SwiftUI
- **Data Persistence**: Core Data with CloudKit integration
- **Development Team**: J65B8G3B3Y
- **Bundle Identifier**: athx.DoMotive

## Build Commands

### Building the Project
```bash
# Build the project for Debug configuration
xcodebuild -project DoMotive.xcodeproj -scheme DoMotive -configuration Debug build

# Build for Release configuration
xcodebuild -project DoMotive.xcodeproj -scheme DoMotive -configuration Release build

# Build for iOS Simulator
xcodebuild -project DoMotive.xcodeproj -scheme DoMotive -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' build
```

### Running Tests
```bash
# Run unit tests
xcodebuild test -project DoMotive.xcodeproj -scheme DoMotive -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'

# Run UI tests specifically
xcodebuild test -project DoMotive.xcodeproj -scheme DoMotive -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' -only-testing:DoMotiveUITests
```

### Clean Build
```bash
xcodebuild clean -project DoMotive.xcodeproj -scheme DoMotive
```

## Architecture

### App Structure
- **DoMotiveApp.swift**: Main app entry point with Core Data environment setup
- **ContentView.swift**: Root view containing TabView with four main sections (Home, Tasks, Mood, Journal)
- **Persistence.swift**: Core Data stack configuration with CloudKit container setup

### Data Model (Core Data Entities)
- **Task**: Task management with mood-based suggestions
  - `title`, `details`, `dueDate`, `isCompleted`, `moodTag`, `recurrenceRule`
- **MoodEntry**: Daily mood tracking with tags
  - `moodValue` (1-10 scale), `date`, `tags`
- **JournalEntry**: Text-based journal entries
  - `text`, `date`
- **Item**: Legacy entity (appears unused in current implementation)

### View Organization
- **Views/**: Contains all SwiftUI view files
  - `HomeView.swift`: Dashboard with mood status, quick actions, and mood-based task suggestions
  - `AddTaskView.swift`, `TaskListView.swift`: Task management
  - `AddMoodView.swift`, `MoodListView.swift`: Mood tracking
  - `AddJournalView.swift`, `JournalListView.swift`: Journaling
  - `PlanDayView.swift`: Daily planning interface

### Utilities
- **Utils/**: Helper utilities
  - `CloudKitCheck.swift`: CloudKit availability and status checking
  - `Date+Extensions.swift`: Date manipulation extensions

### Key Features
- **Mood-Based Task Suggestions**: HomeView filters tasks based on current mood tags
- **CloudKit Sync**: Automatic data synchronization across devices
- **Tab-Based Navigation**: Four main sections accessible via bottom tab bar
- **Daily Planning**: Dedicated view for planning daily activities

## Development Notes

- The app uses CloudKit for data synchronization, requiring proper entitlements and iCloud configuration
- Mood values are stored as Int16 with a 1-10 scale
- Task suggestions are filtered by matching mood tags between MoodEntry and Task entities
- The Core Data model includes CloudKit sync capabilities with "usedWithCloudKit=YES"
- SwiftUI previews are supported with in-memory Core Data context for development