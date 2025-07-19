//
//  AddTaskView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import SwiftUI
import CoreData

struct AddTaskView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentation
    @StateObject private var labelManager = LabelManager.shared
    @StateObject private var themeManager = ColorThemeManager.shared

    @State private var title = ""
    @State private var details = ""
    @State private var dueDate = Date()
    @State private var category = "Personal"
    @State private var difficulty: Int16 = 3
    @State private var estimatedDuration: Int32 = 30
    @State private var selectedLabels: [TaskLabel] = []
    @State private var recurrenceRule = ""
    
    @State private var showingLabelPicker = false

    private let categories = ["Personal", "Work", "Health", "Learning", "Social", "Creative", "Household"]
    private let durations = [15, 30, 45, 60, 90, 120]

    var body: some View {
        NavigationView {
            Form {
                basicDetailsSection
                categoryAndDifficultySection
                labelsSection
                schedulingSection
                advancedSection
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { addTask() }
                        .disabled(title.isEmpty)
                        .fontWeight(.medium)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { presentation.wrappedValue.dismiss() }
                }
            }
            .themeAware()
            .moodResponsiveBackground(opacity: 0.05)
            .sheet(isPresented: $showingLabelPicker) {
                LabelPickerView(selectedLabels: $selectedLabels)
                    .environmentObject(themeManager)
                    .onDisappear {
                        labelManager.loadLabels(context: viewContext)
                    }
            }
            .onAppear {
                labelManager.loadLabels(context: viewContext)
            }
        }
    }
    
    private var basicDetailsSection: some View {
        Section("Task Details") {
            TextField("Task title", text: $title)
                .font(.headline)
            
            TextField("Description (optional)", text: $details, axis: .vertical)
                .lineLimit(3...6)
        }
    }
    
    private var categoryAndDifficultySection: some View {
        Section("Task Properties") {
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
                Text("Estimated Duration")
                Spacer()
                Picker("Duration", selection: $estimatedDuration) {
                    ForEach(durations, id: \.self) { duration in
                        Text("\(duration) min").tag(Int32(duration))
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
    }
    
    private var labelsSection: some View {
        Section("Labels") {
            Button {
                showingLabelPicker = true
            } label: {
                HStack {
                    Image(systemName: "tag")
                        .foregroundColor(themeManager.accentColor)
                    Text(selectedLabels.isEmpty ? "Add labels" : "Manage labels")
                        .foregroundColor(.primary)
                    Spacer()
                    if !selectedLabels.isEmpty {
                        Text("\(selectedLabels.count)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(themeManager.accentColor))
                            .foregroundColor(.white)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if !selectedLabels.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedLabels, id: \.id) { label in
                            HStack(spacing: 4) {
                                if let emoji = label.emoji, !emoji.isEmpty {
                                    Text(emoji)
                                        .font(.caption)
                                }
                                Text(label.name ?? "")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                
                                Button {
                                    withAnimation(.spring()) {
                                        selectedLabels.removeAll { $0.id == label.id }
                                    }
                                } label: {
                                    Image(systemName: "xmark")
                                        .font(.caption2)
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(labelManager.getColor(for: label))
                            )
                            .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
    }
    
    private var schedulingSection: some View {
        Section("Scheduling") {
            DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(CompactDatePickerStyle())
            
            TextField("Recurrence (e.g., daily, weekly)", text: $recurrenceRule)
        }
    }
    
    private var advancedSection: some View {
        Section {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.orange)
                Text("Smart suggestions will help match this task to your future moods based on its difficulty and labels.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func addTask() {
        let newTask = Task(context: viewContext)
        newTask.id = UUID()
        newTask.title = title
        newTask.details = details.isEmpty ? nil : details
        newTask.dueDate = dueDate
        newTask.category = category
        newTask.difficulty = difficulty
        newTask.estimatedDuration = estimatedDuration
        newTask.labels = labelManager.labelsToString(selectedLabels)
        newTask.isCompleted = false
        newTask.recurrenceRule = recurrenceRule.isEmpty ? nil : recurrenceRule
        newTask.createdDate = Date()

        // Increment usage count for selected labels
        for label in selectedLabels {
            labelManager.incrementUsage(for: label, context: viewContext)
        }

        do {
            try viewContext.save()
            presentation.wrappedValue.dismiss()
        } catch {
            print("Error saving task: \(error)")
        }
    }
}
