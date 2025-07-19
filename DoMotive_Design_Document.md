# DoMotive - Engineering Design Document

## Overview

DoMotive is an iOS application that combines mood tracking, task management, journaling, and daily planning features. The app uses intelligent algorithms to suggest tasks based on the user's current emotional state, creating a personalized productivity experience.

**Key Features:**
- Mood-based task suggestion engine
- User-defined label system for task organization
- Dynamic UI theming that responds to emotional state
- Comprehensive task management with CRUD operations
- Journaling and daily planning capabilities
- CloudKit integration for cross-device synchronization

## Architecture Overview

### Core Architecture Pattern
DoMotive follows the **MVVM (Model-View-ViewModel)** architecture pattern with SwiftUI, utilizing:
- **Core Data** for local data persistence
- **CloudKit** for cloud synchronization
- **Singleton Managers** for business logic coordination
- **ObservableObject** pattern for reactive UI updates

### Data Layer Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   CloudKit      │◄──►│   Core Data     │◄──►│  UI Layer       │
│   (Remote)      │    │   (Local)       │    │  (SwiftUI)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Core Data Model

### Entity Relationships

```
Task ──────────┐
│              │
├─ TaskTemplate │
├─ TaskLabel   ─┼─ LabelManager
├─ MoodEntry   ─┤
├─ JournalEntry│
└─ TaskSuggestion
```

### Entity Definitions

#### Task
- **Purpose**: Represents user tasks with mood-based properties
- **Key Attributes**:
  - `title`, `details`, `category`
  - `difficulty` (1-5 scale), `estimatedDuration`
  - `isCompleted`, `dueDate`, `completedDate`
  - `labels` (comma-separated string)
  - `moodTag`, `recurrenceRule`

#### TaskTemplate
- **Purpose**: Predefined task patterns for suggestion engine
- **Key Attributes**:
  - `title`, `taskDescription`, `category`
  - `difficulty`, `estimatedDuration`
  - `moodRange` (e.g., "1-3,7-10")
  - `defaultLabels`, `isBuiltIn`

#### TaskLabel
- **Purpose**: User-defined tags for task organization
- **Key Attributes**:
  - `name`, `colorHex`, `category`
  - `usageCount`, `isBuiltIn`

#### MoodEntry
- **Purpose**: Daily mood tracking (1-10 scale)
- **Key Attributes**:
  - `moodValue`, `moodLabel`, `date`
  - `tags` (comma-separated emotions)

#### TaskSuggestion
- **Purpose**: Tracks suggestion algorithm performance
- **Key Attributes**:
  - `taskTemplateId`, `moodValue`
  - `suggestedDate`, `responseDate`
  - `wasAccepted`, `timeOfDay`

## Business Logic Managers

### TaskEngine
**Location**: `Utils/TaskEngine.swift`

**Responsibilities:**
- Intelligent task suggestion algorithm
- Mood compatibility scoring
- User history analysis
- Task creation from templates

**Core Algorithm:**
```swift
func getSuggestedTasks(for moodValue: Int16, 
                      timeOfDay: TimeOfDay = .current,
                      maxSuggestions: Int = 5) -> [TaskTemplate]
```

**Scoring Factors:**
- Mood compatibility (40% weight)
- Time of day optimization (20% weight)
- User acceptance history (25% weight)
- Energy level matching (15% weight)

### LabelManager
**Location**: `Utils/LabelManager.swift`

**Responsibilities:**
- CRUD operations for custom labels
- Built-in label categories management
- Usage analytics and recommendations
- Label-to-string serialization

**Built-in Categories:**
- Energy: Low Energy, Medium Energy, High Energy
- Location: Home, Office, Outdoors, Anywhere
- Type: Physical, Mental, Social, Creative
- Duration: Quick, Medium, Long
- Category: Administrative, Self Care, Learning

### ColorThemeManager
**Location**: `Utils/ColorThemeManager.swift`

**Responsibilities:**
- Dynamic theme adaptation based on mood
- 5 distinct mood-based color schemes
- UI animation coordination
- Theme persistence

**Mood Themes:**
- **Comfort** (1-2): Warm, soft colors for low moods
- **Gentle** (3-4): Calm, nurturing tones
- **Balanced** (5-6): Neutral, stable colors
- **Energetic** (7-8): Vibrant, motivating hues
- **Radiant** (9-10): Bright, celebratory colors

## Screen Architecture

### 1. HomeView
**File**: `Views/HomeView.swift`

**Purpose**: Central dashboard with personalized content

**Key Components:**
- Current mood status display
- Mood-based task suggestions (TaskSuggestionCard)
- Quick action buttons
- Daily progress overview

**Data Sources:**
- Today's mood entries
- Suggested tasks from TaskEngine
- Recent task completions

**Navigation Flows:**
- → AddMoodView (mood logging)
- → AddTaskView (task creation)
- → TaskListView (task management)
- → SuggestionView (detailed suggestions)

### 2. TaskListView
**File**: `Views/TaskListView.swift`

**Purpose**: Comprehensive task management interface

**Key Features:**
- Search and filtering capabilities
- Empty state management
- Swipe-to-delete functionality
- Edit task functionality
- Task completion animations

**Components:**
- `EnhancedTaskRow`: Individual task display with animations
- `EditTaskView`: Modal task editing interface
- Filter system: All, Active, Completed, Overdue

**State Management:**
```swift
@State private var searchText = ""
@State private var selectedFilter = "All"
@State private var editingTask: Task?
```

### 3. SuggestionView
**File**: `Views/SuggestionView.swift`

**Purpose**: AI-powered task recommendation interface

**Key Features:**
- Card-based suggestion display
- Swipe gestures (accept/dismiss)
- Mood compatibility indicators
- Suggestion progress tracking

**Components:**
- `TaskSuggestionCard`: Interactive suggestion cards
- `QuickActionCard`: Navigation shortcuts
- `AllSuggestionsView`: Comprehensive suggestion list

**User Interactions:**
- Swipe right → Accept suggestion
- Swipe left → Dismiss suggestion
- Tap → View detailed suggestion info

### 4. AddTaskView
**File**: `Views/AddTaskView.swift`

**Purpose**: Task creation with enhanced label system

**Enhanced Features:**
- Integration with LabelManager
- Dynamic label picker
- Mood-responsive UI theming
- Input validation and animations

**Form Sections:**
- Basic details (title, description)
- Properties (category, difficulty, duration)
- Labels (custom and built-in)
- Scheduling (due date, recurrence)

### 5. MoodView (AddMoodView)
**File**: `Views/AddMoodView.swift`

**Purpose**: Daily mood tracking interface

**Features:**
- 1-10 mood scale selection
- Emotion tag selection
- Mood history visualization
- Integration with suggestion engine

### 6. JournalView
**File**: `Views/AddJournalView.swift` & `JournalListView.swift`

**Purpose**: Text-based reflection and journaling

**Features:**
- Rich text input
- Date-based organization
- Search functionality
- Mood correlation display

## Component Library

### TaskSuggestionCard
**File**: `Views/Components/TaskSuggestionCard.swift`

**Purpose**: Interactive suggestion display with rich animations

**Features:**
- Drag gesture handling
- Mood compatibility visualization
- Difficulty indicators
- Category emoji mapping
- Press-to-detail functionality

**Gesture System:**
```swift
.gesture(
    DragGesture()
        .onChanged { /* Update card position */ }
        .onEnded { /* Accept/dismiss based on threshold */ }
)
```

### LabelPickerView
**File**: `Views/Components/LabelPickerView.swift`

**Purpose**: Advanced label selection interface

**Features:**
- Multi-selection capability
- Real-time search
- Category-based organization
- Custom label creation
- Usage-based recommendations

## Data Flow Architecture

### Task Suggestion Flow
```
1. User logs mood → MoodEntry created
2. HomeView detects mood change
3. TaskEngine.getSuggestedTasks() called
4. Algorithm scores all TaskTemplates
5. Top suggestions displayed in UI
6. User interaction tracked in TaskSuggestion
```

### Theme Update Flow
```
1. Mood value changes
2. ColorThemeManager.updateTheme() triggered
3. Theme properties updated
4. UI components automatically re-render
5. Animations applied via @Published properties
```

### Label Management Flow
```
1. User creates/selects labels
2. LabelManager processes changes
3. Usage analytics updated
4. Recommendations recalculated
5. UI reflects new label state
```

## Animation System

### Core Animation Principles
- **Spring Physics**: Natural, responsive animations
- **Micro-interactions**: Subtle feedback for user actions
- **Theme-aware**: Animations adapt to current mood theme
- **Performance-optimized**: Efficient rendering for smooth experience

### Animation Categories

#### 1. Navigation Animations
- Screen transitions with hero animations
- Tab switching with spring physics
- Modal presentations with blur effects

#### 2. Interaction Animations
- Button press feedback
- Card swipe gestures
- Task completion celebrations
- Loading state indicators

#### 3. Data-driven Animations
- Mood value changes
- Theme transitions
- Progress indicators
- Real-time updates

### Implementation Example
```swift
.animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentCardIndex)
.scaleEffect(isPressed ? 0.98 : 1.0)
.animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPressed)
```

## Performance Considerations

### Core Data Optimization
- Efficient fetch requests with predicates
- Lazy loading for large datasets
- Background context for heavy operations
- Relationship optimization

### UI Performance
- Lazy loading for lists
- Efficient recomputation with @Published
- Minimal view hierarchy depth
- Strategic use of PreferenceKey for complex layouts

### Memory Management
- Proper @StateObject vs @ObservedObject usage
- Singleton pattern for managers
- Weak references in closures
- Resource cleanup in onDisappear

## CloudKit Integration

### Sync Strategy
- Automatic background sync
- Conflict resolution with timestamps
- Incremental updates
- Offline capability with local caching

### Data Privacy
- User-controlled sync preferences
- Local encryption for sensitive data
- Minimal cloud data footprint
- GDPR compliance considerations

## Testing Strategy

### Unit Testing
- Business logic in managers
- Algorithm accuracy verification
- Data model validation
- Edge case handling

### UI Testing
- Navigation flow verification
- Animation completion testing
- Accessibility compliance
- Performance benchmarking

### Integration Testing
- Core Data + CloudKit sync
- Cross-screen data consistency
- Theme system integration
- Suggestion algorithm end-to-end

## Future Enhancements

### Planned Features
1. **Advanced Analytics**: Mood patterns and productivity correlations
2. **Social Features**: Shared task templates and challenges
3. **Notification System**: Smart reminders based on mood and time
4. **Widget Support**: iOS home screen widgets for quick actions
5. **Machine Learning**: Enhanced suggestion accuracy with on-device ML

### Technical Debt
1. **Code Documentation**: Comprehensive inline documentation
2. **Error Handling**: Robust error recovery mechanisms
3. **Localization**: Multi-language support preparation
4. **Accessibility**: VoiceOver and accessibility improvements

## Conclusion

DoMotive represents a sophisticated iOS application that seamlessly blends emotional intelligence with productivity management. The architecture prioritizes user experience through responsive design, intelligent algorithms, and delightful animations while maintaining robust data management and sync capabilities.

The modular design allows for easy feature expansion and maintenance, while the mood-based suggestion engine provides a unique value proposition that differentiates DoMotive from traditional task management applications.