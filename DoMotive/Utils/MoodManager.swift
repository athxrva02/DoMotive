//
//  MoodManager.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import Foundation
import CoreData

class MoodManager: ObservableObject {
    static let shared = MoodManager()
    
    private let defaultMoodLabels: [Int16: (label: String, emoji: String)] = [
        1: ("Terrible", "😭"),
        2: ("Very Bad", "😢"),
        3: ("Bad", "😔"),
        4: ("Poor", "😞"),
        5: ("Okay", "😐"),
        6: ("Good", "🙂"),
        7: ("Great", "😊"),
        8: ("Excellent", "😃"),
        9: ("Amazing", "😄"),
        10: ("Euphoric", "🤩")
    ]
    
    private init() {}
    
    func getMoodLabel(for value: Int16, context: NSManagedObjectContext) -> String {
        let request: NSFetchRequest<CustomMoodLabel> = CustomMoodLabel.fetchRequest()
        request.predicate = NSPredicate(format: "moodValue == %d", value)
        request.fetchLimit = 1
        
        do {
            let customLabels = try context.fetch(request)
            if let customLabel = customLabels.first {
                return customLabel.label ?? defaultMoodLabels[value]?.label ?? "Unknown"
            }
        } catch {
            print("Error fetching custom mood label: \(error)")
        }
        
        return defaultMoodLabels[value]?.label ?? "Unknown"
    }
    
    func getMoodEmoji(for value: Int16, context: NSManagedObjectContext) -> String {
        let request: NSFetchRequest<CustomMoodLabel> = CustomMoodLabel.fetchRequest()
        request.predicate = NSPredicate(format: "moodValue == %d", value)
        request.fetchLimit = 1
        
        do {
            let customLabels = try context.fetch(request)
            if let customLabel = customLabels.first {
                return customLabel.emoji ?? defaultMoodLabels[value]?.emoji ?? "❓"
            }
        } catch {
            print("Error fetching custom mood emoji: \(error)")
        }
        
        return defaultMoodLabels[value]?.emoji ?? "❓"
    }
    
    func saveCustomMoodLabel(value: Int16, label: String, emoji: String, context: NSManagedObjectContext) {
        let request: NSFetchRequest<CustomMoodLabel> = CustomMoodLabel.fetchRequest()
        request.predicate = NSPredicate(format: "moodValue == %d", value)
        
        do {
            let existingLabels = try context.fetch(request)
            let customLabel = existingLabels.first ?? CustomMoodLabel(context: context)
            
            customLabel.id = customLabel.id ?? UUID()
            customLabel.moodValue = value
            customLabel.label = label
            customLabel.emoji = emoji
            customLabel.createdDate = Date()
            
            try context.save()
        } catch {
            print("Error saving custom mood label: \(error)")
        }
    }
    
    func getDefaultLabel(for value: Int16) -> String {
        return defaultMoodLabels[value]?.label ?? "Unknown"
    }
    
    func getDefaultEmoji(for value: Int16) -> String {
        return defaultMoodLabels[value]?.emoji ?? "❓"
    }
}

// MARK: - Utility Functions
func parseTags(_ str: String?) -> [String] {
    str?.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
}