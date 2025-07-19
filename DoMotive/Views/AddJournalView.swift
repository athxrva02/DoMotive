//
//  AddJournalView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import SwiftUI
import CoreData

struct AddJournalView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentation
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var moodManager = MoodManager.shared

    @State private var text: String = ""
    @State private var moodValue: Int16 = 5
    @State private var tags: String = ""
    @State private var selectedDate = Date()
    @State private var showingMoodSelector = false
    @State private var isExpanded = false
    
    private let characterLimit = 2000

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
            .navigationTitle("New Journal Entry")
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
                        addJournal()
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
                Text("What's on your mind?")
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
                    .onChange(of: text) { newValue in
                        if newValue.count > characterLimit {
                            text = String(newValue.prefix(characterLimit))
                        }
                        // Update theme based on content
                        if !newValue.isEmpty {
                            themeManager.updateTheme(for: moodValue)
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

    private func addJournal() {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        let newJournal = JournalEntry(context: viewContext)
        newJournal.id = UUID()
        newJournal.text = trimmedText
        newJournal.date = selectedDate
        newJournal.moodValue = moodValue
        newJournal.moodLabel = moodManager.getMoodLabel(for: moodValue, context: viewContext)
        newJournal.tags = tags.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : tags

        do {
            try viewContext.save()
            presentation.wrappedValue.dismiss()
        } catch {
            print("Error saving journal entry: \(error)")
        }
    }
}

struct MoodSelectorView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var moodManager = MoodManager.shared
    @Binding var selectedMood: Int16
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("How are you feeling right now?")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.textPrimaryColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                DiscreteMoodSlider(selectedValue: $selectedMood)
                    .onChange(of: selectedMood) { newValue in
                        themeManager.updateTheme(for: newValue)
                    }
                
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Text(moodManager.getMoodEmoji(for: selectedMood, context: viewContext))
                            .font(.system(size: 50))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(moodManager.getMoodLabel(for: selectedMood, context: viewContext))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.textPrimaryColor)
                            
                            Text("Level \(selectedMood) out of 10")
                                .font(.subheadline)
                                .foregroundColor(themeManager.textSecondaryColor)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .animatedCard()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Select Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.accentColor)
                }
            }
        }
        .moodResponsiveBackground(opacity: 0.05)
    }
}
