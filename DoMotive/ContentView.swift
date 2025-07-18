//
//  ContentView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Image(systemName: "house"); Text("Home") }
            TaskListView()
                .tabItem { Image(systemName: "checkmark.circle"); Text("Tasks") }
            MoodListView()
                .tabItem { Image(systemName: "smiley"); Text("Mood") }
            JournalListView()
                .tabItem { Image(systemName: "book"); Text("Journal") }
        }
    }
}
