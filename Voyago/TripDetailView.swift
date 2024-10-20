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
                        HStack {
                            Button(action: { viewModel.voteForItem(item.id, upvote: true) }) {
                                Image(systemName: "hand.thumbsup")
                            }
                            Text("\(item.votes.filter { $0.value }.count)")
                            Button(action: { viewModel.voteForItem(item.id, upvote: false) }) {
                                Image(systemName: "hand.thumbsdown")
                            }
                            Text("\(item.votes.filter { !$0.value }.count)")
                        }
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
            
            Section(header: Text("Participants")) {
                ForEach(viewModel.participantStatuses.sorted(by: { $0.key < $1.key }), id: \.key) { userId, status in
                    HStack {
                        Text(viewModel.getUserName(for: userId))
                        Spacer()
                        Text(statusText(for: status))
                            .foregroundColor(statusColor(for: status))
                    }
                }
                if viewModel.isCreator {
                    Button("Invite Friend") {
                        showingInviteView = true
                    }
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
            viewModel.loadParticipantStatuses()
        }
        
        .sheet(isPresented: $showingInviteView) {
            InviteFriendsView(tripId: tripId) { email, completion in
                viewModel.inviteFriend(email: email, completion: completion)
            }
        }
    }
    
    func statusText(for status: ParticipantStatus) -> String {
        switch status {
        case .inviteSent:
            return "Invite Sent"
        case .invited:
            return "Invited"
        case .accepted:
            return "Accepted"
        case .rejected:
            return "Rejected"
        case .notStarted:
            return "Not Started"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        }
    }
    
    func statusColor(for status: ParticipantStatus) -> Color {
        switch status {
        case .inviteSent, .invited:
            return .blue
        case .accepted, .notStarted:
            return .orange
        case .rejected:
            return .red
        case .inProgress:
            return .yellow
        case .completed:
            return .green
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
    private let userProfileManager = UserProfileManager()
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
            self?.loadParticipantStatuses()
        }
        
        itineraryListener = itineraryManager.listenForItineraryUpdates(tripId: tripId) { [weak self] items in
            self?.itineraryItems = items
        }
    }
    
    func loadParticipantStatuses() {
        guard let tripId = trip?.id else { return }
        
        statusListener = tripDetailsManager.listenForTripDetailsStatus(tripId: tripId) { [weak self] statuses in
            DispatchQueue.main.async {
                self?.updateParticipantStatuses(with: statuses)
            }
        }
        
        invitationListener = invitationManager.listenForTripInvitations(tripId: tripId) { [weak self] invitations in
            DispatchQueue.main.async {
                self?.updateInvitationStatuses(with: invitations)
            }
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
    
    func voteForItem(_ itemId: String, upvote: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        itineraryManager.voteForItem(itemId: itemId, userId: userId, upvote: upvote) { error in
            if let error = error {
                print("Error voting for item: \(error.localizedDescription)")
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
    
    func inviteFriend(email: String, completion: @escaping (Bool) -> Void) {
        guard let tripId = trip?.id, let inviterId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        invitationManager.sendInvitation(tripId: tripId, inviterEmail: inviterId, inviteeEmail: email, tripName: trip?.place.name ?? "") { [weak self] error in
            if let error = error {
                print("Error sending invitation: \(error.localizedDescription)")
                completion(false)
            } else {
                self?.participantStatuses[email] = .inviteSent
                completion(true)
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
