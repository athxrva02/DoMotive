//
//  DiscreteMoodSlider.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import SwiftUI
import CoreData

struct DiscreteMoodSlider: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var moodManager = MoodManager.shared
    
    @Binding var selectedValue: Int16
    @State private var showingCustomization = false
    @State private var customLabel = ""
    @State private var customEmoji = ""
    
    private let moodValues: [Int16] = Array(1...10)
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("How are you feeling?")
                    .font(.headline)
                Spacer()
                Button("Customize") {
                    customLabel = moodManager.getMoodLabel(for: selectedValue, context: viewContext)
                    customEmoji = moodManager.getMoodEmoji(for: selectedValue, context: viewContext)
                    showingCustomization = true
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 12) {
                Text(moodManager.getMoodEmoji(for: selectedValue, context: viewContext))
                    .font(.system(size: 60))
                    .animation(.easeInOut(duration: 0.2), value: selectedValue)
                
                Text(moodManager.getMoodLabel(for: selectedValue, context: viewContext))
                    .font(.title2)
                    .fontWeight(.medium)
                    .animation(.easeInOut(duration: 0.2), value: selectedValue)
            }
            .frame(height: 120)
            
            VStack(spacing: 8) {
                HStack {
                    ForEach(moodValues, id: \.self) { value in
                        Button {
                            selectedValue = value
                        } label: {
                            Circle()
                                .fill(selectedValue == value ? Color.accentColor : Color.gray.opacity(0.3))
                                .frame(width: circleSize(for: value), height: circleSize(for: value))
                                .overlay(
                                    Text("\(value)")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(selectedValue == value ? .white : .gray)
                                )
                                .scaleEffect(selectedValue == value ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: selectedValue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                HStack {
                    Text("Terrible")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Euphoric")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 5)
            }
        }
        .sheet(isPresented: $showingCustomization) {
            customizationSheet
        }
    }
    
    private func circleSize(for value: Int16) -> CGFloat {
        return selectedValue == value ? 35 : 28
    }
    
    private var customizationSheet: some View {
        NavigationView {
            Form {
                Section("Customize Mood Level \(selectedValue)") {
                    HStack {
                        Text("Label:")
                        TextField("Enter custom label", text: $customLabel)
                    }
                    
                    HStack {
                        Text("Emoji:")
                        TextField("Enter emoji", text: $customEmoji)
                            .onChange(of: customEmoji) { newValue in
                                let filtered = String(newValue.prefix(2))
                                if filtered != newValue {
                                    customEmoji = filtered
                                }
                            }
                    }
                }
                
                Section {
                    HStack {
                        Text("Preview:")
                        Spacer()
                        Text(customEmoji)
                            .font(.title2)
                        Text(customLabel)
                            .font(.headline)
                    }
                }
                
                Section {
                    Button("Reset to Default") {
                        customLabel = moodManager.getDefaultLabel(for: selectedValue)
                        customEmoji = moodManager.getDefaultEmoji(for: selectedValue)
                    }
                    .foregroundColor(.orange)
                }
            }
            .navigationTitle("Customize Mood")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCustomization = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !customLabel.isEmpty && !customEmoji.isEmpty {
                            moodManager.saveCustomMoodLabel(
                                value: selectedValue,
                                label: customLabel,
                                emoji: customEmoji,
                                context: viewContext
                            )
                        }
                        showingCustomization = false
                    }
                    .disabled(customLabel.isEmpty || customEmoji.isEmpty)
                }
            }
        }
    }
}