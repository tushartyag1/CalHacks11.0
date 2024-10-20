//
//  HomeView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import GooglePlaces

struct HomeView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingCreateTripView = false
    @State private var showingSignOutAlert = false
    @State private var showingNotificationsView = false
    @State private var notificationDetent: PresentationDetent = .medium
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // Custom Navigation Bar
                    HStack {
                                            Button(action: {
                                                showingNotificationsView = true
                                            }) {
                                                Image(systemName: "bell.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .foregroundStyle(.accent)
                                                    .frame(width: 24, height: 24)
                                            }
                                            .buttonStyle(BouncyButton())
                                            Spacer()
                                            Button(action: {
                                                showingSignOutAlert = true
                                            }) {
                                                Image(systemName: "rectangle.portrait.and.arrow.right.fill")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .foregroundStyle(.accent)
                                                    .frame(width: 24, height: 24)
                                            }
                                            .buttonStyle(BouncyButton())
                                        }
                                        .padding(.horizontal, 20)
                                        .padding(.top, 20)
                    
                    // Main Content
                    if viewModel.trips.isEmpty {
                        emptyStateView
                    } else {
                        tripListView
                    }
                }
                
                // Floating Action Button (only show when trips are not empty)
                if !viewModel.trips.isEmpty {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: {
                                showingCreateTripView = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.accent)
                                    .clipShape(Circle())
                                    .shadow(radius: 4)
                            }
                            .buttonStyle(BouncyButton())
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCreateTripView) {
            CreateTripView()
        }
//        .sheet(isPresented: $showingNotificationsView) {
//                    NotificationsView(viewModel: viewModel)
//                        .presentationDetents([.medium, .large], selection: $notificationDetent)
//                }
        .alert(isPresented: $showingSignOutAlert) {
            Alert(
                title: Text("Sign Out"),
                message: Text("Are you sure you want to sign out?"),
                primaryButton: .destructive(Text("Yes")) {
                    authManager.signOut()
                },
                secondaryButton: .cancel(Text("No"))
            )
        }
        .onAppear {
            viewModel.loadData()
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            
            Image("HomeHeroImage")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 350)
                .padding(.bottom, 30)
            
            VStack(spacing: 5) {
                Text("When if not today?")
                    .font(.custom("ClashDisplay-Medium", size: 28))
                    .foregroundColor(.primary)
                
                Text("It's time to plan a new trip")
                    .font(.custom("ClashDisplay-Regular", size: 18))
                    .foregroundColor(.secondary)
            }
            .multilineTextAlignment(.center)
            
            Spacer()
            
            Button(action: {
                showingCreateTripView = true
            }) {
                Text("Create your first one")
                    .font(.custom("ClashDisplay-Semibold", size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.accent)
                    .clipShape(Capsule())
            }
            .buttonStyle(BouncyButton())
            .padding(.horizontal, 20)
            .padding(.bottom, 80)
        }
        .padding(.horizontal, 20)
    }
    
    private var tripListView: some View {
        VStack(spacing: 0) {
            Text("Your Trips")
                .font(.custom("ClashDisplay-Semibold", size: 44))
                .multilineTextAlignment(.center)
                .padding(.top, 30)
                .padding(.bottom, 10)
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(viewModel.trips) { trip in
                        NavigationLink(destination: TripDetailView(tripId: trip.id ?? "")) {
                            TripRowView(trip: trip)
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                viewModel.deleteTrip(trip)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            
//            // Invitations Section
//            Section(header: Text("Invitations").font(.headline)) {
//                if viewModel.invitations.isEmpty {
//                    Text("No invitations")
//                } else {
//                    ForEach(viewModel.invitations) { invitation in
//                        HStack {
//                            Text("Invitation to \(invitation.tripName)")
//                            Spacer()
//                            Button("Accept") {
//                                viewModel.respondToInvitation(invitation.id, accept: true)
//                            }
//                            .foregroundColor(.accent)
//                            .buttonStyle(BouncyButton())
//                            Button("Decline") {
//                                viewModel.respondToInvitation(invitation.id, accept: false)
//                            }
//                            .foregroundColor(.red)
//                            .buttonStyle(BouncyButton())
//                        }
//                    }
//                }
//            }
//            .padding()
            
//            // Debug Section
//            Section(header: Text("Debug").font(.headline)) {
//                Text("Invitations count: \(viewModel.invitations.count)")
//                Button("Refresh Data") {
//                    viewModel.loadData()
//                }
//                .foregroundColor(.accent)
//                .buttonStyle(BouncyButton())
//            }
//            .padding()
        }
    }

    struct TripRowView: View {
        let trip: Trip
        @State private var image: UIImage?
        
        var body: some View {
            HStack(spacing: 16) {
                // Image
                Group {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color.gray // Placeholder color instead of missing image
                    }
                }
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .onAppear(perform: loadImage)
                
                // Trip details
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.place.name ?? "Unknown Location")
                        .font(.custom("ClashDisplay-Semibold", size: 18))
                        .foregroundColor(.primary)
                    
                    Text(dateRangeText)
                        .font(.custom("ClashDisplay-Medium", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    Text(durationText)
                        .font(.custom("ClashDisplay-Medium", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .frame(height: 100)
            .padding(14)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        
        private var dateRangeText: String {
            let startDate = trip.startDate.formatted(date: .abbreviated, time: .omitted)
            let endDate = trip.endDate.formatted(date: .abbreviated, time: .omitted)
            return "\(startDate) - \(endDate)"
        }
        
        private var durationText: String {
            let duration = Calendar.current.dateComponents([.day, .weekOfMonth, .month], from: trip.startDate, to: trip.endDate)
            
            if let months = duration.month, months > 0 {
                return "\(months) month\(months > 1 ? "s" : "")"
            } else if let weeks = duration.weekOfMonth, weeks > 0 {
                return "\(weeks) week\(weeks > 1 ? "s" : "")"
            } else if let days = duration.day, days > 0 {
                return "\(days) day\(days > 1 ? "s" : "")"
            } else {
                return "Less than a day"
            }
        }
        
        private func loadImage() {
            guard let placeName = trip.place.name else { return }
            
            let placesClient = GMSPlacesClient.shared()
            let token = GMSAutocompleteSessionToken.init()
            
            placesClient.findAutocompletePredictions(fromQuery: placeName, filter: nil, sessionToken: token) { (results, error) in
                if let error = error {
                    print("Error finding place: \(error.localizedDescription)")
                    return
                }
                
                guard let firstResult = results?.first else {
                    print("No results found for place: \(placeName)")
                    return
                }
                
                placesClient.fetchPlace(fromPlaceID: firstResult.placeID, placeFields: .photos, sessionToken: token) { (place, error) in
                    if let error = error {
                        print("Error fetching place details: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let firstPhoto = place?.photos?.first else {
                        print("No photos found for place: \(placeName)")
                        return
                    }
                    
                    placesClient.loadPlacePhoto(firstPhoto, callback: { (photo, error) -> Void in
                        if let error = error {
                            print("Error loading photo: \(error.localizedDescription)")
                            return
                        }
                        
                        if let photo = photo {
                            DispatchQueue.main.async {
                                self.image = photo
                            }
                        }
                    })
                }
            }
        }
    }
}

@MainActor
class HomeViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var invitations: [Invitation] = []
    @Published var notifications: [[String: Any]] = []
    
    private let tripManager = TripManager()
    private let invitationManager = InvitationManager()
    private var tripsListener: ListenerRegistration?
    private var invitationsListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func loadData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user ID found")
            return
        }
        
        print("Loading data for user: \(userId)")
        
        tripsListener = tripManager.listenForUserTrips(userId: userId) { [weak self] trips in
            print("Received \(trips.count) trips")
            Task { @MainActor in
                self?.trips = trips
            }
        }
        
        invitationsListener = invitationManager.listenForInvitations(userId: userId) { [weak self] invitations in
            print("Received \(invitations.count) invitations for user \(userId)")
            for invitation in invitations {
                print("Invitation: \(invitation)")
            }
            Task { @MainActor in
                self?.invitations = invitations
            }
        }
        
        fetchNotifications()
    }
    
    func respondToInvitation(_ invitationId: String, accept: Bool) {
        guard let invitation = invitations.first(where: { $0.id == invitationId }) else {
            print("Invitation not found")
            return
        }
        
        invitationManager.respondToInvitation(invitationId: invitationId, accept: accept) { [weak self] error in
            if let error = error {
                print("Error responding to invitation: \(error.localizedDescription)")
            } else {
                Task { @MainActor in
                    self?.invitations.removeAll { $0.id == invitationId }
                    
                    if accept {
                        // Add the user to the trip participants
                        if let userId = Auth.auth().currentUser?.uid {
                            self?.tripManager.addParticipant(tripId: invitation.tripId, userId: userId) { error in
                                if let error = error {
                                    print("Error adding participant to trip: \(error.localizedDescription)")
                                } else {
                                    // Fetch and add the new trip to the trips list
                                    self?.tripManager.fetchTrip(tripId: invitation.tripId) { result in
                                        switch result {
                                        case .success(let trip):
                                            Task { @MainActor in
                                                self?.trips.append(trip)
                                            }
                                        case .failure(let error):
                                            print("Error fetching new trip: \(error.localizedDescription)")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Store notification in Firestore
                    self?.storeNotification(for: invitation, accepted: accept)
                }
            }
        }
    }
    
    private func storeNotification(for invitation: Invitation, accepted: Bool) {
        let message = accepted ? "accepted" : "declined"
        let notification = [
            "recipientId": invitation.inviterId,
            "title": "Invitation Response",
            "body": "Your invitation to \(invitation.tripName) has been \(message).",
            "timestamp": FieldValue.serverTimestamp(),
            "read": false
        ] as [String : Any]
        
        db.collection("notifications").addDocument(data: notification) { error in
            if let error = error {
                print("Error storing notification: \(error.localizedDescription)")
            } else {
                print("Notification stored successfully")
            }
        }
    }
    
    func fetchNotifications() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("notifications")
            .whereField("recipientId", isEqualTo: userId)
            .whereField("read", isEqualTo: false)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                if let error = error {
                    print("Error fetching notifications: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No notifications found")
                    return
                }
                
                let notifications = documents.compactMap { document -> [String: Any]? in
                    var notification = document.data()
                    notification["id"] = document.documentID
                    return notification
                }
                
                Task { @MainActor in
                    self?.notifications = notifications
                    print("Fetched \(notifications.count) notifications")
                }
            }
    }
    
    func deleteTrip(_ trip: Trip) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user ID found")
            return
        }
        
        tripManager.deleteTrip(tripId: trip.id ?? "", userId: userId) { [weak self] result in
            switch result {
            case .success():
                Task { @MainActor in
                    self?.trips.removeAll { $0.id == trip.id }
                }
            case .failure(let error):
                print("Error deleting trip: \(error.localizedDescription)")
            }
        }
    }
    
    func markNotificationAsRead(_ notificationId: String) {
        db.collection("notifications").document(notificationId).updateData(["read": true]) { [weak self] error in
            if let error = error {
                print("Error marking notification as read: \(error.localizedDescription)")
            } else {
                print("Notification marked as read successfully")
                Task { @MainActor in
                    self?.notifications.removeAll { $0["id"] as? String == notificationId }
                }
            }
        }
    }
    
    deinit {
        tripsListener?.remove()
        invitationsListener?.remove()
    }
}

struct BouncyButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { newValue in
                if newValue {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }
            }
    }
}
