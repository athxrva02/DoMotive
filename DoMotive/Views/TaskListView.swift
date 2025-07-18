//
//  TaskListView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

// TaskListView.swift
import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)],
        animation: .default)
    private var tasks: FetchedResults<Task>

    @State private var showingAddTask = false

    var body: some View {
        NavigationView {
            List {
                ForEach(tasks) { task in
                    TaskRow(task: task)
                }
                .onDelete(perform: deleteTasks)
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingAddTask = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
        }
    }

    private func deleteTasks(offsets: IndexSet) {
        for index in offsets {
            viewContext.delete(tasks[index])
        }
        try? viewContext.save()
    }
}

struct TaskRow: View {
    @ObservedObject var task: Task
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title ?? "")
                    .font(.headline)
                if let due = task.dueDate {
                    Text("Due: \(due.formatted(date: .abbreviated, time: .shortened))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let mood = task.moodTag {
                    Text("Mood: \(mood)").font(.caption)
                }
            }
            Spacer()
            Button {
                task.isCompleted.toggle()
                try? viewContext.save()
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
            }
        }
        .padding(.vertical, 4)
    }
}


