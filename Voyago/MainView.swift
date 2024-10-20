//
//  MainView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct MainView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var viewModel = MainViewModel()
    @State private var showingCreateTripView = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Your Trips")) {
                    ForEach(viewModel.trips) { trip in
                        NavigationLink(destination: TripDetailView(tripId: trip.id)) {
                            Text(trip.place.name ?? "")
                        }
                    }
                }
                
                Section(header: Text("Invitations")) {
                    if viewModel.invitations.isEmpty {
                        Text("No invitations")
                    } else {
                        ForEach(viewModel.invitations) { invitation in
                            HStack {
                                Text("Invitation to \(invitation.tripName)")
                                Spacer()
                                Button("Accept") {
                                    viewModel.respondToInvitation(invitation.id, accept: true)
                                }
                                Button("Decline") {
                                    viewModel.respondToInvitation(invitation.id, accept: false)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Debug")) {
                    Text("Invitations count: \(viewModel.invitations.count)")
                    Button("Refresh Data") {
                        viewModel.loadData()
                    }
                }
            }
            .navigationTitle("Voyago")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create Trip") {
                        showingCreateTripView = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Sign Out") {
                        authManager.signOut()
                    }
                }
            }
            .sheet(isPresented: $showingCreateTripView) {
                CreateTripView()
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

class MainViewModel: ObservableObject {
    @Published var trips: [Trip] = []
    @Published var invitations: [Invitation] = []
    
    private let tripManager = TripManager()
    private let invitationManager = InvitationManager()
    private var tripsListener: ListenerRegistration?
    private var invitationsListener: ListenerRegistration?
    
    func loadData() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No user ID found")
            return
        }
        
        print("Loading data for user: \(userId)")
        
        tripsListener = tripManager.listenForUserTrips(userId: userId) { [weak self] trips in
            print("Received \(trips.count) trips")
            DispatchQueue.main.async {
                self?.trips = trips
            }
        }
        
        invitationsListener = invitationManager.listenForInvitations(userId: userId) { [weak self] invitations in
            print("Received \(invitations.count) invitations for user \(userId)")
            for invitation in invitations {
                print("Invitation: \(invitation)")
            }
            DispatchQueue.main.async {
                self?.invitations = invitations
            }
        }
    }
    
    func respondToInvitation(_ invitationId: String, accept: Bool) {
        invitationManager.respondToInvitation(invitationId: invitationId, accept: accept) { [weak self] error in
            if let error = error {
                print("Error responding to invitation: \(error.localizedDescription)")
            } else {
                // Update the local state
                if let index = self?.invitations.firstIndex(where: { $0.id == invitationId }) {
                    DispatchQueue.main.async {
                        if accept {
                            self?.invitations[index].status = "accepted"
                            // Add the user to the trip participants
                            if let tripId = self?.invitations[index].tripId,
                               let userId = Auth.auth().currentUser?.uid {
                                self?.tripManager.addParticipant(tripId: tripId, userId: userId) { error in
                                    if let error = error {
                                        print("Error adding participant to trip: \(error.localizedDescription)")
                                    }
                                }
                            }
                        } else {
                            self?.invitations[index].status = "rejected"
                        }
                        // Remove the invitation from the list
                        self?.invitations.remove(at: index)
                    }
                }
            }
        }
    }
    
    deinit {
        tripsListener?.remove()
        invitationsListener?.remove()
    }
}
