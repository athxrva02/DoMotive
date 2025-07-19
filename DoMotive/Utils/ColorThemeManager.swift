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
    
    @Published var currentTheme: AppTheme = .default
    @Published var currentMoodValue: Int16 = 5
    
    private init() {}
    
    // MARK: - Theme Management
    
    func updateTheme(for moodValue: Int16) {
        currentMoodValue = moodValue
        currentTheme = getTheme(for: moodValue)
    }
    
    func getTheme(for moodValue: Int16) -> AppTheme {
        switch moodValue {
        case 1...2:
            return .lowMood
        case 3...4:
            return .sadMood
        case 5...6:
            return .neutral
        case 7...8:
            return .goodMood
        case 9...10:
            return .euphoric
        default:
            return .default
        }
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
    let name: String
    
    // MARK: - Predefined Themes
    
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
        name: "Default"
    )
    
    static let lowMood = AppTheme(
        primaryColor: Color(red: 0.5, green: 0.5, blue: 0.6), // Muted blue-gray
        secondaryColor: Color(red: 0.6, green: 0.5, blue: 0.7), // Soft purple
        accentColor: Color(red: 0.7, green: 0.6, blue: 0.8), // Light lavender
        backgroundColor: Color(.systemBackground),
        cardBackgroundColor: Color(.tertiarySystemBackground),
        gradientColors: [
            Color(red: 0.5, green: 0.5, blue: 0.6),
            Color(red: 0.6, green: 0.5, blue: 0.7)
        ],
        textPrimaryColor: Color(.label),
        textSecondaryColor: Color(.secondaryLabel),
        name: "Comfort"
    )
    
    static let sadMood = AppTheme(
        primaryColor: Color(red: 0.6, green: 0.6, blue: 0.7), // Soft gray
        secondaryColor: Color(red: 0.7, green: 0.6, blue: 0.6), // Warm gray
        accentColor: Color(red: 0.8, green: 0.7, blue: 0.6), // Beige
        backgroundColor: Color(.systemBackground),
        cardBackgroundColor: Color(.secondarySystemBackground),
        gradientColors: [
            Color(red: 0.6, green: 0.6, blue: 0.7),
            Color(red: 0.7, green: 0.6, blue: 0.6)
        ],
        textPrimaryColor: Color(.label),
        textSecondaryColor: Color(.secondaryLabel),
        name: "Gentle"
    )
    
    static let neutral = AppTheme(
        primaryColor: Color(red: 0.29, green: 0.56, blue: 0.89), // Standard blue
        secondaryColor: Color(red: 0.31, green: 0.78, blue: 0.47), // Standard green
        accentColor: Color(red: 0.27, green: 0.72, blue: 0.88), // Standard accent
        backgroundColor: Color(.systemBackground),
        cardBackgroundColor: Color(.secondarySystemBackground),
        gradientColors: [
            Color(red: 0.29, green: 0.56, blue: 0.89),
            Color(red: 0.31, green: 0.78, blue: 0.47)
        ],
        textPrimaryColor: Color(.label),
        textSecondaryColor: Color(.secondaryLabel),
        name: "Balanced"
    )
    
    static let goodMood = AppTheme(
        primaryColor: Color(red: 0.2, green: 0.7, blue: 0.4), // Vibrant green
        secondaryColor: Color(red: 0.3, green: 0.8, blue: 0.9), // Bright cyan
        accentColor: Color(red: 0.9, green: 0.7, blue: 0.2), // Sunny yellow
        backgroundColor: Color(.systemBackground),
        cardBackgroundColor: Color(.secondarySystemBackground),
        gradientColors: [
            Color(red: 0.2, green: 0.7, blue: 0.4),
            Color(red: 0.3, green: 0.8, blue: 0.9)
        ],
        textPrimaryColor: Color(.label),
        textSecondaryColor: Color(.secondaryLabel),
        name: "Energetic"
    )
    
    static let euphoric = AppTheme(
        primaryColor: Color(red: 0.9, green: 0.2, blue: 0.6), // Vibrant pink
        secondaryColor: Color(red: 0.2, green: 0.8, blue: 0.9), // Electric blue
        accentColor: Color(red: 0.9, green: 0.6, blue: 0.1), // Golden orange
        backgroundColor: Color(.systemBackground),
        cardBackgroundColor: Color(.secondarySystemBackground),
        gradientColors: [
            Color(red: 0.9, green: 0.2, blue: 0.6),
            Color(red: 0.2, green: 0.8, blue: 0.9),
            Color(red: 0.9, green: 0.6, blue: 0.1)
        ],
        textPrimaryColor: Color(.label),
        textSecondaryColor: Color(.secondaryLabel),
        name: "Radiant"
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