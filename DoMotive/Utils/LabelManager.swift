//
//  LabelManager.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import Foundation
import CoreData
import SwiftUI

class LabelManager: ObservableObject {
    static let shared = LabelManager()
    
    @Published var availableLabels: [TaskLabel] = []
    
    private let builtInLabels: [(name: String, category: String, colorHex: String, emoji: String)] = [
        // Energy Level Labels
        ("High Energy", "Energy", "#FF6B6B", "⚡️"),
        ("Medium Energy", "Energy", "#4ECDC4", "🔋"),
        ("Low Energy", "Energy", "#95A5A6", "😴"),
        
        // Location Labels
        ("Home", "Location", "#3498DB", "🏠"),
        ("Office", "Location", "#9B59B6", "🏢"),
        ("Outdoors", "Location", "#27AE60", "🌳"),
        ("Anywhere", "Location", "#F39C12", "📍"),
        
        // Type Labels
        ("Creative", "Type", "#E74C3C", "🎨"),
        ("Physical", "Type", "#E67E22", "💪"),
        ("Mental", "Type", "#8E44AD", "🧠"),
        ("Social", "Type", "#1ABC9C", "👥"),
        ("Administrative", "Type", "#34495E", "📋"),
        
        // Duration Labels
        ("Quick", "Duration", "#2ECC71", "⚡️"),
        ("Medium", "Duration", "#F1C40F", "⏰"),
        ("Long", "Duration", "#E74C3C", "⏳"),
        
        // Category Labels
        ("Cleaning", "Category", "#3498DB", "🧹"),
        ("Exercise", "Category", "#E74C3C", "🏃‍♂️"),
        ("Self Care", "Category", "#9B59B6", "🧘‍♀️"),
        ("Learning", "Category", "#27AE60", "📚"),
        ("Work", "Category", "#34495E", "💼")
    ]
    
    private init() {}
    
    // MARK: - Label Management
    
    func loadLabels(context: NSManagedObjectContext) {
        initializeBuiltInLabels(context: context)
        fetchAllLabels(context: context)
    }
    
    func createLabel(name: String, category: String, colorHex: String, emoji: String, context: NSManagedObjectContext) -> TaskLabel? {
        guard !name.isEmpty else { return nil }
        
        let label = TaskLabel(context: context)
        label.id = UUID()
        label.name = name
        label.category = category
        label.colorHex = colorHex
        label.emoji = emoji
        label.isBuiltIn = false
        label.usageCount = 0
        label.createdDate = Date()
        
        do {
            try context.save()
            fetchAllLabels(context: context)
            return label
        } catch {
            print("Error creating label: \(error)")
            return nil
        }
    }
    
    func updateLabel(_ label: TaskLabel, name: String, category: String, colorHex: String, emoji: String, context: NSManagedObjectContext) {
        label.name = name
        label.category = category
        label.colorHex = colorHex
        label.emoji = emoji
        
        do {
            try context.save()
            fetchAllLabels(context: context)
        } catch {
            print("Error updating label: \(error)")
        }
    }
    
    func deleteLabel(_ label: TaskLabel, context: NSManagedObjectContext) {
        guard !label.isBuiltIn else { return }
        
        context.delete(label)
        
        do {
            try context.save()
            fetchAllLabels(context: context)
        } catch {
            print("Error deleting label: \(error)")
        }
    }
    
    func incrementUsage(for label: TaskLabel, context: NSManagedObjectContext) {
        label.usageCount += 1
        label.lastUsedDate = Date()
        
        do {
            try context.save()
        } catch {
            print("Error updating label usage: \(error)")
        }
    }
    
    // MARK: - Label Retrieval
    
    func getLabels(by category: String, context: NSManagedObjectContext) -> [TaskLabel] {
        let request: NSFetchRequest<TaskLabel> = TaskLabel.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskLabel.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \TaskLabel.name, ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching labels by category: \(error)")
            return []
        }
    }
    
    func getMostUsedLabels(limit: Int = 10, context: NSManagedObjectContext) -> [TaskLabel] {
        let request: NSFetchRequest<TaskLabel> = TaskLabel.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TaskLabel.usageCount, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching most used labels: \(error)")
            return []
        }
    }
    
    func searchLabels(query: String, context: NSManagedObjectContext) -> [TaskLabel] {
        guard !query.isEmpty else { return availableLabels }
        
        let request: NSFetchRequest<TaskLabel> = TaskLabel.fetchRequest()
        request.predicate = NSPredicate(format: "name CONTAINS[cd] %@", query)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskLabel.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \TaskLabel.name, ascending: true)
        ]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error searching labels: \(error)")
            return []
        }
    }
    
    func getLabelsFromString(_ labelString: String?, context: NSManagedObjectContext) -> [TaskLabel] {
        guard let labelString = labelString, !labelString.isEmpty else { return [] }
        
        let labelNames = labelString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        let request: NSFetchRequest<TaskLabel> = TaskLabel.fetchRequest()
        request.predicate = NSPredicate(format: "name IN %@", labelNames)
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching labels from string: \(error)")
            return []
        }
    }
    
    // MARK: - Label String Conversion
    
    func labelsToString(_ labels: [TaskLabel]) -> String {
        return labels.compactMap { $0.name }.joined(separator: ", ")
    }
    
    func parseLabelString(_ labelString: String?) -> [String] {
        guard let labelString = labelString, !labelString.isEmpty else { return [] }
        return labelString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    // MARK: - Color and Display Helpers
    
    func getColor(for label: TaskLabel) -> Color {
        Color(hex: label.colorHex ?? "#3498DB") ?? .blue
    }
    
    func getRandomColor() -> String {
        let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F"]
        return colors.randomElement() ?? "#3498DB"
    }
    
    func getAllCategories(context: NSManagedObjectContext) -> [String] {
        let request: NSFetchRequest<TaskLabel> = TaskLabel.fetchRequest()
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["category"]
        request.returnsDistinctResults = true
        
        do {
            let results = try context.fetch(request) as? [[String: Any]] ?? []
            return results.compactMap { $0["category"] as? String }.sorted()
        } catch {
            print("Error fetching categories: \(error)")
            return []
        }
    }
    
    // MARK: - Private Methods
    
    private func initializeBuiltInLabels(context: NSManagedObjectContext) {
        let request: NSFetchRequest<TaskLabel> = TaskLabel.fetchRequest()
        request.predicate = NSPredicate(format: "isBuiltIn == YES")
        
        do {
            let existingLabels = try context.fetch(request)
            if existingLabels.isEmpty {
                for builtInLabel in builtInLabels {
                    let label = TaskLabel(context: context)
                    label.id = UUID()
                    label.name = builtInLabel.name
                    label.category = builtInLabel.category
                    label.colorHex = builtInLabel.colorHex
                    label.emoji = builtInLabel.emoji
                    label.isBuiltIn = true
                    label.usageCount = 0
                    label.createdDate = Date()
                }
                try context.save()
            }
        } catch {
            print("Error initializing built-in labels: \(error)")
        }
    }
    
    private func fetchAllLabels(context: NSManagedObjectContext) {
        let request: NSFetchRequest<TaskLabel> = TaskLabel.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \TaskLabel.category, ascending: true),
            NSSortDescriptor(keyPath: \TaskLabel.usageCount, ascending: false),
            NSSortDescriptor(keyPath: \TaskLabel.name, ascending: true)
        ]
        
        do {
            availableLabels = try context.fetch(request)
        } catch {
            print("Error fetching all labels: \(error)")
            availableLabels = []
        }
    }
}

// MARK: - Color Extension
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}