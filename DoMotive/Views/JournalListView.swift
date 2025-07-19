//
//  JournalListView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import SwiftUI
import CoreData

struct JournalListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var moodManager = MoodManager.shared
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \JournalEntry.date, ascending: false)],
        animation: .default
    ) private var journals: FetchedResults<JournalEntry>

    @State private var showingAddJournal = false
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    
    private let filterOptions = ["All", "Today", "This Week", "This Month"]
    
    private var filteredJournals: [JournalEntry] {
        var journalArray = Array(journals)
        
        // Apply search filter
        if !searchText.isEmpty {
            journalArray = journalArray.filter { journal in
                (journal.text?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (journal.moodLabel?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (journal.tags?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply date filter
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedFilter {
        case "Today":
            journalArray = journalArray.filter { journal in
                guard let date = journal.date else { return false }
                return calendar.isDate(date, inSameDayAs: now)
            }
        case "This Week":
            journalArray = journalArray.filter { journal in
                guard let date = journal.date else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
            }
        case "This Month":
            journalArray = journalArray.filter { journal in
                guard let date = journal.date else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .month)
            }
        default:
            break
        }
        
        return journalArray
    }

    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundGradient
                    .opacity(0.03)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    searchAndFilterSection
                    
                    if filteredJournals.isEmpty {
                        emptyStateView
                    } else {
                        journalListSection
                    }
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddJournal = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(themeManager.accentColor)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddJournal) {
                AddJournalView()
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
                TextField("Search entries...", text: $searchText)
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
                showingAddJournal = true
            } label: {
                HStack {
                    Image(systemName: "square.and.pencil")
                    Text("Start Journaling")
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
    
    private var journalListSection: some View {
        List {
            ForEach(filteredJournals, id: \.id) { journal in
                JournalEntryCard(journal: journal)
                    .environmentObject(themeManager)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .onDelete(perform: deleteJournalEntries)
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Helper Methods
    
    private func getFilterCount(_ filter: String) -> Int {
        let calendar = Calendar.current
        let now = Date()
        
        switch filter {
        case "Today":
            return journals.filter { journal in
                guard let date = journal.date else { return false }
                return calendar.isDate(date, inSameDayAs: now)
            }.count
        case "This Week":
            return journals.filter { journal in
                guard let date = journal.date else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
            }.count
        case "This Month":
            return journals.filter { journal in
                guard let date = journal.date else { return false }
                return calendar.isDate(date, equalTo: now, toGranularity: .month)
            }.count
        default:
            return journals.count
        }
    }
    
    private func getEmptyStateIcon() -> String {
        switch selectedFilter {
        case "Today": return "calendar.circle"
        case "This Week": return "calendar.badge.clock"
        case "This Month": return "calendar.badge.exclamationmark"
        default: return "book.circle"
        }
    }
    
    private func getEmptyStateTitle() -> String {
        switch selectedFilter {
        case "Today": return "No entries today"
        case "This Week": return "No entries this week"
        case "This Month": return "No entries this month"
        default: return "Start Your Journal"
        }
    }
    
    private func getEmptyStateSubtitle() -> String {
        switch selectedFilter {
        case "Today": return "Take a moment to reflect on your day and capture your thoughts."
        case "This Week": return "This week has been quiet. Share what's on your mind."
        case "This Month": return "Start documenting your journey this month."
        default: return "Capture your thoughts, feelings, and daily reflections in your personal journal."
        }
    }
    
    private func deleteJournalEntries(at indexSet: IndexSet) {
        withAnimation {
            for index in indexSet {
                viewContext.delete(filteredJournals[index])
            }
            
            do {
                try viewContext.save()
            } catch {
                print("Error deleting journal entry: \(error)")
            }
        }
    }
}

struct JournalEntryCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var moodManager = MoodManager.shared
    @ObservedObject var journal: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if journal.moodValue > 0 {
                    HStack(spacing: 8) {
                        Text(moodManager.getMoodEmoji(for: journal.moodValue, context: viewContext))
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(journal.moodLabel ?? "")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(themeManager.accentColor)
                            
                            Text("Mood \(journal.moodValue)/10")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(themeManager.accentColor.opacity(0.1))
                    )
                }
                
                Spacer()
                
                if let date = journal.date {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        Text(date.formatted(date: .omitted, time: .shortened))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text(journal.text ?? "")
                .font(.body)
                .foregroundColor(themeManager.textPrimaryColor)
                .lineLimit(6)
                .multilineTextAlignment(.leading)
            
            if let tags = journal.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(parseTags(tags), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color(.tertiarySystemFill))
                                )
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding()
        .animatedCard()
    }
}
