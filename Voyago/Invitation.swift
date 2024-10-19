//
//  Invitation.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import FirebaseFirestore

struct Invitation: Identifiable {
    let id: String
    let tripId: String
    let inviterId: String
    let inviteeId: String
    var status: String // "pending", "accepted", "declined"
}

class InvitationManager {
    private let db = Firestore.firestore()
    
    func sendInvitation(tripId: String, inviterId: String, inviteeId: String, completion: @escaping (Error?) -> Void) {
        let invitationRef = db.collection("invitations").document()
        invitationRef.setData([
            "tripId": tripId,
            "inviterId": inviterId,
            "inviteeId": inviteeId,
            "status": "pending"
        ]) { error in
            completion(error)
        }
    }
    
    func respondToInvitation(invitationId: String, status: String, completion: @escaping (Error?) -> Void) {
        let invitationRef = db.collection("invitations").document(invitationId)
        invitationRef.updateData([
            "status": status
        ]) { error in
            completion(error)
        }
    }
    
    func listenForInvitations(userId: String, completion: @escaping ([Invitation]) -> Void) -> ListenerRegistration {
        return db.collection("invitations")
            .whereField("inviteeId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                let invitations = documents.compactMap { document -> Invitation? in
                    let data = document.data()
                    return Invitation(
                        id: document.documentID,
                        tripId: data["tripId"] as? String ?? "",
                        inviterId: data["inviterId"] as? String ?? "",
                        inviteeId: data["inviteeId"] as? String ?? "",
                        status: data["status"] as? String ?? "pending"
                    )
                }
                completion(invitations)
            }
    }
    
    func getInvitation(invitationId: String, completion: @escaping (Invitation?) -> Void) {
        let invitationRef = db.collection("invitations").document(invitationId)
        invitationRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let invitation = Invitation(
                    id: document.documentID,
                    tripId: data?["tripId"] as? String ?? "",
                    inviterId: data?["inviterId"] as? String ?? "",
                    inviteeId: data?["inviteeId"] as? String ?? "",
                    status: data?["status"] as? String ?? "pending"
                )
                completion(invitation)
            } else {
                completion(nil)
            }
        }
    }
}
