//
//  TaskListView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import SwiftUI
import CoreData

struct TaskListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var labelManager = LabelManager.shared
    
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Task.isCompleted, ascending: true),
            NSSortDescriptor(keyPath: \Task.dueDate, ascending: true)
        ],
        animation: .default
    ) private var allTasks: FetchedResults<Task>

    @State private var showingAddTask = false
    @State private var showingCompletedTasks = false
    @State private var editingTask: Task?
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    
    private let filterOptions = ["All", "Active", "Completed", "Overdue"]
    
    private var filteredTasks: [Task] {
        var tasks = Array(allTasks)
        
        // Apply search filter
        if !searchText.isEmpty {
            tasks = tasks.filter { task in
                (task.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (task.details?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (task.category?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply status filter
        switch selectedFilter {
        case "All":
            fallthrough
        case "Active":
            tasks = tasks.filter { !$0.isCompleted }
        case "Completed":
            tasks = tasks.filter { $0.isCompleted }
        case "Overdue":
            tasks = tasks.filter { task in
                guard let dueDate = task.dueDate else { return false }
                return !task.isCompleted && dueDate < Date()
            }
        default:
            break
        }
        
        return tasks
    }
    
    private var activeTasks: [Task] {
        allTasks.filter { !$0.isCompleted }
    }
    
    private var completedTasks: [Task] {
        allTasks.filter { $0.isCompleted }
    }

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundGradient
                    .opacity(0.03)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchAndFilterSection
                    
                    if filteredTasks.isEmpty {
                        emptyStateView
                    } else {
                        taskListSection
                    }
                }
            }
            .navigationTitle("My Tasks")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !completedTasks.isEmpty {
                        Button {
                            showingCompletedTasks.toggle()
                        } label: {
                            Image(systemName: showingCompletedTasks ? "eye.slash" : "eye")
                                .foregroundColor(themeManager.accentColor)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.accentColor)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
                    .environmentObject(themeManager)
            }
            .sheet(item: $editingTask) { task in
                EditTaskView(task: task)
                    .environmentObject(themeManager)
            }
        }
        .onAppear {
            labelManager.loadLabels(context: viewContext)
        }
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search tasks...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(themeManager.accentColor)
                    .font(.caption)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filterOptions, id: \.self) { filter in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(filter)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                if filter != "All" {
                                    Text("\(getFilterCount(filter))")
                                        .font(.caption2)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Circle().fill(Color.white.opacity(0.3)))
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedFilter == filter ? 
                                          themeManager.accentColor : 
                                          Color(.tertiarySystemFill))
                            )
                            .foregroundColor(selectedFilter == filter ? .white : .primary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
        .background(themeManager.cardBackgroundColor)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: getEmptyStateIcon())
                    .font(.system(size: 60))
                    .foregroundColor(themeManager.accentColor.opacity(0.7))
                    .scaleEffect(1.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: selectedFilter)
                
                VStack(spacing: 8) {
                    Text(getEmptyStateTitle())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Text(getEmptyStateSubtitle())
                        .font(.subheadline)
                        .foregroundColor(themeManager.textSecondaryColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .padding()
            .animatedCard()
            
            if selectedFilter == "Active" || selectedFilter == "All" {
                Button {
                    showingAddTask = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Your First Task")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(themeManager.accentColor)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var taskListSection: some View {
        List {
            if showingCompletedTasks && !completedTasks.isEmpty {
                Section("Completed (\(completedTasks.count))") {
                    ForEach(completedTasks, id: \.id) { task in
                        EnhancedTaskRow(task: task, onEdit: { editingTask = task })
                            .environmentObject(themeManager)
                    }
                    .onDelete { indexSet in
                        deleteTasks(from: completedTasks, at: indexSet)
                    }
                }
            }
            
            if selectedFilter != "Completed" {
                Section(activeTasks.isEmpty ? "" : "Active (\(activeTasks.count))") {
                    ForEach(filteredTasks.filter { !$0.isCompleted }, id: \.id) { task in
                        EnhancedTaskRow(task: task, onEdit: { editingTask = task })
                            .environmentObject(themeManager)
                    }
                    .onDelete { indexSet in
                        deleteTasks(from: filteredTasks.filter { !$0.isCompleted }, at: indexSet)
                    }
                }
            }
            
            if selectedFilter == "Completed" {
                Section("Completed Tasks") {
                    ForEach(filteredTasks.filter { $0.isCompleted }, id: \.id) { task in
                        EnhancedTaskRow(task: task, onEdit: { editingTask = task })
                            .environmentObject(themeManager)
                    }
                    .onDelete { indexSet in
                        deleteTasks(from: filteredTasks.filter { $0.isCompleted }, at: indexSet)
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Helper Methods
    
    private func getFilterCount(_ filter: String) -> Int {
        switch filter {
        case "Active": return activeTasks.count
        case "Completed": return completedTasks.count
        case "Overdue": return allTasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return !task.isCompleted && dueDate < Date()
        }.count
        default: return allTasks.count
        }
    }
    
    private func getEmptyStateIcon() -> String {
        switch selectedFilter {
        case "Active": return "checkmark.circle"
        case "Completed": return "trophy.circle"
        case "Overdue": return "clock.circle"
        default: return "list.bullet.circle"
        }
    }
    
    private func getEmptyStateTitle() -> String {
        switch selectedFilter {
        case "All": return "No Tasks Yet"
        case "Active": return "All Caught Up! 🎉"
        case "Completed": return "No Completed Tasks"
        case "Overdue": return "Nothing Overdue! ✅"
        default: return "No Tasks Yet"
        }
    }
    
    private func getEmptyStateSubtitle() -> String {
        switch selectedFilter {
        case "Active": return "You've completed all your active tasks. Time to relax or create new goals!"
        case "Completed": return "Complete some tasks to see them here."
        case "Overdue": return "Great job staying on top of your tasks!"
        default: return "Create your first task to get started with organizing your day."
        }
    }
    
    private func deleteTasks(from tasks: [Task], at indexSet: IndexSet) {
        withAnimation {
            for index in indexSet {
                viewContext.delete(tasks[index])
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting task: \(error)")
            }
        }
    }
}

struct EnhancedTaskRow: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var labelManager = LabelManager.shared
    @ObservedObject var task: Task
    let onEdit: () -> Void
    
    @State private var isCompleting = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isCompleting = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    task.isCompleted.toggle()
                    if task.isCompleted {
                        task.completedDate = Date()
                    }
                    try? viewContext.save()
                    isCompleting = false
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(task.isCompleted ? .green : themeManager.accentColor)
                    .scaleEffect(isCompleting ? 1.3 : 1.0)
                    .rotationEffect(.degrees(isCompleting ? 360 : 0))
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(task.title ?? "Untitled")
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.textPrimaryColor)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if isOverdue {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let details = task.details, !details.isEmpty {
                    Text(details)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textSecondaryColor)
                        .lineLimit(2)
                }
                
                HStack(spacing: 8) {
                    if let due = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(due, style: .relative)
                                .font(.caption)
                        }
                        .foregroundColor(isOverdue ? .red : .secondary)
                    }
                    
                    if let category = task.category {
                        Text(category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(themeManager.accentColor.opacity(0.2)))
                            .foregroundColor(themeManager.accentColor)
                    }
                    
                    if task.difficulty > 0 {
                        HStack(spacing: 2) {
                            ForEach(1...Int(task.difficulty), id: \.self) { _ in
                                Circle()
                                    .fill(themeManager.accentColor)
                                    .frame(width: 4, height: 4)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(task.estimatedDuration)m")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let labels = task.labels, !labels.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(parseTags(labels), id: \.self) { labelName in
                                Text(labelName)
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color(.tertiarySystemFill)))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle")
                    .font(.title3)
                    .foregroundColor(themeManager.accentColor.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .opacity(task.isCompleted ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: task.isCompleted)
    }
    
    private var isOverdue: Bool {
        guard let dueDate = task.dueDate else { return false }
        return !task.isCompleted && dueDate < Date()
    }
}

struct EditTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var labelManager = LabelManager.shared
    
    @ObservedObject var task: Task
    
    @State private var title: String
    @State private var details: String
    @State private var dueDate: Date
    @State private var category: String
    @State private var difficulty: Int16
    @State private var estimatedDuration: Int32
    @State private var selectedLabels: [TaskLabel] = []
    @State private var recurrenceRule: String
    
    private let categories = ["Personal", "Work", "Health", "Learning", "Social", "Creative", "Household"]
    private let durations = [15, 30, 45, 60, 90, 120]
    
    init(task: Task) {
        self.task = task
        _title = State(initialValue: task.title ?? "")
        _details = State(initialValue: task.details ?? "")
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _category = State(initialValue: task.category ?? "Personal")
        _difficulty = State(initialValue: task.difficulty)
        _estimatedDuration = State(initialValue: task.estimatedDuration)
        _recurrenceRule = State(initialValue: task.recurrenceRule ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $title)
                        .font(.headline)
                    
                    TextField("Description", text: $details, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Properties") {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    HStack {
                        Text("Difficulty")
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { level in
                                Button {
                                    withAnimation(.spring(response: 0.3)) {
                                        difficulty = Int16(level)
                                    }
                                } label: {
                                    Circle()
                                        .fill(level <= difficulty ? themeManager.accentColor : Color(.tertiarySystemFill))
                                        .frame(width: 20, height: 20)
                                        .scaleEffect(level <= difficulty ? 1.1 : 1.0)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    
                    HStack {
                        Text("Duration")
                        Spacer()
                        Picker("Duration", selection: $estimatedDuration) {
                            ForEach(durations, id: \.self) { duration in
                                Text("\(duration) min").tag(Int32(duration))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
                
                Section("Scheduling") {
                    DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    
                    TextField("Recurrence", text: $recurrenceRule)
                }
                
                Section("Status") {
                    HStack {
                        Text("Completed")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { task.isCompleted },
                            set: { newValue in
                                task.isCompleted = newValue
                                if newValue {
                                    task.completedDate = Date()
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.medium)
                }
            }
            .moodResponsiveBackground(opacity: 0.05)
        }
        .onAppear {
            labelManager.loadLabels(context: viewContext)
            loadSelectedLabels()
        }
    }
    
    private func loadSelectedLabels() {
        if let labels = task.labels {
            selectedLabels = labelManager.getLabelsFromString(labels, context: viewContext)
        }
    }
    
    private func saveTask() {
        task.title = title
        task.details = details.isEmpty ? nil : details
        task.dueDate = dueDate
        task.category = category
        task.difficulty = difficulty
        task.estimatedDuration = estimatedDuration
        task.labels = labelManager.labelsToString(selectedLabels)
        task.recurrenceRule = recurrenceRule.isEmpty ? nil : recurrenceRule
        
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving task: \(error)")
        }
    }
}


