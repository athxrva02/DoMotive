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
    @State private var editingJournal: JournalEntry?
    @State private var selectedJournal: JournalEntry?
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
            .sheet(item: $editingJournal) { journal in
                EditJournalView(journal: journal)
                    .environmentObject(themeManager)
            }
            .sheet(item: $selectedJournal) { journal in
                JournalDetailView(journal: journal)
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
                    .onTapGesture {
                        selectedJournal = journal
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            editingJournal = journal
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(themeManager.accentColor)
                    }
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

struct EditJournalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var moodManager = MoodManager.shared
    
    @ObservedObject var journal: JournalEntry
    
    @State private var text: String
    @State private var moodValue: Int16
    @State private var tags: String
    @State private var selectedDate: Date
    @State private var showingMoodSelector = false
    @State private var isExpanded = false
    
    private let characterLimit = 2000
    
    init(journal: JournalEntry) {
        self.journal = journal
        _text = State(initialValue: journal.text ?? "")
        _moodValue = State(initialValue: journal.moodValue)
        _tags = State(initialValue: journal.tags ?? "")
        _selectedDate = State(initialValue: journal.date ?? Date())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundGradient
                    .opacity(0.03)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        journalEntrySection
                        moodSection
                        additionalDetailsSection
                        characterCountSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentation.wrappedValue.dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveJournal()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 
                                   .secondary : themeManager.accentColor)
                }
            }
        }
        .onAppear {
            themeManager.updateTheme(for: moodValue)
        }
    }
    
    private var journalEntrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "square.and.pencil")
                    .foregroundColor(themeManager.accentColor)
                Text("Edit your thoughts")
                    .font(.headline)
                    .foregroundColor(themeManager.textPrimaryColor)
                Spacer()
            }
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    VStack {
                        HStack {
                            Text("Share your thoughts, feelings, experiences, or anything you'd like to remember...")
                                .foregroundColor(.secondary)
                                .font(.body)
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
                }
                
                TextEditor(text: $text)
                    .font(.body)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .frame(minHeight: isExpanded ? 300 : 150)
                    .onChange(of: text) { _, newValue in
                        if newValue.count > characterLimit {
                            text = String(newValue.prefix(characterLimit))
                        }
                    }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeManager.accentColor.opacity(0.3), lineWidth: 1)
                    )
            )
            
            HStack {
                Button {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.caption)
                        Text(isExpanded ? "Compact" : "Expand")
                            .font(.caption)
                    }
                    .foregroundColor(themeManager.accentColor)
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
        }
        .animatedCard()
    }
    
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "heart.circle.fill")
                    .foregroundColor(themeManager.accentColor)
                Text("How are you feeling?")
                    .font(.headline)
                    .foregroundColor(themeManager.textPrimaryColor)
                Spacer()
                
                Button {
                    showingMoodSelector.toggle()
                } label: {
                    Text("Change")
                        .font(.caption)
                        .foregroundColor(themeManager.accentColor)
                }
            }
            
            HStack(spacing: 12) {
                Text(moodManager.getMoodEmoji(for: moodValue, context: viewContext))
                    .font(.system(size: 40))
                    .scaleEffect(1.2)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6), value: moodValue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(moodManager.getMoodLabel(for: moodValue, context: viewContext))
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(themeManager.textPrimaryColor)
                    
                    Text("Mood Level: \(moodValue)/10")
                        .font(.subheadline)
                        .foregroundColor(themeManager.textSecondaryColor)
                    
                    HStack(spacing: 2) {
                        ForEach(1...10, id: \.self) { level in
                            Circle()
                                .fill(level <= moodValue ? themeManager.accentColor : Color(.tertiarySystemFill))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.accentColor.opacity(0.1))
            )
            .onTapGesture {
                showingMoodSelector = true
            }
        }
        .animatedCard()
        .sheet(isPresented: $showingMoodSelector) {
            MoodSelectorView(selectedMood: $moodValue)
                .environmentObject(themeManager)
        }
    }
    
    private var additionalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag.circle.fill")
                    .foregroundColor(themeManager.accentColor)
                Text("Additional Details")
                    .font(.headline)
                    .foregroundColor(themeManager.textPrimaryColor)
                Spacer()
            }
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(themeManager.accentColor)
                        .frame(width: 20)
                    Text("Date & Time")
                        .font(.subheadline)
                        .foregroundColor(themeManager.textPrimaryColor)
                    Spacer()
                    DatePicker("", selection: $selectedDate, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "number")
                            .foregroundColor(themeManager.accentColor)
                            .frame(width: 20)
                        Text("Tags")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textPrimaryColor)
                        Spacer()
                    }
                    
                    TextField("Enter tags (separated by commas)", text: $tags)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Examples: grateful, productive, excited, challenging")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(themeManager.cardBackgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.separator), lineWidth: 0.5)
                    )
            )
        }
        .animatedCard()
    }
    
    private var characterCountSection: some View {
        HStack {
            Spacer()
            Text("\(text.count)/\(characterLimit)")
                .font(.caption2)
                .foregroundColor(text.count > characterLimit * 9/10 ? .orange : .secondary)
        }
        .padding(.horizontal)
    }
    
    private func saveJournal() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        journal.text = trimmedText
        journal.date = selectedDate
        journal.moodValue = moodValue
        journal.moodLabel = moodManager.getMoodLabel(for: moodValue, context: viewContext)
        journal.tags = tags.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : tags
        
        // Update corresponding mood entry
        updateMoodEntry()
        
        do {
            try viewContext.save()
            presentation.wrappedValue.dismiss()
        } catch {
            print("Error saving journal entry: \(error)")
        }
    }
    
    private func updateMoodEntry() {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        
        // Check if mood entry already exists for this date
        let fetchRequest: NSFetchRequest<MoodEntry> = MoodEntry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", dayStart as NSDate, dayEnd as NSDate)
        fetchRequest.fetchLimit = 1
        
        do {
            let existingMoods = try viewContext.fetch(fetchRequest)
            
            if let existingMood = existingMoods.first {
                // Update existing mood entry
                existingMood.moodValue = moodValue
                existingMood.moodLabel = moodManager.getMoodLabel(for: moodValue, context: viewContext)
                // Update tags if provided
                if !tags.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    existingMood.tags = tags
                }
            } else {
                // Create new mood entry if none exists
                let newMood = MoodEntry(context: viewContext)
                newMood.id = UUID()
                newMood.moodValue = moodValue
                newMood.moodLabel = moodManager.getMoodLabel(for: moodValue, context: viewContext)
                newMood.tags = tags.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : tags
                newMood.date = selectedDate
            }
        } catch {
            print("Error updating mood entry: \(error)")
        }
    }
}

struct JournalDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var moodManager = MoodManager.shared
    
    @ObservedObject var journal: JournalEntry
    @State private var showingEditView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                themeManager.backgroundGradient
                    .opacity(0.03)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        contentSection
                        if let tags = journal.tags, !tags.isEmpty {
                            tagsSection
                        }
                        metadataSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Journal Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showingEditView = true
                    }
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditJournalView(journal: journal)
                .environmentObject(themeManager)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            if journal.moodValue > 0 {
                HStack(spacing: 16) {
                    Text(moodManager.getMoodEmoji(for: journal.moodValue, context: viewContext))
                        .font(.system(size: 50))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(journal.moodLabel ?? moodManager.getMoodLabel(for: journal.moodValue, context: viewContext))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.textPrimaryColor)
                        
                        Text("Mood Level: \(journal.moodValue)/10")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondaryColor)
                        
                        HStack(spacing: 3) {
                            ForEach(1...10, id: \.self) { level in
                                Circle()
                                    .fill(level <= journal.moodValue ? themeManager.accentColor : Color(.tertiarySystemFill))
                                    .frame(width: 8, height: 8)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(themeManager.accentColor.opacity(0.1))
                )
            }
        }
        .animatedCard()
    }
    
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "text.quote")
                    .foregroundColor(themeManager.accentColor)
                Text("Entry")
                    .font(.headline)
                    .foregroundColor(themeManager.textPrimaryColor)
                Spacer()
            }
            
            Text(journal.text ?? "")
                .font(.body)
                .foregroundColor(themeManager.textPrimaryColor)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .animatedCard()
    }
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag.circle.fill")
                    .foregroundColor(themeManager.accentColor)
                Text("Tags")
                    .font(.headline)
                    .foregroundColor(themeManager.textPrimaryColor)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: 8)
            ], spacing: 8) {
                ForEach(parseTags(journal.tags ?? ""), id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(themeManager.accentColor.opacity(0.15))
                        )
                        .foregroundColor(themeManager.accentColor)
                }
            }
        }
        .padding()
        .animatedCard()
    }
    
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(themeManager.accentColor)
                Text("Details")
                    .font(.headline)
                    .foregroundColor(themeManager.textPrimaryColor)
                Spacer()
            }
            
            VStack(spacing: 12) {
                if let date = journal.date {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(themeManager.accentColor)
                            .frame(width: 20)
                        Text("Written on")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondaryColor)
                        Spacer()
                        Text(date.formatted(date: .complete, time: .shortened))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.textPrimaryColor)
                    }
                }
                
                if let text = journal.text {
                    HStack {
                        Text("Word count")
                            .font(.subheadline)
                            .foregroundColor(themeManager.textSecondaryColor)
                        Spacer()
                        Text("\(text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count) words")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(themeManager.textPrimaryColor)
                    }
                }
            }
        }
        .padding()
        .animatedCard()
    }
}
