# DoMotive Crash Fix - NSInvalidArgumentException

## Problem
DoMotive was crashing with the error:
```
NSInvalidArgumentException: executeFetchRequest:error: A fetch request must have an entity
```

## Root Cause
The crash was caused by Core Data fetch requests using the `.fetchRequest()` class method on entity classes, which wasn't working properly. This commonly happens when:

1. Core Data model isn't properly configured for automatic code generation
2. Entity classes aren't generated with the `fetchRequest()` method
3. There's a mismatch between the model and generated classes

## Solution Applied

### Fixed Files:
1. **MoodManager.swift** - Fixed 3 fetch requests
2. **TaskEngine.swift** - Fixed 3 fetch requests  
3. **TaskTemplateManager.swift** - Fixed 3 fetch requests
4. **LabelManager.swift** - Fixed 7 fetch requests

### Change Pattern:
**Before (causing crash):**
```swift
let request: NSFetchRequest<TaskLabel> = TaskLabel.fetchRequest()
```

**After (fixed):**
```swift
let request: NSFetchRequest<TaskLabel> = NSFetchRequest<TaskLabel>(entityName: "TaskLabel")
```

### Entity Names Used:
- `"TaskLabel"` - For task labels and categories
- `"TaskTemplate"` - For task suggestion templates  
- `"TaskSuggestion"` - For tracking suggestion interactions
- `"CustomMoodLabel"` - For custom mood labels/emojis

## Files Modified:
- `/Utils/MoodManager.swift` ✅
- `/Utils/TaskEngine.swift` ✅  
- `/Utils/TaskTemplateManager.swift` ✅
- `/Utils/LabelManager.swift` ✅

## Core Data Model Entities:
The following entities are properly defined in the model:
- ✅ Task
- ✅ TaskTemplate  
- ✅ TaskLabel
- ✅ TaskSuggestion
- ✅ MoodEntry
- ✅ JournalEntry
- ✅ CustomMoodLabel
- ✅ Item (legacy)

## Testing Recommendations:
1. **Clean Build** - Clean and rebuild the project
2. **Test Core Functionality:**
   - Mood logging
   - Task creation
   - Task suggestions
   - Label management
3. **Verify Data Persistence** - Ensure data saves and loads correctly
4. **Check CloudKit Sync** - Verify data syncs if using CloudKit

## Prevention:
To prevent this issue in the future:
1. Always use explicit entity names in fetch requests
2. Ensure Core Data model has proper code generation settings
3. Test fetch requests early in development
4. Use consistent patterns across all managers

The app should now launch and function properly without the fetch request crash.