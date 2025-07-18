//
//  JournalListView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

// JournalListView.swift
import SwiftUI
import CoreData

struct JournalListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntry.date, ascending: false)],
        animation: .default)
    private var journals: FetchedResults<JournalEntry>

    @State private var showingAddJournal = false

    var body: some View {
        NavigationView {
            List {
                ForEach(journals) { journal in
                    VStack(alignment: .leading) {
                        Text(journal.text ?? "")
                        if let date = journal.date {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddJournal = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddJournal) {
                AddJournalView()
            }
        }
    }
}
