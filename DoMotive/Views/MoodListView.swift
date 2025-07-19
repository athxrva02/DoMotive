//
//  MoodListView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import SwiftUI
import CoreData

struct MoodListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var moodManager = MoodManager.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.date, ascending: false)],
        animation: .default)
    private var moods: FetchedResults<MoodEntry>

    @State private var showingAddMood = false

    var body: some View {
        NavigationView {
            List {
                ForEach(moods) { mood in
                    MoodRowView(mood: mood)
                        .padding(.vertical, 4)
                }
                .onDelete(perform: deleteMoods)
            }
            .navigationTitle("Mood History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddMood = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddMood) {
                AddMoodView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    private func deleteMoods(offsets: IndexSet) {
        withAnimation {
            offsets.map { moods[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting mood: \(error)")
            }
        }
    }
}

struct MoodRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var moodManager = MoodManager.shared
    let mood: MoodEntry
    
    var body: some View {
        HStack {
            Text(moodManager.getMoodEmoji(for: mood.moodValue, context: viewContext))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(mood.moodLabel ?? moodManager.getMoodLabel(for: mood.moodValue, context: viewContext))
                        .font(.headline)
                    Spacer()
                    Text("Level \(mood.moodValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.gray.opacity(0.2)))
                }
                
                if let tags = mood.tags, !tags.isEmpty {
                    HStack {
                        ForEach(parseTags(tags), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.blue.opacity(0.15)))
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                if let date = mood.date {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

