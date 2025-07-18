//
//  MoodListView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

// MoodListView.swift
import SwiftUI
import CoreData

struct MoodListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.date, ascending: false)],
        animation: .default)
    private var moods: FetchedResults<MoodEntry>

    @State private var showingAddMood = false

    var body: some View {
        NavigationView {
            List {
                ForEach(moods) { mood in
                    VStack(alignment: .leading) {
                        Text("Mood: \(mood.moodValue)")
                        if let tags = mood.tags {
                            Text("Tags: \(tags)")
                                .font(.caption)
                        }
                        if let date = mood.date {
                            Text(date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Mood Logs")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddMood = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMood) {
                AddMoodView()
            }
        }
    }
}
