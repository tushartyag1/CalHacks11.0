//
//  TripPreferencesView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//


import SwiftUI

struct TripPreferencesView: View {
    let tripId: String
    let userId: String
    @State private var budget: Double = 1000
    @State private var paceOfTravel: PaceOfTravel = .medium
    @State private var cuisinePreferences: Set<Cuisine> = []
    @State private var crowdPreference: CrowdPreference = .medium
    @State private var transportationPreference: TransportationPreference = .publicTransport
    @State private var dailyStartTime = Date()
    @State private var dailyEndTime = Date()
    @State private var activityPreferences: Set<ActivityPreference> = []
    @State private var customItineraryAdditions: String = ""
    @State private var navigateToItinerary = false
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = TripPreferencesViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    budgetSection
                    paceOfTravelSection
                    cuisinePreferencesSection
                    crowdPreferenceSection
                    transportationPreferenceSection
                    dailyScheduleSection
                    activityPreferencesSection
                    customItinerarySection
                    
                    NavigationLink(destination: GeneratedItineraryView(itinerary: viewModel.generatedItinerary), isActive: $navigateToItinerary) {
                        EmptyView()
                    }
                    
                    Button(action: submitPreferences) {
                        Text("Submit Preferences")
                            .font(.custom("ClashDisplay-Semibold", size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.pastelGreen)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                    .padding(.top, 24)
                }
                .padding()
            }
            .navigationTitle("Trip Preferences")
            .background(Color.pastelBackground.ignoresSafeArea())
        }
    }
    
    private var budgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Budget")
                .font(.custom("ClashDisplay-Semibold", size: 24))
            
            PastelSlider(value: $budget, range: 100...10000, step: 100)
            
            Text("$\(Int(budget))")
                .font(.custom("ClashDisplay-Medium", size: 18))
                .foregroundColor(.pastelBlue)
        }
    }
    
    private var paceOfTravelSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pace of Travel")
                .font(.custom("ClashDisplay-Semibold", size: 24))
            
            HStack {
                ForEach(PaceOfTravel.allCases, id: \.self) { pace in
                    PastelToggle(
                        title: pace.rawValue,
                        isSelected: paceOfTravel == pace,
                        action: { paceOfTravel = pace }
                    )
                }
            }
        }
    }
    
    private var cuisinePreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cuisine Preferences")
                .font(.custom("ClashDisplay-Semibold", size: 24))
            
            FlowLayout(spacing: 8) {
                ForEach(Cuisine.allCases, id: \.self) { cuisine in
                    PastelToggle(
                        title: cuisine.rawValue,
                        isSelected: cuisinePreferences.contains(cuisine),
                        action: {
                            if cuisinePreferences.contains(cuisine) {
                                cuisinePreferences.remove(cuisine)
                            } else {
                                cuisinePreferences.insert(cuisine)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var crowdPreferenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crowd Preference")
                .font(.custom("ClashDisplay-Semibold", size: 24))
            
            HStack {
                ForEach(CrowdPreference.allCases, id: \.self) { preference in
                    PastelToggle(
                        title: preference.rawValue,
                        isSelected: crowdPreference == preference,
                        action: { crowdPreference = preference }
                    )
                }
            }
        }
    }
    
    private var transportationPreferenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transportation Preference")
                .font(.custom("ClashDisplay-Semibold", size: 24))
            
            FlowLayout(spacing: 8) {
                ForEach(TransportationPreference.allCases, id: \.self) { preference in
                    PastelToggle(
                        title: preference.rawValue,
                        isSelected: transportationPreference == preference,
                        action: { transportationPreference = preference }
                    )
                }
            }
        }
    }
    
    private var dailyScheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Schedule")
                .font(.custom("ClashDisplay-Semibold", size: 24))
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Start Time")
                        .font(.custom("ClashDisplay-Regular", size: 16))
                    DatePicker("", selection: $dailyStartTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("End Time")
                        .font(.custom("ClashDisplay-Regular", size: 16))
                    DatePicker("", selection: $dailyEndTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                }
            }
        }
    }
    
    private var activityPreferencesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Preferences")
                .font(.custom("ClashDisplay-Semibold", size: 24))
            
            FlowLayout(spacing: 8) {
                ForEach(ActivityPreference.allCases, id: \.self) { activity in
                    PastelToggle(
                        title: activity.rawValue,
                        isSelected: activityPreferences.contains(activity),
                        action: {
                            if activityPreferences.contains(activity) {
                                activityPreferences.remove(activity)
                            } else {
                                activityPreferences.insert(activity)
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var customItinerarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Itinerary Additions")
                .font(.custom("ClashDisplay-Semibold", size: 24))
            
            TextEditor(text: $customItineraryAdditions)
                .font(.custom("ClashDisplay-Regular", size: 16))
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.pastelGray, lineWidth: 1)
                )
        }
    }
    
    func submitPreferences() {
        print("Submitting preferences...")
        let selectedPreferences = TripPreferencesData(
            budget: budget,
            paceOfTravel: paceOfTravel.rawValue,
            cuisinePreferences: Array(cuisinePreferences.map { $0.rawValue }),
            crowdPreference: crowdPreference.rawValue,
            transportationPreference: transportationPreference.rawValue,
            dailyStartTime: dailyStartTime,
            dailyEndTime: dailyEndTime,
            activityPreferences: Array(activityPreferences.map { $0.rawValue }),
            customItineraryAdditions: customItineraryAdditions
        )
        
        viewModel.saveTripDetails(
            userId: userId,
            tripId: tripId,
            preferences: selectedPreferences
        ) { error in
            if let error = error {
                print("Error in submitPreferences: \(error.localizedDescription)")
            } else {
                print("Trip details saved and itinerary generated successfully")
                DispatchQueue.main.async {
                    self.navigateToItinerary = true
                }
            }
        }
    }
}

struct PastelSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.pastelBlue.opacity(0.3))
                    .frame(height: 8)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.pastelBlue)
                    .frame(width: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * geometry.size.width, height: 8)
                    .cornerRadius(4)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 28, height: 28)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .offset(x: CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound)) * (geometry.size.width - 28))
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                let newValue = Double(gesture.location.x / geometry.size.width) * (range.upperBound - range.lowerBound) + range.lowerBound
                                value = min(max(newValue, range.lowerBound), range.upperBound)
                                value = round(value / step) * step
                            }
                    )
            }
        }
        .frame(height: 28)
    }
}

struct PastelToggle: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("ClashDisplay-Regular", size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.pastelPink : Color.pastelGray)
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposal: proposal)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var origin = bounds.origin
        var maxY: CGFloat = 0
        
        for (index, size) in sizes.enumerated() {
            if origin.x + size.width > bounds.maxX {
                origin.x = bounds.origin.x
                origin.y = maxY + spacing
            }
            
            subviews[index].place(at: origin, proposal: .unspecified)
            origin.x += size.width + spacing
            maxY = max(maxY, origin.y + size.height)
        }
    }
    
    private func layout(sizes: [CGSize], proposal: ProposedViewSize) -> CGSize {
        var origin = CGPoint.zero
        var maxY: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for size in sizes {
            if origin.x + size.width > maxWidth {
                origin.x = 0
                origin.y = maxY + spacing
            }
            
            origin.x += size.width + spacing
            maxY = max(maxY, origin.y + size.height)
        }
        
        return CGSize(width: maxWidth, height: maxY)
    }
}

extension Color {
    static let pastelBlue = Color(red: 173/255, green: 216/255, blue: 230/255)
    static let pastelPink = Color(red: 255/255, green: 182/255, blue: 193/255)
    static let pastelGreen = Color(red: 152/255, green: 251/255, blue: 152/255)
    static let pastelGray = Color(red: 211/255, green: 211/255, blue: 211/255)
    static let pastelBackground = Color(red: 250/255, green: 250/255, blue: 250/255)
}

class TripPreferencesViewModel: ObservableObject {
    private let tripDetailsManager = TripDetailsManager()
    private let geminiService = GeminiService()
    @Published var generatedItinerary: [ItineraryDay] = []
    
    func saveTripDetails(userId: String, tripId: String, preferences: TripPreferencesData, completion: @escaping (Error?) -> Void) {
        print("Saving trip details...")
        tripDetailsManager.saveTripDetails(
            userId: userId,
            tripId: tripId,
            budget: preferences.budget,
            interests: preferences.cuisinePreferences,
            preferences: Dictionary(uniqueKeysWithValues: preferences.activityPreferences.map { ($0, true) }),
            paceOfTravel: preferences.paceOfTravel,
            crowdPreference: preferences.crowdPreference,
            transportationPreference: preferences.transportationPreference,
            dailyStartTime: preferences.dailyStartTime,
            dailyEndTime: preferences.dailyEndTime,
            customItineraryAdditions: preferences.customItineraryAdditions
        ) { [weak self] error in
            if let error = error {
                print("Error saving trip details: \(error.localizedDescription)")
                completion(error)
            } else {
                print("Trip details saved successfully. Generating itinerary...")
                self?.generateItinerary(preferences: preferences) { generatedError in
                    completion(generatedError)
                }
            }
        }
    }
    
    private func generateItinerary(preferences: TripPreferencesData, completion: @escaping (Error?) -> Void) {
        print("Starting itinerary generation...")
        geminiService.generateItinerary(preferences: preferences) { [weak self] result in
            switch result {
            case .success(let itinerary):
                print("Itinerary generated successfully. Number of days: \(itinerary.count)")
                DispatchQueue.main.async {
                    self?.generatedItinerary = itinerary
                    completion(nil)
                }
            case .failure(let error):
                print("Failed to generate itinerary: \(error.localizedDescription)")
                completion(error)
            }
        }
    }
}

enum PaceOfTravel: String, CaseIterable {
    case slow = "Slow"
    case medium = "Medium"
    case fast = "Fast"
}

enum Cuisine: String, CaseIterable {
    case chinese = "Chinese"
    case japanese = "Japanese"
    case european = "European"
    case mediterranean = "Mediterranean"
    case indian = "Indian"
    case american = "American"
    case italian = "Italian"
    case mexican = "Mexican"
    case thai = "Thai"
    case local = "Local"
}

enum CrowdPreference: String, CaseIterable {
    case empty = "Empty"
    case medium = "Medium"
    case busy = "Busy"
}

enum TransportationPreference: String, CaseIterable {
    case uber = "Uber"
    case rentalCar = "Rental Car"
    case publicTransport = "Public Transport"
    case walk = "Walk"
    case bike = "Bike"
}

enum ActivityPreference: String, CaseIterable {
    case landAdventure = "Land-based Adventure"
    case waterAdventure = "Water-based Adventure"
    case airAdventure = "Air-based Adventure"
    case museums = "Museums"
    case localMarkets = "Local Markets"
    case localRestaurants = "Local Restaurants"
    case malls = "Malls"
    case bars = "Bars"
    case parties = "Parties"
    case cityExplorer = "City Explorer"
}

struct TripPreferencesData: Codable {
    let budget: Double
    let paceOfTravel: String
    let cuisinePreferences: [String]
    let crowdPreference: String
    let transportationPreference: String
    let dailyStartTime: Date
    let dailyEndTime: Date
    let activityPreferences: [String]
    let customItineraryAdditions: String
}









