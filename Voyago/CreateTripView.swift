//
//  CreateTripView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

//
//  CreateTripView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import FirebaseAuth
import GooglePlaces
import ContactsUI

struct CreateTripView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = CreateTripViewModel()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 5) {
                searchSection
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                if !viewModel.predictions.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 15) {
                            ForEach(viewModel.predictions, id: \.placeID) { prediction in
                                NavigationLink(
                                    destination: SelectedCityView(
                                        placeID: prediction.placeID,
                                        viewModel: viewModel
                                    ),
                                    label: {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(prediction.attributedPrimaryText.string)
                                                .font(.custom("ClashDisplay-Medium", size: 24))
                                                .foregroundColor(.primary)
                                            Text(prediction.attributedSecondaryText?.string ?? "")
                                                .font(.custom("ClashDisplay-Regular", size: 18))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                )
                                .padding(.vertical, 5)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 30)
            .navigationBarBackButtonHidden()
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(item: $viewModel.errorWrapper) { errorWrapper in
            Alert(title: Text("Error"), message: Text(errorWrapper.error), dismissButton: .default(Text("OK")))
        }
    }
    
    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Search for a City")
                .font(.custom("ClashDisplay-Semibold", size: 34))
                .foregroundColor(.accentColor)
            
            CustomSearchBar(text: $viewModel.searchText)
                .onChange(of: viewModel.searchText) { newValue in
                    viewModel.searchPlaces(query: newValue)
                }
        }
    }
}

struct CustomSearchBar: View {
    @Binding var text: String
    var placeholder: String = "San Francisco, London, Tokyo, Mumbai, ..."
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.accentColor)
            
            TextField(placeholder, text: $text)
                .font(.custom("ClashDisplay-Regular", size: 18))
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

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
        self.selectedPlace = nil // Reset the selected place
        placesManager.fetchPlaceDetails(placeID: placeID) { [weak self] place in
            DispatchQueue.main.async {
                if let place = place {
                    self?.selectedPlace = place
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
        guard let creatorId = Auth.auth().currentUser?.uid, let creatorName = Auth.auth().currentUser?.displayName else {
            print("No user ID or name found")
            completion(false)
            return
        }
        
<<<<<<< HEAD
        invitationManager.sendInvitation(tripId: self.tripId, inviterId: creatorId, inviterName: creatorName, inviteeEmail: email, tripName: selectedPlace?.name ?? "") { [weak self] error in
=======
        invitationManager.sendInvitation(tripId: self.tripId, inviterId: creatorId, inviteeEmail: email, tripName: selectedPlace?.name ?? "") { [weak self] error in
>>>>>>> fa5e609f915e237a4f9929144ae6cc12ddd193a5
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

struct InviteFriendsView: View {
    let tripId: String
    let inviteFriend: (String, @escaping (Bool) -> Void) -> Void
    @Environment(\.presentationMode) var presentationMode
    @State private var friendEmail = ""
    @State private var invitedFriends: [String] = []
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingContactPicker = false
    @State private var isInviting = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Invite Friends")
                .font(.custom("ClashDisplay-Semibold", size: 34))
                .foregroundColor(.accentColor)
            
            HStack {
                TextField("Enter friend's email", text: $friendEmail)
                    .font(.custom("ClashDisplay-Regular", size: 18))
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .keyboardType(.emailAddress)
                
                Button(action: {
                    showingContactPicker = true
                }) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            if !invitedFriends.isEmpty {
                Text("Invited Friends")
                    .font(.custom("ClashDisplay-Medium", size: 24))
                    .padding(.top)
                
                ForEach(invitedFriends, id: \.self) { email in
                    HStack {
                        Text(email)
                            .font(.custom("ClashDisplay-Regular", size: 18))
                        Spacer()
                        Button(action: {
                            invitedFriends.removeAll { $0 == email }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 5)
                }
            }
            
            Spacer()
            
            Button(action: sendInvite) {
                if isInviting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Send Invite")
                        .font(.custom("ClashDisplay-Semibold", size: 18))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .cornerRadius(10)
            .disabled(friendEmail.isEmpty || invitedFriends.count >= 5 || isInviting)
        }
        .padding()
        .navigationBarTitle("Invite Friends", displayMode: .inline)
        .navigationBarItems(trailing: Button("Done") {
            presentationMode.wrappedValue.dismiss()
        })
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Invitation"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showingContactPicker) {
            ContactPicker(email: $friendEmail)
        }
    }
    
    private func sendInvite() {
        let lowercaseEmail = friendEmail.lowercased()
        if invitedFriends.contains(lowercaseEmail) {
            alertMessage = "This friend has already been invited."
            showingAlert = true
            return
        }
        
        if invitedFriends.count >= 5 {
            alertMessage = "You can only invite up to 5 friends."
            showingAlert = true
            return
        }
        
        isInviting = true
        inviteFriend(lowercaseEmail) { success in
            isInviting = false
            if success {
                invitedFriends.append(lowercaseEmail)
                alertMessage = "Invitation sent successfully"
                friendEmail = ""
            } else {
                alertMessage = "User not found or failed to send invitation"
            }
            showingAlert = true
        }
    }
}

struct ContactPicker: UIViewControllerRepresentable {
    @Binding var email: String
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        picker.predicateForEnablingContact = NSPredicate(format: "emailAddresses.@count > 0")
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker
        
        init(_ parent: ContactPicker) {
            self.parent = parent
        }
        
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            if let email = contact.emailAddresses.first?.value as String? {
                parent.email = email.lowercased()
            }
        }
    }
}
