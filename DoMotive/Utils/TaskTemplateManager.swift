//
//  TaskTemplateManager.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import Foundation
import CoreData

class TaskTemplateManager: ObservableObject {
    static let shared = TaskTemplateManager()
    
    private let builtInTemplates: [(title: String, description: String, category: String, difficulty: Int16, duration: Int32, moodRange: String, labels: String)] = [
        // Low Mood Tasks (1-3)
        ("Tidy Desk", "Organize and clean your workspace", "Cleaning", 1, 15, "1-4", "Low Energy, Home, Quick"),
        ("Listen to Music", "Play your favorite calming playlist", "Self Care", 1, 30, "1-5", "Low Energy, Anywhere, Self Care"),
        ("Water Plants", "Check and water your indoor plants", "Household", 1, 10, "1-6", "Low Energy, Home, Quick"),
        ("Make Tea", "Brew a warm, comforting cup of tea", "Self Care", 1, 10, "1-5", "Low Energy, Home, Quick"),
        ("Gentle Stretching", "Do light stretches or yoga", "Exercise", 2, 20, "1-6", "Low Energy, Home, Physical"),
        
        // Medium Mood Tasks (4-6)
        ("Grocery Shopping", "Buy weekly groceries and essentials", "Household", 3, 60, "4-7", "Medium Energy, Outdoors, Administrative"),
        ("Respond to Emails", "Clear your email inbox", "Work", 3, 45, "4-8", "Medium Energy, Anywhere, Administrative"),
        ("Laundry", "Wash, dry, and fold clothes", "Household", 2, 90, "3-7", "Medium Energy, Home, Household"),
        ("Read a Book", "Read a chapter or two", "Learning", 2, 30, "3-8", "Medium Energy, Anywhere, Learning"),
        ("Meal Prep", "Prepare meals for tomorrow", "Household", 3, 45, "4-7", "Medium Energy, Home, Household"),
        
        // High Mood Tasks (7-10)
        ("Deep Clean Room", "Thoroughly clean and organize bedroom", "Cleaning", 4, 120, "6-10", "High Energy, Home, Physical"),
        ("Go for a Run", "Take an energizing outdoor run", "Exercise", 4, 45, "7-10", "High Energy, Outdoors, Physical"),
        ("Creative Project", "Work on art, music, or writing", "Creative", 3, 90, "6-10", "High Energy, Anywhere, Creative"),
        ("Learn New Skill", "Practice a new language or skill", "Learning", 4, 60, "7-10", "High Energy, Anywhere, Learning"),
        ("Social Activity", "Call friends or plan social event", "Social", 3, 60, "7-10", "High Energy, Anywhere, Social"),
        
        // Flexible Tasks (Any Mood)
        ("Meditation", "Practice mindfulness meditation", "Self Care", 2, 20, "1-10", "Any Energy, Anywhere, Self Care"),
        ("Journal Writing", "Write thoughts and reflections", "Self Care", 2, 25, "1-10", "Any Energy, Anywhere, Self Care"),
        ("Quick Walk", "Take a short walk around the block", "Exercise", 2, 20, "3-10", "Any Energy, Outdoors, Physical"),
        ("Organize Photos", "Sort and organize digital photos", "Administrative", 2, 45, "3-8", "Medium Energy, Anywhere, Administrative"),
        ("Plan Tomorrow", "Review and plan next day's schedule", "Administrative", 3, 30, "4-9", "Medium Energy, Anywhere, Administrative")
    ]
    
    private init() {}
    
    func initializeBuiltInTemplates(context: NSManagedObjectContext) {
        // Check if templates already exist
        let request: NSFetchRequest<TaskTemplate> = TaskTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "isBuiltIn == YES")
        
        do {
            let existingTemplates = try context.fetch(request)
            if existingTemplates.isEmpty {
                // Create built-in templates
                for template in builtInTemplates {
                    let taskTemplate = TaskTemplate(context: context)
                    taskTemplate.id = UUID()
                    taskTemplate.title = template.title
                    setTemplateDescription(taskTemplate, description: template.description)
                    taskTemplate.category = template.category
                    taskTemplate.difficulty = template.difficulty
                    taskTemplate.estimatedDuration = template.duration
                    taskTemplate.moodRange = template.moodRange
                    taskTemplate.defaultLabels = template.labels
                    taskTemplate.isBuiltIn = true
                    taskTemplate.createdDate = Date()
                }
                
                try context.save()
                print("Initialized \(builtInTemplates.count) built-in task templates")
            }
        } catch {
            print("Error initializing built-in templates: \(error)")
        }
    }
    
    func createCustomTemplate(
        title: String,
        description: String,
        category: String,
        difficulty: Int16,
        duration: Int32,
        moodRange: String,
        labels: String,
        context: NSManagedObjectContext
    ) -> TaskTemplate? {
        
        let template = TaskTemplate(context: context)
        template.id = UUID()
        template.title = title
        setTemplateDescription(template, description: description)
        template.category = category
        template.difficulty = difficulty
        template.estimatedDuration = duration
        template.moodRange = moodRange
        template.defaultLabels = labels
        template.isBuiltIn = false
        template.createdDate = Date()
        
        do {
            try context.save()
            return template
        } catch {
            print("Error creating custom template: \(error)")
            return nil
        }
    }
    
    func getAllTemplates(context: NSManagedObjectContext) -> [TaskTemplate] {
        let request: NSFetchRequest<TaskTemplate> = TaskTemplate.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskTemplate.isBuiltIn, ascending: false),
            NSSortDescriptor(keyPath: \TaskTemplate.category, ascending: true),
            NSSortDescriptor(keyPath: \TaskTemplate.title, ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching templates: \(error)")
            return []
        }
    }
    
    func getTemplatesByCategory(_ category: String, context: NSManagedObjectContext) -> [TaskTemplate] {
        let request: NSFetchRequest<TaskTemplate> = TaskTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskTemplate.title, ascending: true)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching templates by category: \(error)")
            return []
        }
    }
    
    func deleteTemplate(_ template: TaskTemplate, context: NSManagedObjectContext) {
        guard !template.isBuiltIn else {
            print("Cannot delete built-in template")
            return
        }
        
        context.delete(template)
        
        do {
            try context.save()
        } catch {
            print("Error deleting template: \(error)")
        }
    }
}