//
//  NotificationsView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/20/24.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.invitations) { invitation in
                    VStack(alignment: .leading) {
                        Text("Trip: \(invitation.tripName)")
                            .font(.headline)
                        Text("Invited by: \(invitation.inviterName)")
                            .font(.subheadline)
                        HStack {
                            Button("Accept") {
                                viewModel.respondToInvitation(invitation.id, accept: true)
                            }
                            .foregroundColor(.green)
                            Button("Decline") {
                                viewModel.respondToInvitation(invitation.id, accept: false)
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationBarBackButtonHidden()
        }
        .onAppear {
            viewModel.loadInvitations()
        }
    }
}

class NotificationsViewModel: ObservableObject {
    @Published var invitations: [Invitation] = []
    private let invitationManager = InvitationManager()
    private var listener: ListenerRegistration?
    
    func loadInvitations() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        listener = invitationManager.listenForInvitations(userId: userId) { [weak self] invitations in
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
                self?.loadInvitations()
            }
        }
    }
    
    deinit {
        listener?.remove()
    }
}
