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
                            Text(trip.place.name)
                        }
                    }
                }
                
                Section(header: Text("Invitations")) {
                    ForEach(viewModel.invitations) { invitation in
                        HStack {
                            Text("Invitation to \(invitation.tripId)")
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
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        tripsListener = tripManager.listenForUserTrips(userId: userId) { [weak self] trips in
            self?.trips = trips
        }
        
        invitationsListener = invitationManager.listenForInvitations(userId: userId) { [weak self] invitations in
            self?.invitations = invitations
        }
    }
    
    func respondToInvitation(_ invitationId: String, accept: Bool) {
        invitationManager.respondToInvitation(invitationId: invitationId, status: accept ? "accepted" : "declined") { [weak self] error in
            if let error = error {
                print("Error responding to invitation: \(error.localizedDescription)")
            } else if accept {
                self?.invitationManager.getInvitation(invitationId: invitationId) { invitation in
                    if let invitation = invitation {
                        self?.tripManager.addParticipant(tripId: invitation.tripId, userId: invitation.inviteeId) { error in
                            if let error = error {
                                print("Error adding participant to trip: \(error.localizedDescription)")
                            }
                        }
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
