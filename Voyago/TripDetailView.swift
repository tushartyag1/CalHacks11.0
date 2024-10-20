//
//  TripDetailView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TripDetailView: View {
    let tripId: String
    @StateObject private var viewModel = TripDetailViewModel()
    @State private var showingPreferencesView = false
    @State private var newItemTitle = ""
    @State private var newItemDescription = ""
    @State private var newItemDate = Date()
    @State private var showingInviteView = false
    
    var body: some View {
        List {
            Section(header: Text("Trip Details")) {
                Text("Place: \(viewModel.trip?.place.name ?? "")")
                Text("Duration: \(viewModel.trip?.formattedDuration ?? "")")
                Text("Participants: \(viewModel.trip?.participants.count ?? 0)")
            }
            
            Section(header: Text("Shared Notes")) {
                TextEditor(text: Binding(
                    get: { viewModel.trip?.sharedNotes ?? "" },
                    set: { viewModel.updateSharedNotes($0) }
                ))
            }
            
            Section(header: Text("Itinerary")) {
                ForEach(viewModel.itineraryItems) { item in
                    VStack(alignment: .leading) {
                        Text(item.title).font(.headline)
                        Text(item.description).font(.subheadline)
                        Text(item.date, style: .date)
                    }
                }
            }
            
            Section(header: Text("Add New Item")) {
                TextField("Title", text: $newItemTitle)
                TextField("Description", text: $newItemDescription)
                DatePicker("Date", selection: $newItemDate, displayedComponents: .date)
                Button("Add Item") {
                    viewModel.addItineraryItem(title: newItemTitle, description: newItemDescription, date: newItemDate)
                    newItemTitle = ""
                    newItemDescription = ""
                    newItemDate = Date()
                }
            }
            
            if viewModel.currentUserStatus == .accepted || viewModel.currentUserStatus == .notStarted {
                            Section {
                                Button("Submit Preferences") {
                                    showingPreferencesView = true
                                }
                            }
                        }
                    }
                    .navigationTitle("Trip Details")
                    .onAppear {
                        viewModel.loadTrip(tripId: tripId)
                    }
                    .sheet(isPresented: $showingPreferencesView) {
                        TripPreferencesView(tripId: tripId, userId: Auth.auth().currentUser?.uid ?? "")
                    }
    }
}

class TripDetailViewModel: ObservableObject {
    @Published var trip: Trip?
    @Published var itineraryItems: [ItineraryItem] = []
    @Published var participantStatuses: [String: ParticipantStatus] = [:]
    
    private let tripManager = TripManager()
    private let itineraryManager = ItineraryManager()
    private let tripDetailsManager = TripDetailsManager()
    private let invitationManager = InvitationManager()
    private let userManager = UserManager()
    private var tripListener: ListenerRegistration?
    private var itineraryListener: ListenerRegistration?
    private var statusListener: ListenerRegistration?
    private var invitationListener: ListenerRegistration?
    
    var currentUserStatus: ParticipantStatus {
        guard let userId = Auth.auth().currentUser?.uid else { return .notStarted }
        return participantStatuses[userId] ?? .notStarted
    }
    
    var isCreator: Bool {
        guard let userId = Auth.auth().currentUser?.uid, let trip = trip else { return false }
        return trip.creatorId == userId
    }
    
    func loadTrip(tripId: String) {
        tripListener = tripManager.listenForTripUpdates(tripId: tripId) { [weak self] trip in
            self?.trip = trip
        }
        
        itineraryListener = itineraryManager.listenForItineraryUpdates(tripId: tripId) { [weak self] items in
            self?.itineraryItems = items
        }
    }
    
    private func updateParticipantStatuses(with tripDetails: [String: ParticipantStatus]) {
        for (userId, status) in tripDetails {
            participantStatuses[userId] = status
        }
    }
    
    private func updateInvitationStatuses(with invitations: [Invitation]) {
        for invitation in invitations {
            switch invitation.status {
            case "pending":
                participantStatuses[invitation.inviteeId] = .invited
            case "accepted":
                if participantStatuses[invitation.inviteeId] != .inProgress && participantStatuses[invitation.inviteeId] != .completed {
                    participantStatuses[invitation.inviteeId] = .notStarted
                }
            case "rejected":
                participantStatuses[invitation.inviteeId] = .rejected
            default:
                break
            }
        }
    }
    
    func getUserName(for userId: String) -> String {
        // This should be updated to use a cache of user profiles
        return "User \(userId.prefix(4))"
    }
    
    func updateSharedNotes(_ notes: String) {
        guard let tripId = trip?.id else { return }
        tripManager.updateSharedNotes(tripId: tripId, notes: notes) { error in
            if let error = error {
                print("Error updating shared notes: \(error.localizedDescription)")
            }
        }
    }
    
    func addItineraryItem(title: String, description: String, date: Date) {
        guard let tripId = trip?.id, let userId = Auth.auth().currentUser?.uid else { return }
        itineraryManager.addItineraryItem(tripId: tripId, creatorId: userId, title: title, description: description, date: date) { _, error in
            if let error = error {
                print("Error adding itinerary item: \(error.localizedDescription)")
            }
        }
    }
    
    func updateUserStatus(to status: ParticipantStatus) {
        guard let userId = Auth.auth().currentUser?.uid, let tripId = trip?.id else { return }
        tripDetailsManager.updateUserStatus(userId: userId, tripId: tripId, status: status) { error in
            if let error = error {
                print("Error updating user status: \(error.localizedDescription)")
            }
        }
    }
    
    func submitPreferences(preferences: TripDetails) {
        tripDetailsManager.updateTripDetails(tripDetails: preferences) { [weak self] error in
            if let error = error {
                print("Error updating trip details: \(error.localizedDescription)")
            } else {
                self?.updateUserStatus(to: .inProgress)
            }
        }
    }
    
    deinit {
        tripListener?.remove()
        itineraryListener?.remove()
        statusListener?.remove()
        invitationListener?.remove()
    }
}
