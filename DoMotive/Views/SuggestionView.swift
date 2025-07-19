//
//  SuggestionView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import SwiftUI
import CoreData

struct SuggestionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskEngine = TaskEngine.shared
    @StateObject private var themeManager = ColorThemeManager.shared
    @StateObject private var moodManager = MoodManager.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.date, ascending: false)],
        predicate: NSPredicate(format: "date >= %@", Calendar.current.startOfDay(for: Date()) as NSDate),
        animation: .default
    ) private var todayMood: FetchedResults<MoodEntry>
    
    @State private var suggestedTasks: [TaskTemplate] = []
    @State private var isLoading = false
    @State private var currentCardIndex = 0
    @State private var showingAllSuggestions = false
    @State private var cardOffsets: [CGSize] = []
    
    private var currentMoodValue: Int16 {
        todayMood.first?.moodValue ?? 5
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        
                        if isLoading {
                            loadingView
                        } else if suggestedTasks.isEmpty {
                            emptyStateView
                        } else {
                            suggestedTasksSection
                        }
                        
                        quickActionsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Task Suggestions")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAllSuggestions = true
                    } label: {
                        Image(systemName: "list.bullet")
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingAllSuggestions) {
                AllSuggestionsView(moodValue: currentMoodValue)
                    .environmentObject(themeManager)
            }
            .onAppear {
                loadSuggestions()
                themeManager.updateTheme(for: currentMoodValue)
                setupCardOffsets()
            }
            .onChange(of: currentMoodValue) { newValue in
                themeManager.updateTheme(for: newValue)
                loadSuggestions()
            }
        }
    }
    
    private var backgroundGradient: some View {
        themeManager.backgroundGradient
            .opacity(0.1)
            .ignoresSafeArea()
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Perfect Tasks for You")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    if let mood = todayMood.first {
                        HStack(spacing: 8) {
                            Text(moodManager.getMoodEmoji(for: mood.moodValue, context: viewContext))
                                .font(.title3)
                            Text("Based on your \(mood.moodLabel ?? "current") mood")
                                .font(.subheadline)
                                .foregroundColor(themeManager.textSecondaryColor)
                        }
                    } else {
                        Text("Log your mood first to get personalized suggestions")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                }
                
                Spacer()
                
                Button(action: loadSuggestions) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(themeManager.accentColor)
                        .rotationEffect(.degrees(isLoading ? 360 : 0))
                        .animation(.linear(duration: 1).repeatWhileActiveOrOnLoad(isLoading), value: isLoading)
                }
            }
            
            if !suggestedTasks.isEmpty {
                ProgressView(value: Double(currentCardIndex), total: Double(suggestedTasks.count - 1))
                    .progressViewStyle(LinearProgressViewStyle(tint: themeManager.accentColor))
                    .animation(.easeInOut(duration: 0.3), value: currentCardIndex)
            }
        }
        .padding()
        .animatedCard()
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(themeManager.accentColor)
            
            Text("Finding perfect tasks for your mood...")
                .font(.subheadline)
                .foregroundColor(themeManager.textSecondaryColor)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
        .animatedCard()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lightbulb")
                .font(.system(size: 50))
                .foregroundColor(themeManager.accentColor.opacity(0.7))
            
            VStack(spacing: 8) {
                Text("No Suggestions Available")
                    .font(.headline)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Text("Create some task templates or log your mood to get personalized suggestions.")
                    .font(.subheadline)
                    .foregroundColor(themeManager.textSecondaryColor)
                    .multilineTextAlignment(.center)
            }
            
            Button("Create Task Template") {
                // Navigate to create template view
            }
            .padding()
            .background(themeManager.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .animatedCard()
    }
    
    private var suggestedTasksSection: some View {
        VStack(spacing: 16) {
            ZStack {
                ForEach(Array(suggestedTasks.enumerated()), id: \.offset) { index, template in
                    if index >= currentCardIndex && index < currentCardIndex + 3 {
                        TaskSuggestionCard(
                            template: template,
                            moodValue: currentMoodValue,
                            onAccept: {
                                acceptSuggestion(template: template)
                            },
                            onDismiss: {
                                dismissSuggestion(at: index)
                            }
                        )
                        .environmentObject(themeManager)
                        .offset(y: CGFloat(index - currentCardIndex) * 10)
                        .scaleEffect(index == currentCardIndex ? 1.0 : 0.95)
                        .opacity(index == currentCardIndex ? 1.0 : 0.7)
                        .zIndex(Double(suggestedTasks.count - index))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentCardIndex)
                    }
                }
            }
            .frame(height: 180)
            
            if suggestedTasks.count > 1 {
                HStack(spacing: 8) {
                    ForEach(0..<suggestedTasks.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentCardIndex ? themeManager.accentColor : Color(.tertiarySystemFill))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentCardIndex ? 1.2 : 1.0)
                            .animation(.spring(), value: currentCardIndex)
                    }
                }
            }
        }
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(themeManager.textPrimaryColor)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                NavigationLink(destination: AddTaskView().environmentObject(themeManager)) {
                    NavigableQuickActionCard(
                        icon: "plus.circle.fill",
                        title: "Create Task",
                        subtitle: "Add a new task",
                        color: themeManager.accentColor
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: AddMoodView().environmentObject(themeManager)) {
                    NavigableQuickActionCard(
                        icon: "heart.circle.fill",
                        title: "Update Mood",
                        subtitle: "Log current feeling",
                        color: .pink
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button {
                    showingAllSuggestions = true
                } label: {
                    NavigableQuickActionCard(
                        icon: "list.bullet.circle.fill",
                        title: "Browse Templates",
                        subtitle: "View all suggestions",
                        color: .orange
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                NavigationLink(destination: TaskListView().environmentObject(themeManager)) {
                    NavigableQuickActionCard(
                        icon: "chart.line.uptrend.xyaxis.circle.fill",
                        title: "View Tasks",
                        subtitle: "Track progress",
                        color: .purple
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .animatedCard()
    }
    
    // MARK: - Helper Methods
    
    private func loadSuggestions() {
        isLoading = true
        currentCardIndex = 0
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            suggestedTasks = taskEngine.getSuggestedTasks(
                for: currentMoodValue,
                timeOfDay: .current,
                maxSuggestions: 5,
                context: viewContext
            )
            
            setupCardOffsets()
            isLoading = false
        }
    }
    
    private func setupCardOffsets() {
        cardOffsets = Array(repeating: .zero, count: suggestedTasks.count)
    }
    
    private func acceptSuggestion(template: TaskTemplate) {
        let _ = taskEngine.createTask(from: template, context: viewContext)
        
        do {
            try viewContext.save()
            taskEngine.recordAcceptance(suggestionId: UUID(), context: viewContext)
            
            withAnimation(.spring()) {
                moveToNextCard()
            }
        } catch {
            print("Error creating task: \(error)")
        }
    }
    
    private func dismissSuggestion(at index: Int) {
        withAnimation(.spring()) {
            moveToNextCard()
        }
    }
    
    private func moveToNextCard() {
        if currentCardIndex < suggestedTasks.count - 1 {
            currentCardIndex += 1
        } else {
            loadSuggestions()
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(.horizontal, 12)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct NavigableQuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
    }
}

struct AllSuggestionsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var taskEngine = TaskEngine.shared
    
    let moodValue: Int16
    @State private var allSuggestions: [TaskTemplate] = []
    
    var body: some View {
        NavigationView {
            List {
                ForEach(allSuggestions, id: \.id) { template in
                    TaskSuggestionRow(template: template, moodValue: moodValue)
                        .environmentObject(themeManager)
                }
            }
            .navigationTitle("All Suggestions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                loadAllSuggestions()
            }
        }
    }
    
    private func loadAllSuggestions() {
        allSuggestions = taskEngine.getSuggestedTasks(
            for: moodValue,
            timeOfDay: .current,
            maxSuggestions: 20,
            context: viewContext
        )
    }
}

struct TaskSuggestionRow: View {
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var taskEngine = TaskEngine.shared
    @Environment(\.managedObjectContext) private var viewContext
    
    let template: TaskTemplate
    let moodValue: Int16
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(template.title ?? "Untitled")
                    .font(.headline)
                    .foregroundColor(themeManager.textPrimaryColor)
                
                Text(getTemplateDescription(template))
                    .font(.subheadline)
                    .foregroundColor(themeManager.textSecondaryColor)
                    .lineLimit(2)
                
                HStack {
                    Text("\(template.estimatedDuration) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let category = template.category {
                        Text(category)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(themeManager.accentColor.opacity(0.2)))
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            
            Spacer()
            
            Button {
                acceptSuggestion()
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.accentColor)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
    
    private func acceptSuggestion() {

        
        do {
            try viewContext.save()
            taskEngine.recordAcceptance(suggestionId: UUID(), context: viewContext)
        } catch {
            print("Error creating task: \(error)")
        }
    }
}

// MARK: - Animation Extension

extension Animation {
    func repeatWhileActiveOrOnLoad(_ isActive: Bool) -> Animation {
        isActive ? self.repeatForever(autoreverses: false) : self
    }
}

