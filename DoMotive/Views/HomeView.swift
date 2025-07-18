//
//  HomeView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

// HomeView.swift
import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)],
        predicate: NSPredicate(format: "isCompleted == NO"),
        animation: .default
    ) private var upcomingTasks: FetchedResults<Task>
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.date, ascending: false)],
        animation: .default
    ) private var moodEntries: FetchedResults<MoodEntry>

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                // App Title
                Text("DoMotive")
                    .font(.largeTitle).bold()
                    .padding(.top)
                
                // Current Mood
                VStack(alignment: .leading) {
                    Text("Today's Mood").font(.headline)
                    if let mood = moodEntries.first {
                        HStack {
                            Text("Value: \(mood.moodValue)")
                            if let tags = mood.tags { Text("(\(tags))").font(.caption) }
                        }
                    } else {
                        Text("No mood entry yet.").font(.subheadline).foregroundColor(.secondary)
                    }
                }
                
                // Task Suggestions (First 3 Incomplete)
                VStack(alignment: .leading) {
                    Text("Today's Tasks")
                        .font(.headline)
                    if upcomingTasks.isEmpty {
                        Text("No tasks scheduled for today!").foregroundColor(.secondary)
                    } else {
                        ForEach(upcomingTasks.prefix(3)) { task in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(task.title ?? "").font(.body)
                                    if let due = task.dueDate {
                                        Text(due.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption).foregroundColor(.secondary)
                                    }
                                    if let mood = task.moodTag {
                                        Text("Mood: \(mood)").font(.caption2)
                                    }
                                }
                                Spacer()
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(task.isCompleted ? .green : .gray)
                            }.padding(.vertical, 4)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitle("Home", displayMode: .inline)
        }
    }
}
