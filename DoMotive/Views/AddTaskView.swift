//
//  AddTaskView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

// AddTaskView.swift
import SwiftUI

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentation

    @State private var title = ""
    @State private var details = ""
    @State private var dueDate = Date()
    @State private var moodTag = ""
    @State private var recurrenceRule = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Title", text: $title)
                TextField("Details", text: $details)
                DatePicker("Due Date", selection: $dueDate)
                TextField("Mood Tag", text: $moodTag)
                TextField("Recurrence (e.g. daily)", text: $recurrenceRule)
            }
            .navigationTitle("New Task")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { addTask() }
                        .disabled(title.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentation.wrappedValue.dismiss() }
                }
            }
        }
    }

    private func addTask() {
        let newTask = Task(context: viewContext)
        newTask.id = UUID()
        newTask.title = title
        newTask.details = details
        newTask.dueDate = dueDate
        newTask.moodTag = moodTag
        newTask.isCompleted = false
        newTask.recurrenceRule = recurrenceRule

        try? viewContext.save()
        presentation.wrappedValue.dismiss()
    }
}
