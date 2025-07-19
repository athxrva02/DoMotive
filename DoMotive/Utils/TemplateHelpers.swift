//
//  TemplateHelpers.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import Foundation
import CoreData

// MARK: - Helper Functions for TaskTemplate
func getTemplateDescription(_ template: TaskTemplate, defaultText: String = "") -> String {
    if let description = template.value(forKey: "taskDescription") as? String {
        return description
    }
    return defaultText
}

func setTemplateDescription(_ template: TaskTemplate, description: String) {
    template.setValue(description, forKey: "taskDescription")
}