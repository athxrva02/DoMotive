//
//  ColorThemeManager.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import SwiftUI
import CoreData

class ColorThemeManager: ObservableObject {
    static let shared = ColorThemeManager()
    
    @Published var currentTheme: AppTheme = .unified
    @Published var currentMoodValue: Int16 = 5
    
    private init() {}
    
    // MARK: - Theme Management (Simplified)
    
    func updateTheme(for moodValue: Int16) {
        currentMoodValue = moodValue
        // Keep mood tracking but use consistent theme
        currentTheme = .unified
    }
    
    func getTheme(for moodValue: Int16) -> AppTheme {
        // Always return unified theme regardless of mood
        return .unified
    }
    
    // MARK: - Color Accessors
    
    var primaryColor: Color {
        currentTheme.primaryColor
    }
    
    var secondaryColor: Color {
        currentTheme.secondaryColor
    }
    
    var accentColor: Color {
        currentTheme.accentColor
    }
    
    var backgroundColor: Color {
        currentTheme.backgroundColor
    }
    
    var cardBackgroundColor: Color {
        currentTheme.cardBackgroundColor
    }
    
    var gradientColors: [Color] {
        currentTheme.gradientColors
    }
    
    var textPrimaryColor: Color {
        currentTheme.textPrimaryColor
    }
    
    var textSecondaryColor: Color {
        currentTheme.textSecondaryColor
    }
    
    // MARK: - Semantic Colors
    
    var successColor: Color {
        currentTheme.successColor
    }
    
    var warningColor: Color {
        currentTheme.warningColor
    }
    
    var surfaceColor: Color {
        currentTheme.surfaceColor
    }
    
    var onSurfaceColor: Color {
        currentTheme.onSurfaceColor
    }
    
    // MARK: - Dynamic Gradients
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var cardGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [cardBackgroundColor, cardBackgroundColor.opacity(0.8)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Animation Support
    
    func animateThemeChange() {
        withAnimation(.easeInOut(duration: 0.6)) {
            // Theme change will automatically trigger UI updates
        }
    }
    
    // MARK: - Mood-Specific Helpers
    
    func getMoodAccentColor(for value: Int16) -> Color {
        switch value {
        case 1...2: return Color(red: 0.7, green: 0.3, blue: 0.3) // Muted red
        case 3...4: return Color(red: 0.8, green: 0.6, blue: 0.4) // Orange-brown
        case 5...6: return Color(red: 0.4, green: 0.6, blue: 0.8) // Blue
        case 7...8: return Color(red: 0.3, green: 0.7, blue: 0.5) // Green
        case 9...10: return Color(red: 0.9, green: 0.6, blue: 0.2) // Golden
        default: return .blue
        }
    }
    
    func getProgressColor(for progress: Double) -> Color {
        let red = min(1.0, 2.0 * (1.0 - progress))
        let green = min(1.0, 2.0 * progress)
        return Color(red: red, green: green, blue: 0.2)
    }
}

// MARK: - App Theme Definition

struct AppTheme {
    let primaryColor: Color
    let secondaryColor: Color
    let accentColor: Color
    let backgroundColor: Color
    let cardBackgroundColor: Color
    let gradientColors: [Color]
    let textPrimaryColor: Color
    let textSecondaryColor: Color
    let successColor: Color
    let warningColor: Color
    let surfaceColor: Color
    let onSurfaceColor: Color
    let name: String
    
    // MARK: - Predefined Themes
    
    static let unified = AppTheme(
        primaryColor: Color(red: 0.39, green: 0.4, blue: 0.945), // #6366F1 - Soft Indigo
        secondaryColor: Color(red: 0.925, green: 0.286, blue: 0.6), // #EC4899 - Warm Pink
        accentColor: Color(red: 0.39, green: 0.4, blue: 0.945), // #6366F1 - Soft Indigo
        backgroundColor: Color(.systemBackground),
        cardBackgroundColor: Color(.systemGroupedBackground),
        gradientColors: [
            Color(red: 0.39, green: 0.4, blue: 0.945),
            Color(red: 0.925, green: 0.286, blue: 0.6)
        ],
        textPrimaryColor: Color(.label),
        textSecondaryColor: Color(.secondaryLabel),
        successColor: Color(red: 0.063, green: 0.725, blue: 0.506), // #10B981 - Forest Green
        warningColor: Color(red: 0.961, green: 0.616, blue: 0.043), // #F59E0B - Warm Amber
        surfaceColor: Color(.secondarySystemGroupedBackground),
        onSurfaceColor: Color(.label),
        name: "Unified"
    )
    
    static let `default` = AppTheme(
        primaryColor: Color(red: 0.29, green: 0.56, blue: 0.89), // #4A90E2
        secondaryColor: Color(red: 0.31, green: 0.78, blue: 0.47), // #50C878
        accentColor: Color(red: 0.27, green: 0.72, blue: 0.88), // #45B7D1
        backgroundColor: Color(.systemBackground),
        cardBackgroundColor: Color(.secondarySystemBackground),
        gradientColors: [
            Color(red: 0.29, green: 0.56, blue: 0.89),
            Color(red: 0.31, green: 0.78, blue: 0.47)
        ],
        textPrimaryColor: Color(.label),
        textSecondaryColor: Color(.secondaryLabel),
        successColor: Color(red: 0.063, green: 0.725, blue: 0.506),
        warningColor: Color(red: 0.961, green: 0.616, blue: 0.043),
        surfaceColor: Color(.secondarySystemGroupedBackground),
        onSurfaceColor: Color(.label),
        name: "Default"
    )
    
    // Note: Keeping mood-based themes for potential future use, but app will use unified theme
    static let lowMood = AppTheme(
        primaryColor: Color(red: 0.5, green: 0.5, blue: 0.6),
        secondaryColor: Color(red: 0.6, green: 0.5, blue: 0.7),
        accentColor: Color(red: 0.7, green: 0.6, blue: 0.8),
        backgroundColor: Color(.systemBackground),
        cardBackgroundColor: Color(.tertiarySystemBackground),
        gradientColors: [Color(red: 0.5, green: 0.5, blue: 0.6), Color(red: 0.6, green: 0.5, blue: 0.7)],
        textPrimaryColor: Color(.label),
        textSecondaryColor: Color(.secondaryLabel),
        successColor: Color(red: 0.063, green: 0.725, blue: 0.506),
        warningColor: Color(red: 0.961, green: 0.616, blue: 0.043),
        surfaceColor: Color(.secondarySystemGroupedBackground),
        onSurfaceColor: Color(.label),
        name: "Comfort"
    )
}

// MARK: - Theme-Aware ViewModifier

struct ThemeAware: ViewModifier {
    @StateObject private var themeManager = ColorThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .environmentObject(themeManager)
    }
}

extension View {
    func themeAware() -> some View {
        modifier(ThemeAware())
    }
}

// MARK: - Mood-Responsive Background ViewModifier

struct MoodResponsiveBackground: ViewModifier {
    @EnvironmentObject var themeManager: ColorThemeManager
    let opacity: Double
    
    init(opacity: Double = 0.1) {
        self.opacity = opacity
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                themeManager.backgroundGradient
                    .opacity(opacity)
                    .animation(.easeInOut(duration: 0.6), value: themeManager.currentMoodValue)
            )
    }
}

extension View {
    func moodResponsiveBackground(opacity: Double = 0.1) -> some View {
        modifier(MoodResponsiveBackground(opacity: opacity))
    }
}

// MARK: - Animated Card ViewModifier

struct AnimatedCard: ViewModifier {
    @EnvironmentObject var themeManager: ColorThemeManager
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    
    init(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(themeManager.cardBackgroundColor)
                    .shadow(
                        color: themeManager.primaryColor.opacity(0.2),
                        radius: shadowRadius,
                        x: 0, y: 4
                    )
            )
            .animation(.easeInOut(duration: 0.3), value: themeManager.currentTheme.name)
    }
}

extension View {
    func animatedCard(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 8) -> some View {
        modifier(AnimatedCard(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}