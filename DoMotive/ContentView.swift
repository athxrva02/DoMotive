//
//  ContentView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ColorThemeManager
    @State private var selectedTab = 0
    @State private var previousTab = 0
    
    var body: some View {
        ZStack {
            // Background gradient that responds to mood
            themeManager.backgroundGradient
                .opacity(0.05)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.8), value: themeManager.currentTheme.name)
            
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem { 
                        TabItemView(icon: "house.fill", title: "Home", isSelected: selectedTab == 0)
                    }
                    .tag(0)
                
                TaskListView()
                    .tabItem { 
                        TabItemView(icon: "checkmark.circle.fill", title: "Tasks", isSelected: selectedTab == 1)
                    }
                    .tag(1)
                
                SuggestionView()
                    .tabItem { 
                        TabItemView(icon: "lightbulb.fill", title: "Suggestions", isSelected: selectedTab == 2)
                    }
                    .tag(2)
                
                MoodListView()
                    .tabItem { 
                        TabItemView(icon: "heart.fill", title: "Mood", isSelected: selectedTab == 3)
                    }
                    .tag(3)
                
                JournalListView()
                    .tabItem { 
                        TabItemView(icon: "book.fill", title: "Journal", isSelected: selectedTab == 4)
                    }
                    .tag(4)
            }
            .accentColor(themeManager.accentColor)
            .onChange(of: selectedTab) { newValue in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    previousTab = newValue
                }
            }
        }
        .preferredColorScheme(.none) // Let the app handle its own theming
    }
}

struct TabItemView: View {
    let icon: String
    let title: String
    let isSelected: Bool
    @EnvironmentObject var themeManager: ColorThemeManager
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: isSelected ? 24 : 20))
                .foregroundColor(isSelected ? themeManager.accentColor : .secondary)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            
            Text(title)
                .font(.caption2)
                .fontWeight(isSelected ? .medium : .regular)
                .foregroundColor(isSelected ? themeManager.accentColor : .secondary)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ColorThemeManager.shared)
}
