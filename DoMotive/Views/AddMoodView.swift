//
//  AddMoodView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

// AddMoodView.swift
import SwiftUI

struct AddMoodView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentation

    @State private var moodValue: Double = 5
    @State private var tags: String = ""

    var body: some View {
        NavigationView {
            Form {
                VStack {
                    Text("Mood: \(Int(moodValue))")
                    Slider(value: $moodValue, in: 1...10, step: 1)
                }
                TextField("Tags (comma separated)", text: $tags)
            }
            .navigationTitle("New Mood")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { addMood() }
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
        newMood.moodValue = Int16(moodValue)
        newMood.tags = tags
        newMood.date = Date()

        try? viewContext.save()
        presentation.wrappedValue.dismiss()
    }
}
