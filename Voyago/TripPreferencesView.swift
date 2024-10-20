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
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = TripPreferencesViewModel()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Budget")) {
                    Slider(value: $budget, in: 100...10000, step: 100)
                    Text("$\(Int(budget))")
                }
                
                Section(header: Text("Pace of Travel")) {
                    Picker("Pace", selection: $paceOfTravel) {
                        ForEach(PaceOfTravel.allCases, id: \.self) { pace in
                            Text(pace.rawValue).tag(pace)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Cuisine Preferences")) {
                    ForEach(Cuisine.allCases, id: \.self) { cuisine in
                        Toggle(cuisine.rawValue, isOn: Binding(
                            get: { cuisinePreferences.contains(cuisine) },
                            set: { newValue in
                                if newValue {
                                    cuisinePreferences.insert(cuisine)
                                } else {
                                    cuisinePreferences.remove(cuisine)
                                }
                            }
                        ))
                    }
                }
                
                Section(header: Text("Crowd Preference")) {
                    Picker("Crowds", selection: $crowdPreference) {
                        ForEach(CrowdPreference.allCases, id: \.self) { preference in
                            Text(preference.rawValue).tag(preference)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Transportation Preference")) {
                    Picker("Transportation", selection: $transportationPreference) {
                        ForEach(TransportationPreference.allCases, id: \.self) { preference in
                            Text(preference.rawValue).tag(preference)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Daily Schedule")) {
                    DatePicker("Start Time", selection: $dailyStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("End Time", selection: $dailyEndTime, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("Activity Preferences")) {
                    ForEach(ActivityPreference.allCases, id: \.self) { activity in
                        Toggle(activity.rawValue, isOn: Binding(
                            get: { activityPreferences.contains(activity) },
                            set: { newValue in
                                if newValue {
                                    activityPreferences.insert(activity)
                                } else {
                                    activityPreferences.remove(activity)
                                }
                            }
                        ))
                    }
                }
                
                Section(header: Text("Custom Itinerary Additions")) {
                    TextEditor(text: $customItineraryAdditions)
                        .frame(height: 100)
                }
            }
            .navigationTitle("Trip Preferences")
            .navigationBarItems(trailing: Button("Submit") {
                submitPreferences()
            })
        }
    }
    
    func submitPreferences() {
        viewModel.saveTripDetails(
            userId: userId,
            tripId: tripId,
            budget: budget,
            paceOfTravel: paceOfTravel,
            cuisinePreferences: Array(cuisinePreferences),
            crowdPreference: crowdPreference,
            transportationPreference: transportationPreference,
            dailyStartTime: dailyStartTime,
            dailyEndTime: dailyEndTime,
            activityPreferences: Array(activityPreferences),
            customItineraryAdditions: customItineraryAdditions
        ) { error in
            if let error = error {
                print("Error saving trip details: \(error.localizedDescription)")
            } else {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

class TripPreferencesViewModel: ObservableObject {
    private let tripDetailsManager = TripDetailsManager()
    
    func saveTripDetails(userId: String, tripId: String, budget: Double, paceOfTravel: PaceOfTravel, cuisinePreferences: [Cuisine], crowdPreference: CrowdPreference, transportationPreference: TransportationPreference, dailyStartTime: Date, dailyEndTime: Date, activityPreferences: [ActivityPreference], customItineraryAdditions: String, completion: @escaping (Error?) -> Void) {
        let preferences: [String: Bool] = Dictionary(uniqueKeysWithValues: ActivityPreference.allCases.map { ($0.rawValue, activityPreferences.contains($0)) })
        
        tripDetailsManager.saveTripDetails(
            userId: userId,
            tripId: tripId,
            budget: budget,
            interests: cuisinePreferences.map { $0.rawValue },
            preferences: preferences,
            paceOfTravel: paceOfTravel.rawValue,
            crowdPreference: crowdPreference.rawValue,
            transportationPreference: transportationPreference.rawValue,
            dailyStartTime: dailyStartTime,
            dailyEndTime: dailyEndTime,
            customItineraryAdditions: customItineraryAdditions
        ) { error in
            if let error = error {
                print("Error saving trip details: \(error.localizedDescription)")
                // Handle the error (e.g., show an alert to the user)
            } else {
                print("Trip details saved successfully")
                // Handle successful save (e.g., navigate to the next screen)
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
