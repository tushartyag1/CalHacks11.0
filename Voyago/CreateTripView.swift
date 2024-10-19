//
//  CreateTripView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import FirebaseAuth
import GooglePlaces

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
            }
            .navigationTitle("Create Trip")
            .alert(item: $viewModel.errorWrapper) { errorWrapper in
                Alert(title: Text("Error"), message: Text(errorWrapper.error), dismissButton: .default(Text("OK")))
            }
        }
        .sheet(isPresented: $viewModel.showingInviteView) {
            InviteFriendsView(tripId: $viewModel.tripId)
        }
    }
    
    private var searchSection: some View {
        Section(header: Text("Search for a Place")) {
            TextField("Search", text: $viewModel.searchText)
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
                Section(header: Text("Selected Place")) {
                    Text(place.name ?? "")
                    Text(place.formattedAddress ?? "")
                    if let photos = place.photos, !photos.isEmpty {
                        PlacePhotoView(photoMetadata: photos[0])
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
            Text("Price Level: \(String(repeating: "$", count: Int(priceLevel.rawValue)))")
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
                    Stepper("Duration: \(viewModel.duration) days", value: $viewModel.duration, in: 1...30)
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

class CreateTripViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedPlace: GMSPlace?
    @Published var duration = 1
    @Published var showingInviteView = false
    @Published var tripId: String?
    @Published var errorWrapper: ErrorWrapper?
    @Published var predictions: [GMSAutocompletePrediction] = []
    
    private let tripManager = TripManager()
    private let placesManager = PlacesManager.shared
    
    func searchPlaces(query: String) {
        placesManager.findPlaces(query: query) { results in
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
        tripManager.createTrip(creatorId: userId, place: place, duration: duration) { (newTripId, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error creating trip: \(error.localizedDescription)")
                    self.errorWrapper = ErrorWrapper(error: error.localizedDescription)
                } else if let newTripId = newTripId {
                    print("Trip created successfully with ID: \(newTripId)")
                    self.tripId = newTripId
                    self.showingInviteView = true
                } else {
                    print("Unknown error: No trip ID returned and no error")
                    self.errorWrapper = ErrorWrapper(error: "Unknown error occurred")
                }
            }
        }
    }
}

struct PlacePhotoView: View {
    let photoMetadata: GMSPlacePhotoMetadata
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: loadImage)
    }
    
    private func loadImage() {
        GMSPlacesClient.shared().loadPlacePhoto(photoMetadata) { image, error in
            if let error = error {
                print("Error loading place photo: \(error.localizedDescription)")
            } else if let image = image {
                self.image = image
            }
        }
    }
}

struct InviteFriendsView: View {
    @Binding var tripId: String?
    @State private var friendEmail = ""
    @Environment(\.presentationMode) var presentationMode
    
    private let invitationManager = InvitationManager()
    private let userManager = UserManager()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Invite Friends")) {
                    if let id = tripId {
                        Text("Trip ID: \(id)")
                        TextField("Friend's Email", text: $friendEmail)
                        Button("Send Invite") {
                            sendInvite()
                        }
                    } else {
                        Text("No trip ID available")
                    }
                }
            }
            .navigationTitle("Invite Friends")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func sendInvite() {
        guard let tripId = tripId, let userId = Auth.auth().currentUser?.uid else { return }
        
        userManager.getUserIdByEmail(friendEmail) { friendUserId in
            guard let friendUserId = friendUserId else {
                print("User not found")
                return
            }
            
            self.invitationManager.sendInvitation(tripId: tripId, inviterId: userId, inviteeId: friendUserId) { error in
                if let error = error {
                    print("Error sending invitation: \(error.localizedDescription)")
                } else {
                    print("Invitation sent successfully")
                    self.friendEmail = ""
                }
            }
        }
    }
}
