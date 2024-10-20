//
//  CreateTripView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import FirebaseAuth
import GooglePlaces

// MARK: - CreateTripView

struct CreateTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = CreateTripViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                searchSection
                selectedPlaceSection
                tripDetailsSection
                createTripButton
                
                if !viewModel.invitations.isEmpty {
                    Section(header: Text("Invitations Sent")) {
                        ForEach(viewModel.invitations, id: \.self) { email in
                            Text(email)
                        }
                    }
                }
            }
            .navigationTitle("Create Trip")
            .alert(item: $viewModel.errorWrapper) { errorWrapper in
                Alert(title: Text("Error"), message: Text(errorWrapper.error), dismissButton: .default(Text("OK")))
            }
        }
        .sheet(isPresented: $viewModel.showingInviteView) {
            InviteFriendsView(tripId: viewModel.tripId) { email, completion in
                viewModel.inviteFriend(email: email, completion: completion)
            }
        }
    }
    
    private var searchSection: some View {
        Section(header: Text("Search for a City")) {
            TextField("Enter city name", text: $viewModel.searchText)
                .onChange(of: viewModel.searchText) { newValue in
                    viewModel.searchPlaces(query: newValue)
                }
            
            if !viewModel.predictions.isEmpty {
                ForEach(viewModel.predictions, id: \.placeID) { prediction in
                    Button(action: {
                        viewModel.fetchPlaceDetails(placeID: prediction.placeID)
                    }) {
                        VStack(alignment: .leading) {
                            Text(prediction.attributedPrimaryText.string)
                                .font(.headline)
                            Text(prediction.attributedSecondaryText?.string ?? "")
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
    }
    
    private var selectedPlaceSection: some View {
        Group {
            if let place = viewModel.selectedPlace {
                Section(header: Text("Selected City")) {
                    Text(place.name ?? "")
                    Text(place.formattedAddress ?? "")
                    if let photos = place.photos, !photos.isEmpty {
                        PlacePhotosView(photoMetadata: Array(photos.prefix(5)))
                            .frame(height: 200)
                    }
                    placeTypesView(for: place)
                    priceLevelView(for: place)
                    ratingView(for: place)
                }
            }
        }
    }
    
    private func placeTypesView(for place: GMSPlace) -> some View {
        Group {
            if let types = place.types {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(types, id: \.self) { type in
                            Text(type)
                                .padding(5)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(5)
                        }
                    }
                }
            }
        }
    }
    
    private func priceLevelView(for place: GMSPlace) -> some View {
        Group {
            let priceLevel = place.priceLevel
            switch priceLevel {
            case .free:
                Text("Price Level: Free")
            case .cheap:
                Text("Price Level: $")
            case .medium:
                Text("Price Level: $$")
            case .high:
                Text("Price Level: $$$")
            case .expensive:
                Text("Price Level: $$$$")
            @unknown default:
                Text("Price Level: Unknown")
            }
        }
    }
    
    private func ratingView(for place: GMSPlace) -> some View {
        Group {
            let rating = place.rating
            if rating > 0 {
                Text("Rating: \(String(format: "%.1f", rating))")
            } else {
                Text("No rating available")
            }
        }
    }
    
    private var tripDetailsSection: some View {
        Group {
            if viewModel.selectedPlace != nil {
                Section(header: Text("Trip Details")) {
                    DatePicker("Start Date", selection: $viewModel.startDate, in: Date()..., displayedComponents: .date)
                    DatePicker("End Date", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: .date)
                }
            }
        }
    }
    
    private var createTripButton: some View {
        Group {
            if viewModel.selectedPlace != nil {
                Button("Create Trip") {
                    viewModel.createTrip()
                }
            }
        }
    }
}

// MARK: - CreateTripViewModel

class CreateTripViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedPlace: GMSPlace?
    @Published var tripId: String = ""
    @Published var showingInviteView = false
    @Published var errorWrapper: ErrorWrapper?
    @Published var predictions: [GMSAutocompletePrediction] = []
    @Published var trip: Trip?
    @Published var invitations: [String] = []
    
    @Published var startDate: Date {
        didSet {
            if endDate < startDate {
                endDate = startDate
            }
        }
    }
    
    @Published var endDate: Date {
        didSet {
            if endDate < startDate {
                endDate = startDate
            }
        }
    }
    
    private let tripManager = TripManager()
    private let placesManager = PlacesManager.shared
    private let invitationManager = InvitationManager()
    
    init() {
        self.startDate = Date()
        self.endDate = Date()
    }
    
    func searchPlaces(query: String) {
        placesManager.findCities(query: query) { results in
            DispatchQueue.main.async {
                self.predictions = results
            }
        }
    }
    
    func fetchPlaceDetails(placeID: String) {
        placesManager.fetchPlaceDetails(placeID: placeID) { place in
            DispatchQueue.main.async {
                if let place = place {
                    self.selectedPlace = place
                }
            }
        }
    }
    
    func createTrip() {
        guard let userId = Auth.auth().currentUser?.uid, let place = selectedPlace else {
            print("No user ID found or no place selected")
            return
        }
        
        print("Creating trip for user: \(userId)")
        tripManager.createTrip(creatorId: userId, place: place, startDate: startDate, endDate: endDate) { [weak self] (newTripId, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error creating trip: \(error.localizedDescription)")
                    self?.errorWrapper = ErrorWrapper(error: error.localizedDescription)
                } else if let newTripId = newTripId {
                    print("Trip created successfully with ID: \(newTripId)")
                    self?.tripId = newTripId
                    self?.showingInviteView = true
                    
                    // Fetch the created trip details
                    self?.fetchTripDetails(tripId: newTripId)
                } else {
                    print("Unknown error: No trip ID returned and no error")
                    self?.errorWrapper = ErrorWrapper(error: "Unknown error occurred")
                }
            }
        }
    }
    
    private func fetchTripDetails(tripId: String) {
        _ = tripManager.listenForTripUpdates(tripId: tripId) { fetchedTrip in
            DispatchQueue.main.async {
                if let fetchedTrip = fetchedTrip {
                    self.trip = fetchedTrip
                } else {
                    print("Failed to fetch trip details")
                }
            }
        }
    }
    
    func inviteFriend(email: String, completion: @escaping (Bool) -> Void) {
        guard let creatorId = Auth.auth().currentUser?.uid else {
            print("No user ID found")
            completion(false)
            return
        }
        
        invitationManager.sendInvitation(tripId: self.tripId, inviterEmail: creatorId, inviteeEmail: email, tripName: selectedPlace?.name ?? "") { [weak self] error in
            if let error = error {
                print("Error sending invitation: \(error.localizedDescription)")
                completion(false)
            } else {
                self?.invitations.append(email)
                completion(true)
            }
        }
    }
}

// MARK: - InviteFriendsView

struct InviteFriendsView: View {
    let tripId: String
    let inviteFriend: (String, @escaping (Bool) -> Void) -> Void
    @State private var friendEmail = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Invite Friends")) {
                    TextField("Friend's Email", text: $friendEmail)
                    Button("Send Invite") {
                        sendInvite()
                    }
                }
            }
            .navigationTitle("Invite Friends")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Invitation"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private func sendInvite() {
        inviteFriend(friendEmail) { success in
            if success {
                alertMessage = "Invitation sent successfully"
            } else {
                alertMessage = "Failed to send invitation"
            }
            showingAlert = true
            friendEmail = ""
        }
    }
}
