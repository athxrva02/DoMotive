//
//  LabelPickerView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import SwiftUI
import CoreData

struct LabelPickerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var labelManager = LabelManager.shared
    @EnvironmentObject var themeManager: ColorThemeManager
    
    @Binding var selectedLabels: [TaskLabel]
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    @State private var showingCreateLabel = false
    @State private var showingLabelDetail: TaskLabel?
    
    private var filteredLabels: [TaskLabel] {
        var labels = labelManager.availableLabels
        
        if selectedCategory != "All" {
            labels = labels.filter { $0.category == selectedCategory }
        }
        
        if !searchText.isEmpty {
            labels = labels.filter { 
                $0.name?.localizedCaseInsensitiveContains(searchText) ?? false 
            }
        }
        
        return labels
    }
    
    private var categories: [String] {
        ["All"] + labelManager.getAllCategories(context: viewContext)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchAndFilterSection
                categorySelector
                labelGrid
            }
            .navigationTitle("Select Labels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        // Dismiss handled by parent
                    }
                    .fontWeight(.medium)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateLabel = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeManager.accentColor)
                    }
                }
            }
            .sheet(isPresented: $showingCreateLabel) {
                CreateLabelView()
                    .environmentObject(themeManager)
                    .onDisappear {
                        labelManager.loadLabels(context: viewContext)
                    }
            }
            .sheet(item: $showingLabelDetail) { label in
                LabelDetailView(label: label)
                    .environmentObject(themeManager)
            }
            .onAppear {
                labelManager.loadLabels(context: viewContext)
            }
        }
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search labels...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(themeManager.accentColor)
                }
            }
            .padding(.horizontal)
            
            if !selectedLabels.isEmpty {
                selectedLabelsSection
            }
        }
        .padding(.top)
    }
    
    private var selectedLabelsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Selected (\(selectedLabels.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Button("Clear All") {
                    withAnimation(.spring()) {
                        selectedLabels.removeAll()
                    }
                }
                .font(.caption)
                .foregroundColor(themeManager.accentColor)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(selectedLabels, id: \.id) { label in
                    LabelChip(
                        label: label,
                        isSelected: true,
                        onTap: {
                            withAnimation(.spring()) {
                                selectedLabels.removeAll { $0.id == label.id }
                            }
                        },
                        onLongPress: {
                            showingLabelDetail = label
                        }
                    )
                    .environmentObject(themeManager)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedCategory = category
                        }
                    } label: {
                        Text(category)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == category ? 
                                          themeManager.accentColor : 
                                          Color(.tertiarySystemFill))
                            )
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var labelGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(filteredLabels, id: \.id) { label in
                    LabelChip(
                        label: label,
                        isSelected: selectedLabels.contains { $0.id == label.id },
                        onTap: {
                            withAnimation(.spring()) {
                                if let index = selectedLabels.firstIndex(where: { $0.id == label.id }) {
                                    selectedLabels.remove(at: index)
                                } else {
                                    selectedLabels.append(label)
                                    labelManager.incrementUsage(for: label, context: viewContext)
                                }
                            }
                        },
                        onLongPress: {
                            showingLabelDetail = label
                        }
                    )
                    .environmentObject(themeManager)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct LabelChip: View {
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var labelManager = LabelManager.shared
    
    let label: TaskLabel
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: (() -> Void)?
    
    init(label: TaskLabel, isSelected: Bool, onTap: @escaping () -> Void, onLongPress: (() -> Void)? = nil) {
        self.label = label
        self.isSelected = isSelected
        self.onTap = onTap
        self.onLongPress = onLongPress
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                if let emoji = label.emoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.title2)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(label.name ?? "")
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    if let category = label.category {
                        Text(category)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? 
                          labelManager.getColor(for: label) : 
                          labelManager.getColor(for: label).opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(labelManager.getColor(for: label), lineWidth: isSelected ? 2 : 1)
                    )
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture {
            onLongPress?()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct CreateLabelView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var labelManager = LabelManager.shared
    @EnvironmentObject var themeManager: ColorThemeManager
    
    @State private var name = ""
    @State private var category = "Custom"
    @State private var emoji = ""
    @State private var selectedColorHex = "#3498DB"
    
    private let predefinedCategories = ["Energy", "Location", "Type", "Duration", "Category", "Custom"]
    private let colorOptions = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FFEAA7", "#DDA0DD", "#98D8C8", "#F7DC6F", "#FF7675", "#74B9FF"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Label Details") {
                    HStack {
                        TextField("Label name", text: $name)
                        Text(emoji)
                            .font(.title2)
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(predefinedCategories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    
                    TextField("Emoji", text: $emoji)
                        .onChange(of: emoji) { _, newValue in
                            emoji = String(newValue.prefix(2))
                        }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { colorHex in
                            Button {
                                selectedColorHex = colorHex
                            } label: {
                                Circle()
                                    .fill(Color(hex: colorHex) ?? .blue)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColorHex == colorHex ? 3 : 0)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    HStack {
                        Text("Preview:")
                        Spacer()
                        LabelChip(
                            label: previewLabel,
                            isSelected: false,
                            onTap: {}
                        )
                        .environmentObject(themeManager)
                    }
                }
            }
            .navigationTitle("Create Label")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveLabel()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private var previewLabel: TaskLabel {
        let label = TaskLabel(context: viewContext)
        label.name = name.isEmpty ? "Preview" : name
        label.category = category
        label.emoji = emoji.isEmpty ? "🏷️" : emoji
        label.colorHex = selectedColorHex
        return label
    }
    
    private func saveLabel() {
        _ = labelManager.createLabel(
            name: name,
            category: category,
            colorHex: selectedColorHex,
            emoji: emoji.isEmpty ? "🏷️" : emoji,
            context: viewContext
        )
        presentationMode.wrappedValue.dismiss()
    }
}

struct LabelDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var labelManager = LabelManager.shared
    @EnvironmentObject var themeManager: ColorThemeManager
    
    let label: TaskLabel
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text(label.emoji ?? "🏷️")
                        .font(.system(size: 60))
                    
                    Text(label.name ?? "")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text(label.category ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(.tertiarySystemFill)))
                }
                .padding()
                .animatedCard()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Usage Stats")
                            .font(.headline)
                        Spacer()
                    }
                    
                    HStack {
                        Text("Used \(label.usageCount) times")
                        Spacer()
                        if let lastUsed = label.lastUsedDate {
                            Text("Last used: \(lastUsed, style: .relative)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .animatedCard()
                
                if !label.isBuiltIn {
                    Button(role: .destructive) {
                        deleteLabel()
                    } label: {
                        Text("Delete Label")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Label Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func deleteLabel() {
        labelManager.deleteLabel(label, context: viewContext)
        presentationMode.wrappedValue.dismiss()
    }
}