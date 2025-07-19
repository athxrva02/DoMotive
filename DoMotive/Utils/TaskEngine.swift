//
//  TaskEngine.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import Foundation
import CoreData

class TaskEngine: ObservableObject {
    static let shared = TaskEngine()
    
    private init() {}
    
    // MARK: - Task Suggestion Algorithm
    
    func getSuggestedTasks(for moodValue: Int16, 
                          timeOfDay: TimeOfDay = .current,
                          maxSuggestions: Int = 5,
                          context: NSManagedObjectContext) -> [TaskTemplate] {
        
        let templates = fetchTaskTemplates(context: context)
        let filteredTemplates = templates.filter { template in
            return isSuitableForMood(template: template, moodValue: moodValue, timeOfDay: timeOfDay)
        }
        
        let scoredTemplates = filteredTemplates.map { template in
            (template: template, score: calculateSuitabilityScore(template: template, 
                                                                 moodValue: moodValue, 
                                                                 timeOfDay: timeOfDay,
                                                                 context: context))
        }
        
        return scoredTemplates
            .sorted { $0.score > $1.score }
            .prefix(maxSuggestions)
            .map { $0.template }
    }
    
    // MARK: - Suitability Scoring
    
    private func calculateSuitabilityScore(template: TaskTemplate, 
                                         moodValue: Int16, 
                                         timeOfDay: TimeOfDay,
                                         context: NSManagedObjectContext) -> Double {
        var score: Double = 0
        
        // Base mood compatibility (40% weight)
        score += moodCompatibilityScore(template: template, moodValue: moodValue) * 0.4
        
        // Time of day factor (20% weight)
        score += timeOfDayScore(template: template, timeOfDay: timeOfDay) * 0.2
        
        // User history factor (25% weight)
        score += userHistoryScore(template: template, moodValue: moodValue, context: context) * 0.25
        
        // Energy level factor (15% weight)
        score += energyLevelScore(template: template, moodValue: moodValue) * 0.15
        
        return score
    }
    
    private func moodCompatibilityScore(template: TaskTemplate, moodValue: Int16) -> Double {
        guard let moodRange = template.moodRange else { return 0.5 }
        
        let ranges = moodRange.components(separatedBy: ",")
        for range in ranges {
            if let parsedRange = parseMoodRange(range.trimmingCharacters(in: .whitespaces)) {
                if moodValue >= parsedRange.min && moodValue <= parsedRange.max {
                    let center = Double(parsedRange.min + parsedRange.max) / 2
                    let distance = abs(Double(moodValue) - center)
                    let maxDistance = Double(parsedRange.max - parsedRange.min) / 2
                    return 1.0 - (distance / maxDistance)
                }
            }
        }
        
        return 0.0
    }
    
    private func timeOfDayScore(template: TaskTemplate, timeOfDay: TimeOfDay) -> Double {
        guard let category = template.category else { return 0.7 }
        
        switch (category.lowercased(), timeOfDay) {
        case ("exercise", .morning), ("cleaning", .morning):
            return 1.0
        case ("creative", .morning), ("creative", .afternoon):
            return 0.9
        case ("admin", .afternoon):
            return 1.0
        case ("selfcare", .evening):
            return 1.0
        case ("social", .evening):
            return 0.9
        default:
            return 0.7
        }
    }
    
    private func userHistoryScore(template: TaskTemplate, moodValue: Int16, context: NSManagedObjectContext) -> Double {
        let request: NSFetchRequest<TaskSuggestion> = NSFetchRequest<TaskSuggestion>(entityName: "TaskSuggestion")
        request.predicate = NSPredicate(format: "taskTemplateId == %@ AND moodValue >= %d AND moodValue <= %d",
                                      template.id! as CVarArg, moodValue - 1, moodValue + 1)
        
        do {
            let suggestions = try context.fetch(request)
            if suggestions.isEmpty { return 0.5 }
            
            let acceptedCount = suggestions.filter { $0.wasAccepted }.count
            return Double(acceptedCount) / Double(suggestions.count)
        } catch {
            return 0.5
        }
    }
    
    private func energyLevelScore(template: TaskTemplate, moodValue: Int16) -> Double {
        let energyLevel = getEnergyLevel(for: moodValue)
        let taskDifficulty = template.difficulty
        
        switch (energyLevel, taskDifficulty) {
        case (.low, 1...2):
            return 1.0
        case (.medium, 2...4):
            return 1.0
        case (.high, 3...5):
            return 1.0
        case (.low, 3...5):
            return 0.3
        case (.high, 1...2):
            return 0.6
        default:
            return 0.5
        }
    }
    
    // MARK: - Helper Functions
    
    private func isSuitableForMood(template: TaskTemplate, moodValue: Int16, timeOfDay: TimeOfDay) -> Bool {
        guard let moodRange = template.moodRange else { return true }
        
        let ranges = moodRange.components(separatedBy: ",")
        for range in ranges {
            if let parsedRange = parseMoodRange(range.trimmingCharacters(in: .whitespaces)) {
                if moodValue >= parsedRange.min && moodValue <= parsedRange.max {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func parseMoodRange(_ range: String) -> (min: Int16, max: Int16)? {
        if range.contains("-") {
            let components = range.components(separatedBy: "-")
            guard components.count == 2,
                  let min = Int16(components[0].trimmingCharacters(in: .whitespaces)),
                  let max = Int16(components[1].trimmingCharacters(in: .whitespaces)) else {
                return nil
            }
            return (min: min, max: max)
        } else if let value = Int16(range) {
            return (min: value, max: value)
        }
        return nil
    }
    
    private func getEnergyLevel(for moodValue: Int16) -> EnergyLevel {
        switch moodValue {
        case 1...3:
            return .low
        case 4...6:
            return .medium
        case 7...10:
            return .high
        default:
            return .medium
        }
    }
    
    private func fetchTaskTemplates(context: NSManagedObjectContext) -> [TaskTemplate] {
        let request: NSFetchRequest<TaskTemplate> = TaskTemplate.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskTemplate.title, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching task templates: \(error)")
            return []
        }
    }
    
    // MARK: - Task Suggestion Tracking
    
    func recordSuggestion(template: TaskTemplate, moodValue: Int16, context: NSManagedObjectContext) {
        let suggestion = TaskSuggestion(context: context)
        suggestion.id = UUID()
        suggestion.taskTemplateId = template.id
        suggestion.moodValue = moodValue
        suggestion.suggestedDate = Date()
        suggestion.timeOfDay = TimeOfDay.current.rawValue
        suggestion.wasAccepted = false
        
        try? context.save()
    }
    
    func recordAcceptance(suggestionId: UUID, context: NSManagedObjectContext) {
        let request: NSFetchRequest<TaskSuggestion> = NSFetchRequest<TaskSuggestion>(entityName: "TaskSuggestion")
        request.predicate = NSPredicate(format: "id == %@", suggestionId as CVarArg)
        
        do {
            let suggestions = try context.fetch(request)
            if let suggestion = suggestions.first {
                suggestion.wasAccepted = true
                suggestion.responseDate = Date()
                try context.save()
            }
        } catch {
            print("Error recording suggestion acceptance: \(error)")
        }
    }
    
    // MARK: - Create Task from Template
    
    func createTask(from template: TaskTemplate, context: NSManagedObjectContext) -> Task {
        let task = Task(context: context)
        task.id = UUID()
        task.title = template.title
        task.details = getTemplateDescription(template)
        task.category = template.category
        task.difficulty = template.difficulty
        task.estimatedDuration = template.estimatedDuration
        task.labels = template.defaultLabels
        task.isCompleted = false
        task.createdDate = Date()
        task.dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        
        return task
    }
}

// MARK: - Supporting Enums

enum TimeOfDay: String, CaseIterable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
    
    static var current: TimeOfDay {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<12:
            return .morning
        case 12..<17:
            return .afternoon
        case 17..<22:
            return .evening
        default:
            return .night
        }
    }
}

enum EnergyLevel {
    case low, medium, high
}