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
    @State private var searchText = ""
    @State private var selectedPlace: GMSPlace?
    @State private var duration = 1
    @State private var showingInviteView = false
    @State private var tripId: String?
    @State private var errorMessage: String?
    @State private var predictions: [GMSAutocompletePrediction] = []
    
    private let tripManager = TripManager()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search for a Place")) {
                    TextField("Search", text: $searchText)
                        .onChange(of: searchText) { newValue in
                            searchPlaces(query: newValue)
                        }
                    
                    if !predictions.isEmpty {
                        List(predictions, id: \.placeID) { prediction in
                            Button(action: {
                                fetchPlaceDetails(placeID: prediction.placeID)
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
                
                if let place = selectedPlace {
                    Section(header: Text("Selected Place")) {
                        Text(place.name ?? "")
                        Text(place.formattedAddress ?? "")
                        if let photos = place.photos, !photos.isEmpty {
                            PlacePhotoView(photoMetadata: photos[0])
                                .frame(height: 200)
                        }
                        if let types = place.types {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack {
                                    ForEach(types, id: \.self) { type in
                                        Text(type.rawValue)
                                            .padding(5)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(5)
                                    }
                                }
                            }
                        }
                        if let priceLevel = place.priceLevel {
                            Text("Price Level: \(String(repeating: "$", count: Int(priceLevel.rawValue)))")
                        }
                        if let rating = place.rating {
                            Text("Rating: \(rating)")
                        }
                    }
                    
                    Section(header: Text("Trip Details")) {
                        Stepper("Duration: \(duration) days", value: $duration, in: 1...30)
                    }
                    
                    Button("Create Trip") {
                        createTrip()
                    }
                }
            }
            .navigationTitle("Create Trip")
            .alert(item: Binding(
                get: { errorMessage.map { ErrorWrapper(error: $0) } },
                set: { _ in errorMessage = nil }
            )) { errorWrapper in
                Alert(title: Text("Error"), message: Text(errorWrapper.error), dismissButton: .default(Text("OK")))
            }
        }
        .sheet(isPresented: $showingInviteView) {
            InviteFriendsView(tripId: $tripId)
        }
    }
    
    private func searchPlaces(query: String) {
        PlacesManager.shared.findPlaces(query: query) { results in
            self.predictions = results
        }
    }
    
    private func fetchPlaceDetails(placeID: String) {
        PlacesManager.shared.fetchPlaceDetails(placeID: placeID) { place in
            if let place = place {
                self.selectedPlace = place
            }
        }
    }
    
    private func createTrip() {
        guard let userId = Auth.auth().currentUser?.uid, let place = selectedPlace else {
            print("No user ID found or no place selected")
            return
        }
        
        print("Creating trip for user: \(userId)")
        tripManager.createTrip(creatorId: userId, place: place, duration: duration) { (newTripId, error) in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error creating trip: \(error.localizedDescription)")
                    self.errorMessage = "Error creating trip: \(error.localizedDescription)"
                } else if let newTripId = newTripId {
                    print("Trip created successfully with ID: \(newTripId)")
                    self.tripId = newTripId
                    self.showingInviteView = true
                } else {
                    print("Unknown error: No trip ID returned and no error")
                    self.errorMessage = "Unknown error occurred"
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
