//
//  TaskSuggestionCard.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import SwiftUI
import CoreData

struct TaskSuggestionCard: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var labelManager = LabelManager.shared
    @StateObject private var taskEngine = TaskEngine.shared
    
    let template: TaskTemplate
    let moodValue: Int16
    let onAccept: () -> Void
    let onDismiss: () -> Void
    
    @State private var isPressed = false
    @State private var showingDetails = false
    @State private var cardOffset: CGSize = .zero
    @State private var isDragging = false
    
    var body: some View {
        HStack(spacing: 16) {
            leadingContent
            
            VStack(alignment: .leading, spacing: 8) {
                headerSection
                descriptionSection
                labelsSection
                footerSection
            }
            
            trailingContent
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: themeManager.primaryColor.opacity(0.2),
            radius: isPressed ? 2 : 8
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .offset(cardOffset)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPressed)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: cardOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    cardOffset = value.translation
                }
                .onEnded { value in
                    isDragging = false
                    
                    let threshold: CGFloat = 100
                    
                    if value.translation.width > threshold {
                        // Swipe right to accept
                        withAnimation(.spring()) {
                            cardOffset = CGSize(width: 400, height: 0)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onAccept()
                        }
                    } else if value.translation.width < -threshold {
                        // Swipe left to dismiss
                        withAnimation(.spring()) {
                            cardOffset = CGSize(width: -400, height: 0)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            onDismiss()
                        }
                    } else {
                        // Return to center
                        withAnimation(.spring()) {
                            cardOffset = .zero
                        }
                    }
                }
        )
        .onPressGesture(
            onPress: { isPressed = true },
            onRelease: { 
                isPressed = false
                if !isDragging {
                    showingDetails = true
                }
            }
        )
        .sheet(isPresented: $showingDetails) {
            TaskSuggestionDetailView(template: template, moodValue: moodValue)
                .environmentObject(themeManager)
        }
    }
    
    private var leadingContent: some View {
        VStack(spacing: 8) {
            moodCompatibilityIndicator
            difficultyIndicator
        }
    }
    
    private var moodCompatibilityIndicator: some View {
        Circle()
            .fill(compatibilityColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(compatibilityColor.opacity(0.3), lineWidth: 8)
                    .scaleEffect(1.5)
            )
    }
    
    private var compatibilityColor: Color {
        let compatibility = getMoodCompatibility()
        switch compatibility {
        case 0.8...1.0:
            return .green
        case 0.6..<0.8:
            return .orange
        default:
            return .red
        }
    }
    
    private var difficultyIndicator: some View {
        VStack(spacing: 2) {
            ForEach(1...5, id: \.self) { level in
                Rectangle()
                    .fill(level <= template.difficulty ? themeManager.accentColor : Color(.tertiarySystemFill))
                    .frame(width: 3, height: 4)
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text(template.title ?? "Untitled Task")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(themeManager.textPrimaryColor)
                .lineLimit(2)
            
            Spacer()
            
            if let category = template.category {
                Text(getCategoryEmoji(category))
                    .font(.title2)
            }
        }
    }
    
    private var descriptionSection: some View {
        Text(getTemplateDescription(template))
            .font(.subheadline)
            .foregroundColor(themeManager.textSecondaryColor)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
    
    @ViewBuilder
    private var labelsSection: some View {
        if let defaultLabels = template.defaultLabels, !defaultLabels.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(parseLabelString(defaultLabels), id: \.self) { labelName in
                        Text(labelName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(themeManager.accentColor.opacity(0.2))
                            )
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                .padding(.trailing)
            }
        }
    }
    
    private var footerSection: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                Text("\(template.estimatedDuration) min")
                    .font(.caption)
            }
            .foregroundColor(themeManager.textSecondaryColor)
            
            Spacer()
            
//            swipeInstructions
        }
    }
    
    private var swipeInstructions: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.left")
                    .font(.caption2)
                Text("Skip")
                    .font(.caption2)
            }
            .foregroundColor(.red.opacity(0.7))
            
            HStack(spacing: 4) {
                Text("Accept")
                    .font(.caption2)
                Image(systemName: "arrow.right")
                    .font(.caption2)
            }
            .foregroundColor(.green.opacity(0.7))
        }
    }
    
    private var trailingContent: some View {
        VStack(spacing: 12) {
            Button(action: onAccept) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        themeManager.cardBackgroundColor,
                        themeManager.cardBackgroundColor.opacity(0.95)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                themeManager.accentColor.opacity(0.3),
                                themeManager.primaryColor.opacity(0.2)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    // MARK: - Helper Methods
    
    private func getMoodCompatibility() -> Double {
        // Simplified compatibility calculation
        guard let moodRange = template.moodRange else { return 0.5 }
        
        if moodRange.contains("\(moodValue)") {
            return 1.0
        } else if moodRange.contains("-") {
            let components = moodRange.components(separatedBy: "-")
            if components.count == 2,
               let min = Int16(components[0].trimmingCharacters(in: .whitespaces)),
               let max = Int16(components[1].trimmingCharacters(in: .whitespaces)) {
                if moodValue >= min && moodValue <= max {
                    let center = Double(min + max) / 2
                    let distance = abs(Double(moodValue) - center)
                    let maxDistance = Double(max - min) / 2
                    return 1.0 - (distance / maxDistance)
                }
            }
        }
        
        return 0.3
    }
    
    private func getCategoryEmoji(_ category: String) -> String {
        switch category.lowercased() {
        case "cleaning": return "🧹"
        case "exercise": return "🏃‍♂️"
        case "selfcare": return "🧘‍♀️"
        case "creative": return "🎨"
        case "admin": return "📋"
        case "social": return "👥"
        case "learning": return "📚"
        case "work": return "💼"
        default: return "📝"
        }
    }
    
    private func parseLabelString(_ labelString: String) -> [String] {
        labelString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

struct TaskSuggestionDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var themeManager: ColorThemeManager
    @StateObject private var taskEngine = TaskEngine.shared
    
    let template: TaskTemplate
    let moodValue: Int16
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    descriptionSection
                    detailsSection
                    moodCompatibilitySection
                    actionsSection
                }
                .padding()
            }
            .navigationTitle("Task Suggestion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title ?? "Untitled Task")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let category = template.category {
                        Text(category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(themeManager.accentColor.opacity(0.2)))
                            .foregroundColor(themeManager.accentColor)
                    }
                }
                
                Spacer()
                
                VStack(spacing: 8) {
                    difficultyIndicator
                    Text("Difficulty")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .animatedCard()
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
            
            Text(getTemplateDescription(template, defaultText: "No description available."))
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .animatedCard()
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
            
            HStack {
                DetailItem(
                    icon: "clock",
                    title: "Duration",
                    value: "\(template.estimatedDuration) minutes"
                )
                
                Spacer()
                
                DetailItem(
                    icon: "target",
                    title: "Difficulty",
                    value: "\(template.difficulty)/5"
                )
            }
            
            if let moodRange = template.moodRange {
                DetailItem(
                    icon: "heart",
                    title: "Best for moods",
                    value: moodRange
                )
            }
        }
        .padding()
        .animatedCard()
    }
    
    private var moodCompatibilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Compatibility")
                .font(.headline)
            
            HStack {
                Text("Your current mood: \(moodValue)")
                    .font(.subheadline)
                Spacer()
                Text("Match: \(Int(getMoodCompatibility() * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(compatibilityColor)
            }
            
            ProgressView(value: getMoodCompatibility())
                .progressViewStyle(LinearProgressViewStyle(tint: compatibilityColor))
        }
        .padding()
        .animatedCard()
    }
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: acceptSuggestion) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add to My Tasks")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeManager.accentColor)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            
            Button(action: dismissSuggestion) {
                HStack {
                    Image(systemName: "xmark.circle")
                    Text("Not Interested")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    private var difficultyIndicator: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { level in
                Circle()
                    .fill(level <= template.difficulty ? themeManager.accentColor : Color(.tertiarySystemFill))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    private var compatibilityColor: Color {
        let compatibility = getMoodCompatibility()
        switch compatibility {
        case 0.8...1.0: return .green
        case 0.6..<0.8: return .orange
        default: return .red
        }
    }
    
    private func getMoodCompatibility() -> Double {
        // Simplified compatibility calculation (same as in TaskSuggestionCard)
        guard let moodRange = template.moodRange else { return 0.5 }
        
        if moodRange.contains("\(moodValue)") {
            return 1.0
        } else if moodRange.contains("-") {
            let components = moodRange.components(separatedBy: "-")
            if components.count == 2,
               let min = Int16(components[0].trimmingCharacters(in: .whitespaces)),
               let max = Int16(components[1].trimmingCharacters(in: .whitespaces)) {
                if moodValue >= min && moodValue <= max {
                    let center = Double(min + max) / 2
                    let distance = abs(Double(moodValue) - center)
                    let maxDistance = Double(max - min) / 2
                    return 1.0 - (distance / maxDistance)
                }
            }
        }
        
        return 0.3
    }
    
    private func acceptSuggestion() {
        
        do {
            try viewContext.save()
            taskEngine.recordAcceptance(suggestionId: UUID(), context: viewContext)
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error creating task: \(error)")
        }
    }
    
    private func dismissSuggestion() {
        presentationMode.wrappedValue.dismiss()
    }
}

struct DetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Press Gesture Extension

extension View {
    func onPressGesture(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

