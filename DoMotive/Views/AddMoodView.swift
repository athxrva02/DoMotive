//
//  AddMoodView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import SwiftUI
import CoreData

struct AddMoodView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentation
    @StateObject private var moodManager = MoodManager.shared

    @State private var moodValue: Int16 = 5
    @State private var tags: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    DiscreteMoodSlider(selectedValue: $moodValue)
                        .padding(.vertical)
                }
                
                Section("Additional Details") {
                    TextField("Tags (comma separated)", text: $tags)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section {
                    Text("Tags help categorize your mood and can be used to suggest relevant tasks.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Log Your Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { addMood() }
                        .fontWeight(.medium)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentation.wrappedValue.dismiss() }
                }
            }
        }
    }

    private func addMood() {
        let newMood = MoodEntry(context: viewContext)
        newMood.id = UUID()
        newMood.moodValue = moodValue
        newMood.moodLabel = moodManager.getMoodLabel(for: moodValue, context: viewContext)
        newMood.tags = tags.isEmpty ? nil : tags
        newMood.date = Date()

        do {
            try viewContext.save()
            presentation.wrappedValue.dismiss()
        } catch {
            print("Error saving mood: \(error)")
        }
    }
}
