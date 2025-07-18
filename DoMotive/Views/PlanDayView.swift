//
//  PlanDayView.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

// PlanDayView.swift
import SwiftUI

struct PlanDayView: View {
    @Environment(\.presentationMode) var presentation

    // Use CoreData or app state for tasks/moods if needed here

    @State private var aiPlan: String = "" // Simulated plan output
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 28) {
                Text("AI Day Planner")
                    .font(.largeTitle).bold()

                Text("Let DoMotive suggest a schedule for your day based on your tasks and mood.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                Button(action: {
                    getAISchedule()
                }) {
                    HStack {
                        if isLoading {
                            ProgressView().padding(.trailing, 6)
                        }
                        Text(isLoading ? "Planning..." : "Plan My Day")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading)

                if !aiPlan.isEmpty {
                    ScrollView {
                        Text(aiPlan)
                            .font(.body)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
                    }
                    .padding(.top, 20)
                }

                Spacer()
            }
            .padding()
            .navigationBarTitle("Plan Day", displayMode: .inline)
            .navigationBarItems(leading: Button("Close") { presentation.wrappedValue.dismiss() })
        }
    }

    func getAISchedule() {
        // Placeholder for AI/LLM integration
        isLoading = true
        aiPlan = ""
        // Simulate API call (replace with real Gemini call in future)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            aiPlan = """
            9:00 AM – Review top 3 to-dos\n
            10:00 AM – Focus on tasks labeled 'Creative'\n
            12:00 PM – Lunch break\n
            1:00 PM – Free period or personal task\n
            3:00 PM – Finish up and log mood for the day
            """
            isLoading = false
        }
    }
}
