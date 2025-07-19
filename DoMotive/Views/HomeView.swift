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

    // Fetch today’s mood (if any)
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.date, ascending: false)],
        predicate: NSPredicate(format: "date >= %@", Calendar.current.startOfDay(for: Date()) as NSDate),
        animation: .default
    ) private var todayMood: FetchedResults<MoodEntry>

    // Fetch tasks
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)],
        predicate: NSPredicate(format: "isCompleted == NO"),
        animation: .default
    ) private var tasks: FetchedResults<Task>

    // Local state for quick mood entry
    @State private var showMoodSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // --- App Greeting ---
                    VStack(alignment: .leading, spacing: 4) {
                        Text("DoMotive")
                            .font(.largeTitle).bold()
                        Text(Date(), style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 4)

                    // --- Mood Log Section ---
                    moodSection

                    // --- Quick Actions ---
                    quickActions

                    // --- Suggested Tasks For Mood ---
                    suggestedTasksSection

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Mood Section
private extension HomeView {
    var moodSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("How do you feel today?")
                    .font(.headline)
                Spacer()
                Button {
                    showMoodSheet = true
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
                .accessibilityLabel("Add Mood Entry")
            }

            if let mood = todayMood.first {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        MoodEmojiView(value: mood.moodValue)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mood.moodLabel ?? "Unknown")
                                .font(.headline)
                                .fontWeight(.medium)
                            Text("Level \(mood.moodValue)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if !parseTags(mood.tags).isEmpty {
                        HStack {
                            ForEach(parseTags(mood.tags), id: \.self) { tag in
                                Text(tag)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color(.systemBlue).opacity(0.15)))
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            } else {
                Text("Tap '+' to log your mood").foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showMoodSheet) {
            AddMoodView()
                .environment(\.managedObjectContext, viewContext)
        }
    }
}

// MARK: - Quick Actions
private extension HomeView {
    var quickActions: some View {
        HStack(spacing: 18) {
            NavigationLink(destination: AddTaskView()) {
                actionButton(icon: "plus.circle", label: "Add Task", color: .accentColor)
            }
            NavigationLink(destination: AddJournalView()) {
                actionButton(icon: "pencil.and.outline", label: "Journal", color: .purple)
            }
            NavigationLink(destination: PlanDayView()) {
                actionButton(icon: "calendar", label: "Plan Day", color: .green)
            }
        }
    }

    func actionButton(icon: String, label: String, color: Color) -> some View {
        VStack {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.white)
                .padding()
                .background(Circle().fill(color))
            Text(label)
                .font(.caption)
                .foregroundColor(.primary)
        }
        .frame(width: 90)
        .padding(.vertical, 7)
    }
}

// MARK: - Suggested Tasks Section
private extension HomeView {
    var suggestedTasksSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Suggested for your mood")
                .font(.headline)
            if let todayMood = todayMood.first, let moodTag = todayMood.tags?.components(separatedBy: ",").first {
                let matchTasks = tasks.filter {
                    $0.moodTag?.localizedCaseInsensitiveContains(moodTag.trimmingCharacters(in: .whitespaces)) ?? false
                }
                if matchTasks.isEmpty {
                    Text("No tasks matched your mood. Enjoy your day!")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(matchTasks.prefix(3)) { task in
                        HomeTaskCard(task: task)
                    }
                }
            } else {
                ForEach(tasks.prefix(3)) { task in
                    HomeTaskCard(task: task)
                }
            }
        }
    }
}

// MARK: - Helper Components

struct MoodEmojiView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var moodManager = MoodManager.shared
    var value: Int16
    
    var body: some View {
        Text(moodManager.getMoodEmoji(for: value, context: viewContext))
    }
}

struct HomeTaskCard: View {
    @ObservedObject var task: Task
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title ?? "Untitled")
                    .font(.subheadline).bold()
                    .foregroundColor(.primary)
                if let due = task.dueDate {
                    Text(due, style: .time)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if let mood = task.moodTag, !mood.isEmpty {
                    Text("Mood: \(mood.capitalized)").font(.caption2).foregroundColor(.blue)
                }
            }
            Spacer()
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? .green : .gray)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
        .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}

