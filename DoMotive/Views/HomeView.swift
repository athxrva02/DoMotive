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
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var taskEngine = TaskEngine.shared
    @StateObject private var moodManager = MoodManager.shared

    // Fetch today's mood (if any)
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
    @State private var suggestedTasks: [TaskTemplate] = []
    @State private var showingSuggestions = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // --- App Greeting ---
                    greetingSection

                    // --- Mood Log Section ---
                    moodSection

                    // --- Smart Suggestions ---
                    if !suggestedTasks.isEmpty {
                        smartSuggestionsSection
                    }

                    // --- Quick Actions ---
                    quickActions

                    // --- Today's Tasks ---
                    todaysTasksSection

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)
            }
            .navigationBarHidden(true)
            .moodResponsiveBackground(opacity: 0.03)
            .onAppear {
                updateThemeForMood()
                loadSmartSuggestions()
            }
            .onChange(of: todayMood.first?.moodValue) { _ in
                updateThemeForMood()
                loadSmartSuggestions()
            }
        }
    }
    
    // MARK: - New Sections
    
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DoMotive")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Text(Date(), style: .date)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
                
                Spacer()
                
                if let mood = todayMood.first {
                    VStack {
                        Text(moodManager.getMoodEmoji(for: mood.moodValue, context: viewContext))
                            .font(.system(size: 32))
                            .scaleEffect(1.2)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: mood.moodValue)
                    }
                }
            }
        }
        .padding()
        .animatedCard()
    }
    
    private var smartSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Smart Suggestions")
                    .font(.headline)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Spacer()
                
                Button("See All") {
                    showingSuggestions = true
                }
                .font(.caption)
                .foregroundColor(themeManager.accentColor)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(suggestedTasks.prefix(3).enumerated()), id: \.offset) { index, template in
                        SmallTaskSuggestionCard(
                            template: template,
                            moodValue: todayMood.first?.moodValue ?? 5,
                            onAccept: {
                                acceptSuggestion(template: template)
                            }
                        )
                        .environmentObject(themeManager)
                    }
                }
                .padding(.horizontal, 1)
            }
        }
        .padding()
        .animatedCard()
        .sheet(isPresented: $showingSuggestions) {
            SuggestionView()
                .environmentObject(themeManager)
        }
    }
    
    private var todaysTasksSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Today's Tasks")
                    .font(.headline)
                    .foregroundColor(themeManager.textPrimaryColor)
                Spacer()
                Text("\(tasks.count) remaining")
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondaryColor)
            }
            
            if tasks.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 40))
                        .foregroundColor(themeManager.accentColor.opacity(0.7))
                    
                    Text("All caught up! 🎉")
                        .font(.headline)
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Text("No pending tasks for today")
                        .font(.subheadline)
                        .foregroundColor(themeManager.textSecondaryColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ForEach(Array(tasks.prefix(3).enumerated()), id: \.offset) { index, task in
                    EnhancedHomeTaskCard(task: task)
                        .environmentObject(themeManager)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.1), value: tasks.count)
                }
                
                if tasks.count > 3 {
                    NavigationLink(destination: TaskListView()) {
                        Text("View \(tasks.count - 3) more tasks →")
                            .font(.caption)
                            .foregroundColor(themeManager.accentColor)
                            .padding(.vertical, 8)
                    }
                }
            }
        }
        .padding()
        .animatedCard()
    }
    
    // MARK: - Helper Methods
    
    private func updateThemeForMood() {
        if let currentMood = todayMood.first {
            themeManager.updateTheme(for: currentMood.moodValue)
        }
    }
    
    private func loadSmartSuggestions() {
        let currentMoodValue = todayMood.first?.moodValue ?? 5
        suggestedTasks = taskEngine.getSuggestedTasks(
            for: currentMoodValue,
            timeOfDay: .current,
            maxSuggestions: 3,
            context: viewContext
        )
    }
    
    private func acceptSuggestion(template: TaskTemplate) {
        let task = taskEngine.createTask(from: template, context: viewContext)
        
        do {
            try viewContext.save()
            // Reload suggestions after accepting one
            loadSmartSuggestions()
        } catch {
            print("Error creating task from suggestion: \(error)")
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
                                    .background(Capsule().fill(themeManager.primaryColor.opacity(0.15)))
                                    .font(.caption)
                                    .foregroundColor(themeManager.primaryColor)
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
                actionButton(icon: "plus.circle", label: "Add Task", color: themeManager.accentColor)
            }
            NavigationLink(destination: AddJournalView()) {
                actionButton(icon: "pencil.and.outline", label: "Journal", color: themeManager.secondaryColor)
            }
            NavigationLink(destination: PlanDayView()) {
                actionButton(icon: "calendar", label: "Plan Day", color: themeManager.successColor)
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
                            .environmentObject(themeManager)
                    }
                }
            } else {
                ForEach(tasks.prefix(3)) { task in
                    HomeTaskCard(task: task)
                        .environmentObject(themeManager)
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
    @EnvironmentObject var themeManager: ColorThemeManager
    @ObservedObject var task: Task
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(task.title ?? "Untitled")
                    .font(.subheadline).bold()
                    .foregroundColor(.primary)
                if let due = task.dueDate {
                    Text(due.formatted(date: .abbreviated, time: .omitted))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                if let mood = task.moodTag, !mood.isEmpty {
                    Text("Mood: \(mood.capitalized)").font(.caption2).foregroundColor(themeManager.primaryColor)
                }
            }
            Spacer()
            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(task.isCompleted ? themeManager.successColor : .gray)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
        .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 1)
    }
}

struct EnhancedHomeTaskCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var labelManager = LabelManager.shared
    @ObservedObject var task: Task
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
                    .foregroundColor(task.isCompleted ? themeManager.successColor : themeManager.accentColor)
                    .scaleEffect(isCompleting ? 1.3 : 1.0)
                    .rotationEffect(.degrees(isCompleting ? 360 : 0))
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title ?? "Untitled")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .strikethrough(task.isCompleted)
                
                if let details = task.details, !details.isEmpty {
                    Text(details)
                        .font(.subheadline)
                        .foregroundColor(themeManager.textSecondaryColor)
                        .lineLimit(1)
                }
                
                HStack {
                    if let due = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption)
                            Text(due.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    if let category = task.category {
                        Text(category)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(themeManager.accentColor.opacity(0.2)))
                            .foregroundColor(themeManager.accentColor)
                    }
                    
                    Spacer()
                    
                    DifficultyIndicator(difficulty: task.difficulty)
                        .environmentObject(themeManager)
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
        }
        .padding()
        .animatedCard()
        .opacity(task.isCompleted ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.3), value: task.isCompleted)
    }
}

struct SmallTaskSuggestionCard: View {
    @EnvironmentObject var themeManager: ColorThemeManager
    let template: TaskTemplate
    let moodValue: Int16
    let onAccept: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 8) {
                if let category = template.category {
                    Text(getCategoryEmoji(category))
                        .font(.system(size: 28))
                }
                
                Text(template.title ?? "Untitled")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text("\(template.estimatedDuration) min")
                    .font(.caption)
                    .foregroundColor(themeManager.textSecondaryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(themeManager.accentColor.opacity(0.1)))
            }
            
            Button(action: onAccept) {
                Text("Add")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(themeManager.accentColor)
                    .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: 120, height: 140)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(themeManager.cardBackgroundColor)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
    }
    
    private func getCategoryEmoji(_ category: String) -> String {
        switch category.lowercased() {
        case "cleaning": return "🧹"
        case "exercise": return "🏃‍♂️"
        case "self care": return "🧘‍♀️"
        case "selfcare": return "🧘‍♀️"
        case "creative": return "🎨"
        case "admin": return "📋"
        case "administrative": return "📋"
        case "social": return "👥"
        case "learning": return "📚"
        case "work": return "💼"
        case "household": return "🏠"
        default: return "✨"
        }
    }
}

struct DifficultyIndicator: View {
    @EnvironmentObject var themeManager: ColorThemeManager
    let difficulty: Int16
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { level in
                Circle()
                    .fill(level <= difficulty ? themeManager.accentColor : Color(.tertiarySystemFill))
                    .frame(width: 4, height: 4)
            }
        }
    }
}

