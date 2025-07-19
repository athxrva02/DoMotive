# DoMotive - Xcode Previews Guide

## Overview

Xcode Previews allow you to see and interact with your SwiftUI views directly in Xcode without running the full app. This significantly speeds up development and testing of individual components.

## How to Access Previews in Xcode

### 1. Open Canvas Panel
- In Xcode, with a SwiftUI file open, press `Cmd + Option + Enter` 
- Or go to **Editor > Canvas** in the menu bar
- The Canvas panel will appear on the right side

### 2. View Multiple Previews
- Each `#Preview` macro creates a separate preview
- You can have multiple previews in the same file to test different states
- Previews appear as separate cards in the Canvas

### 3. Interactive Previews
- Click the **"Play"** button on a preview to make it interactive
- You can tap buttons, enter text, and navigate between views
- This allows testing without running the full simulator

## Available Previews in DoMotive

### Main App Views

#### ContentView
```swift
#Preview("ContentView")              // Full app with sample data
#Preview("ContentView - Empty State") // Empty state for testing
```

#### HomeView
```swift
#Preview("HomeView")                 // Dashboard with mood tracking
#Preview("DifficultyIndicator")      // Component preview
```

#### TaskListView
```swift
#Preview("TaskListView")             // Task management with data
#Preview("TaskListView Empty")       // Empty state view
```

#### SuggestionView
```swift
#Preview("SuggestionView")           // AI suggestions interface
#Preview("QuickActionCard")          // Individual action card
```

### Input Views

#### AddTaskView
```swift
#Preview("AddTaskView")              // Task creation form
```

#### AddMoodView
```swift
#Preview("AddMoodView")              // Mood logging interface
```

### Component Library

#### TaskSuggestionCard
```swift
#Preview("TaskSuggestionCard")       // Interactive suggestion card
```

#### LabelPickerView
```swift
#Preview("LabelPickerView")          // Label selection interface
#Preview("CreateLabelView")          // Custom label creation
```

#### DiscreteMoodSlider
```swift
#Preview("DiscreteMoodSlider")       // Mood selection slider
```

## Preview Data Context

### Two Data States Available

#### 1. Preview Context (with sample data)
```swift
PersistenceController.preview.container.viewContext
```
**Contains:**
- Sample mood entries (Happy mood, level 7)
- 3 sample tasks (workout, work, grocery shopping)
- Task templates for suggestions
- Custom labels with usage data
- All built-in task templates

#### 2. Empty Context (no data)
```swift
PersistenceController.empty.container.viewContext
```
**Contains:**
- No data - perfect for testing empty states
- First-time user experience
- Loading states and placeholders

## How to Use Previews Effectively

### 1. Development Workflow
1. Open a SwiftUI view file
2. Enable Canvas (`Cmd + Option + Enter`)
3. Make code changes
4. Preview updates automatically
5. Test interactions by clicking "Play"

### 2. Testing Different States
- Use preview context for normal usage testing
- Use empty context for edge case testing
- Create custom preview data for specific scenarios

### 3. Component Testing
- Test individual components in isolation
- Verify animations and interactions
- Check responsive design across different sizes

### 4. Theme Testing
All previews include `ColorThemeManager.shared` which means:
- You can see mood-responsive theming
- Colors adapt based on mood state
- Animations preview correctly

## Preview Benefits

### ⚡ Speed
- No need to build and run full app
- Instant feedback on changes
- Fast iteration cycles

### 🔍 Isolation
- Test components independently
- Focus on specific functionality
- Easier debugging

### 📱 Multiple States
- Test different data scenarios
- Empty states, error states, loading states
- Various mood themes simultaneously

### 🎨 Design Validation
- See animations in action
- Verify spacing and layouts
- Test color themes and gradients

## Common Preview Patterns

### Testing Empty States
```swift
#Preview("Empty State") {
    MyView()
        .environment(\.managedObjectContext, PersistenceController.empty.container.viewContext)
        .environmentObject(ColorThemeManager.shared)
}
```

### Testing with Sample Data
```swift
#Preview("With Data") {
    MyView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(ColorThemeManager.shared)
}
```

### Component-Specific Previews
```swift
#Preview("Component Variants") {
    VStack {
        MyComponent(state: .loading)
        MyComponent(state: .success)
        MyComponent(state: .error)
    }
    .padding()
}
```

## Troubleshooting

### Preview Not Showing
1. Check that Canvas is enabled
2. Ensure proper environment objects are provided
3. Verify Core Data context is set up correctly
4. Look for compilation errors in the file

### Preview Crashes
1. Check Core Data model compatibility
2. Ensure all required environment objects are provided
3. Verify sample data creation doesn't fail

### Slow Preview Updates
1. Simplify complex views for faster previews
2. Use lighter preview data
3. Consider breaking large views into smaller components

## Next Steps

1. **Open Xcode** and navigate to any SwiftUI file
2. **Enable Canvas** with `Cmd + Option + Enter`
3. **Browse previews** to see different app states
4. **Click Play** on any preview to interact with it
5. **Make changes** and see instant updates

This preview setup makes DoMotive development much more efficient and enjoyable! 🚀