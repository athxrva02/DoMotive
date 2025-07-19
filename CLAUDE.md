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
  - `title`, `details`, `dueDate`, `isCompleted`, `moodTag`, `recurrenceRule`, `category`, `difficulty`, `estimatedDuration`, `labels`
- **TaskTemplate**: Template system for mood-based task suggestions
  - `title`, `description`, `category`, `estimatedDuration`, `difficulty`, `moodTags`, `timeOfDay`
- **TaskLabel**: User-defined label system for task categorization
  - `name`, `color`, `emoji`, `lastUsed`
- **TaskSuggestion**: Tracking accepted/dismissed task suggestions
  - `suggestionId`, `templateId`, `isAccepted`, `dateAccepted`
- **MoodEntry**: Daily mood tracking with tags
  - `moodValue` (1-10 scale), `date`, `tags`, `moodLabel`
- **JournalEntry**: Enhanced journal entries with mood integration
  - `text`, `date`, `moodValue`, `moodLabel`, `tags`
- **CustomMoodLabel**: User-defined mood labels
  - `name`, `emoji`, `moodValue`

### View Organization
- **Views/**: Contains all SwiftUI view files
  - `HomeView.swift`: Enhanced dashboard with mood-responsive theming, smart task suggestions, and quick actions
  - `AddTaskView.swift`, `TaskListView.swift`: Task management with labels, difficulty ratings, and swipe actions
  - `AddMoodView.swift`, `MoodListView.swift`: Comprehensive mood tracking with search, filtering, and enhanced UI
  - `AddJournalView.swift`, `JournalListView.swift`: Full-featured journaling with mood integration, editing, and detailed view
  - `SuggestionView.swift`: Smart task suggestion system with card-based UI
  - `PlanDayView.swift`: Daily planning interface
- **Views/Components/**: Reusable UI components
  - `DiscreteMoodSlider.swift`: Interactive mood selection slider
  - `LabelPickerView.swift`: Label management and selection interface
  - `TaskSuggestionCard.swift`: Individual task suggestion cards

### Utilities
- **Utils/**: Enhanced utility classes
  - `CloudKitCheck.swift`: CloudKit availability and status checking
  - `ColorThemeManager.swift`: Unified app-wide theming system with semantic colors
  - `TaskEngine.swift`: Intelligent task suggestion engine based on mood and time
  - `MoodManager.swift`: Mood data management and emoji/label mapping
  - `LabelManager.swift`: User-defined label system management
  - `Date+Extensions.swift`: Date manipulation extensions

### Key Features
- **Intelligent Task Engine**: AI-driven task suggestions based on mood, time of day, and user patterns
- **Comprehensive Mood Tracking**: 1-10 mood scale with custom labels, tags, and emoji support
- **Enhanced Journaling**: Full-featured journaling with mood integration, search, filtering, editing, and detailed reading view
- **User-Defined Labels**: Customizable task categorization system with colors and emojis
- **Unified Design System**: Consistent theming across all views with semantic colors and animations
- **Swipe Actions**: Edit tasks and journal entries via intuitive swipe gestures
- **Smart Date Handling**: Tasks show dates without time details for cleaner UI
- **CloudKit Sync**: Automatic data synchronization across devices
- **Tab-Based Navigation**: Four main sections accessible via bottom tab bar
- **Responsive UI**: Adaptive layouts and animations throughout the app

## Recent Enhancements (2025)

### Journal System Enhancements
- **Journal-Mood Integration**: Creating journal entries automatically creates/updates corresponding mood entries
- **Edit Journal Entries**: Full editing capability for existing journal entries via swipe actions
- **Detailed Journal View**: Click any journal entry to read in a focused, detailed view
- **Enhanced Journal Cards**: Improved visual design with better use of horizontal space

### Task Management Improvements
- **Simplified Date Display**: Tasks now show only dates (no hours/minutes/seconds) for cleaner UI
- **Swipe-to-Edit**: All task lists support swipe actions for editing tasks
- **Enhanced Task Cards**: Improved visual hierarchy and information display

### UI/UX Consistency
- **Unified Color Scheme**: Replaced mood-based dynamic theming with consistent app-wide colors
- **Enhanced Mood History**: Redesigned mood list with search, filtering, and improved card layout
- **iOS 17+ Compatibility**: Updated deprecated onChange syntax for modern iOS compatibility

## Development Notes

- **iOS Compatibility**: Minimum deployment target iOS 18.5, optimized for iOS 17+
- **Core Data**: Enhanced model with CloudKit sync capabilities ("usedWithCloudKit=YES")
- **Mood System**: Mood values stored as Int16 (1-10 scale) with automatic emoji/label mapping
- **Task Engine**: Intelligent matching system using mood tags, time patterns, and difficulty ratings
- **Theme Management**: Centralized ColorThemeManager with semantic color functions
- **Data Consistency**: Journal and mood entries are automatically synchronized
- **SwiftUI Previews**: Comprehensive preview support with sample data for all components
- **Error Handling**: Robust Core Data error handling with graceful fallbacks