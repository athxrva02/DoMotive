//
//  AddJournalView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

// AddJournalView.swift
import SwiftUI

struct AddJournalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentation

    @State private var text: String = ""

    var body: some View {
        NavigationView {
            Form {
                TextEditor(text: $text)
                    .frame(height: 200)
            }
            .navigationTitle("New Journal")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { addJournal() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentation.wrappedValue.dismiss() }
                }
            }
        }
    }

    private func addJournal() {
        let newJournal = JournalEntry(context: viewContext)
        newJournal.id = UUID()
        newJournal.text = text
        newJournal.date = Date()

        try? viewContext.save()
        presentation.wrappedValue.dismiss()
    }
}
