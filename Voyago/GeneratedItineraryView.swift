//
//  GeneratedItineraryView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/20/24.
//

import SwiftUI

struct GeneratedItineraryView: View {
    let itinerary: [ItineraryDay]
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(itinerary, id: \.id) { day in
                    DayItineraryCard(day: day)
                }
            }
            .padding()
        }
        .navigationBarBackButtonHidden()
        .onAppear {
            print("GeneratedItineraryView appeared")
            print("Number of days in itinerary: \(itinerary.count)")
            for (index, day) in itinerary.enumerated() {
                print("Day \(index + 1) activities: \(day.activities.count)")
            }
        }
    }
}

struct DayItineraryCard: View {
    let day: ItineraryDay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day.date.formatted(date: .long, time: .omitted))
                .font(.custom("ClashDisplay-Semibold", size: 20))
            
            ForEach(day.activities) { activity in
                ActivityRow(activity: activity)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct ActivityRow: View {
    let activity: ItineraryActivity
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text(activity.time)
                    .font(.custom("ClashDisplay-Medium", size: 16))
                Text(activity.name)
                    .font(.custom("ClashDisplay-Regular", size: 14))
                Text(activity.description)
                    .font(.custom("ClashDisplay-Regular", size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let imageURL = activity.imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                } placeholder: {
                    Color.gray
                        .frame(width: 60, height: 60)
                        .cornerRadius(8)
                }
            }
        }
    }
}

struct ItineraryDay: Identifiable {
    let id = UUID()
    let date: Date
    let activities: [ItineraryActivity]
}

struct ItineraryActivity: Identifiable {
    let id = UUID()
    let time: String
    let name: String
    let description: String
    let imageURL: URL?
}

import SwiftUI
import GoogleGenerativeAI

class GeminiService {
    private let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.default)
    
    func generateItinerary(preferences: TripPreferencesData, completion: @escaping (Result<[ItineraryDay], Error>) -> Void) {
        let prompt = createPrompt(from: preferences)
        
        Task {
            do {
                let result = try await model.generateContent(prompt)
                if let generatedText = result.text {
                    let itinerary = parseItinerary(from: generatedText)
                    completion(.success(itinerary))
                } else {
                    completion(.failure(NSError(domain: "GeminiService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate itinerary"])))
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private func createPrompt(from preferences: TripPreferencesData) -> String {
        return """
        Generate a detailed 3-day itinerary based on the following preferences:
        Budget: $\(Int(preferences.budget))
        Pace of Travel: \(preferences.paceOfTravel)
        Cuisine Preferences: \(preferences.cuisinePreferences.joined(separator: ", "))
        Crowd Preference: \(preferences.crowdPreference)
        Transportation Preference: \(preferences.transportationPreference)
        Daily Start Time: \(formatTime(preferences.dailyStartTime))
        Daily End Time: \(formatTime(preferences.dailyEndTime))
        Activity Preferences: \(preferences.activityPreferences.joined(separator: ", "))
        Custom Additions: \(preferences.customItineraryAdditions)

        Please provide a detailed itinerary for each day, including specific times, activities, and brief descriptions. Format the response as follows:

        Day 1:
        - 09:00 AM: Activity 1 | Brief description
        - 11:00 AM: Activity 2 | Brief description
        ...

        Day 2:
        ...

        Day 3:
        ...
        """
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func parseItinerary(from generatedText: String) -> [ItineraryDay] {
        let lines = generatedText.components(separatedBy: .newlines)
        var itinerary: [ItineraryDay] = []
        var currentDay: ItineraryDay?
        var currentActivities: [ItineraryActivity] = []
        
        for line in lines {
            if line.starts(with: "Day") {
                if let currentDay = currentDay {
                    itinerary.append(ItineraryDay(date: currentDay.date, activities: currentActivities))
                }
                currentDay = ItineraryDay(date: Date(), activities: [])
                currentActivities = []
            } else if line.contains(":") {
                let components = line.components(separatedBy: ":")
                if components.count >= 2 {
                    let time = components[0].trimmingCharacters(in: .whitespaces)
                    let rest = components[1...].joined(separator: ":").trimmingCharacters(in: .whitespaces)
                    let activityComponents = rest.components(separatedBy: "|")
                    let name = activityComponents[0].trimmingCharacters(in: .whitespaces)
                    let description = activityComponents.count > 1 ? activityComponents[1].trimmingCharacters(in: .whitespaces) : ""
                    
                    let activity = ItineraryActivity(time: time, name: name, description: description, imageURL: nil)
                    currentActivities.append(activity)
                }
            }
        }
        
        if let currentDay = currentDay {
            itinerary.append(ItineraryDay(date: currentDay.date, activities: currentActivities))
        }
        
        return itinerary
    }
}
