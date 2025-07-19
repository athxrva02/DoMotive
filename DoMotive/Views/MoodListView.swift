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
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var moodManager = MoodManager.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MoodEntry.date, ascending: false)],
        animation: .default
    ) private var moods: FetchedResults<MoodEntry>

    @State private var showingAddMood = false
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    
    private let filterOptions = ["All", "Today", "This Week", "This Month"]
    
    private var filteredMoods: [MoodEntry] {
        var moodArray = Array(moods)
        
        // Apply search filter
        if !searchText.isEmpty {
            moodArray = moodArray.filter { mood in
                (mood.moodLabel?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (mood.tags?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply date filter
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedFilter {
        case "Today":
            moodArray = moodArray.filter { mood in
                guard let date = mood.date else { return false }
                return calendar.isDate(date, inSameDayAs: now)
            }
        case "This Week":
            moodArray = moodArray.filter { mood in
                guard let date = mood.date else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
            }
        case "This Month":
            moodArray = moodArray.filter { mood in
                guard let date = mood.date else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .month)
            }
        default:
            break
        }
        
        return moodArray
    }

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundGradient
                    .opacity(0.03)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchAndFilterSection
                    
                    if filteredMoods.isEmpty {
                        emptyStateView
                    } else {
                        moodListSection
                    }
                }
            }
            .navigationTitle("Mood History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddMood = true
                    } label: {
                        Image(systemName: "heart.circle.fill")
                            .foregroundColor(themeManager.accentColor)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddMood) {
                AddMoodView()
                    .environmentObject(themeManager)
            }
        }
        .moodResponsiveBackground(opacity: 0.05)
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search moods...", text: $searchText)
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
            
            Button {
                showingAddMood = true
            } label: {
                HStack {
                    Image(systemName: "heart.circle.fill")
                    Text("Track Your Mood")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding()
                .background(themeManager.accentColor)
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var moodListSection: some View {
        List {
            ForEach(filteredMoods, id: \.id) { mood in
                EnhancedMoodCard(mood: mood)
                    .environmentObject(themeManager)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteMoods)
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Helper Methods
    
    private func getFilterCount(_ filter: String) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        switch filter {
        case "Today":
            return moods.filter { mood in
                guard let date = mood.date else { return false }
                return calendar.isDate(date, inSameDayAs: now)
            }.count
        case "This Week":
            return moods.filter { mood in
                guard let date = mood.date else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
            }.count
        case "This Month":
            return moods.filter { mood in
                guard let date = mood.date else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .month)
            }.count
        default:
            return moods.count
        }
    }
    
    private func getEmptyStateIcon() -> String {
        switch selectedFilter {
        case "Today": return "heart.circle"
        case "This Week": return "heart.text.square"
        case "This Month": return "calendar.badge.clock"
        default: return "heart.fill"
        }
    }
    
    private func getEmptyStateTitle() -> String {
        switch selectedFilter {
        case "Today": return "No mood entries today"
        case "This Week": return "No mood entries this week"
        case "This Month": return "No mood entries this month"
        default: return "Start Tracking Your Mood"
        }
    }
    
    private func getEmptyStateSubtitle() -> String {
        switch selectedFilter {
        case "Today": return "Take a moment to check in with yourself and log how you're feeling."
        case "This Week": return "This week has been quiet. How are you feeling right now?"
        case "This Month": return "Start documenting your emotional journey this month."
        default: return "Track your daily emotions to better understand your mental health patterns."
        }
    }
    
    private func deleteMoods(offsets: IndexSet) {
        withAnimation {
            offsets.map { filteredMoods[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting mood: \(error)")
            }
        }
    }
}

struct EnhancedMoodCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var moodManager = MoodManager.shared
    @ObservedObject var mood: MoodEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left: Emoji and score
            VStack(spacing: 8) {
                Text(moodManager.getMoodEmoji(for: mood.moodValue, context: viewContext))
                    .font(.system(size: 36))
                
                Text("\(mood.moodValue)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.accentColor)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(themeManager.accentColor.opacity(0.15)))
            }
            .frame(width: 60)
            
            // Center: Main content
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(mood.moodLabel ?? moodManager.getMoodLabel(for: mood.moodValue, context: viewContext))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Spacer()
                    
                    if let date = mood.date {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.textSecondaryColor)
                    }
                }
                
                // Mood scale indicator
                HStack(spacing: 3) {
                    ForEach(1...10, id: \.self) { level in
                        Circle()
                            .fill(level <= mood.moodValue ? themeManager.accentColor : Color(.tertiarySystemFill))
                            .frame(width: 6, height: 6)
                    }
                    
                    Spacer()
                    
                    Text("out of 10")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Tags row
                if let tags = mood.tags, !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(parseTags(tags), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(themeManager.accentColor.opacity(0.1))
                                    )
                                    .foregroundColor(themeManager.accentColor)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .animatedCard()
    }
}

