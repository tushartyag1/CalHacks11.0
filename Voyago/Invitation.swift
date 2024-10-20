//
//  Invitation.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import FirebaseFirestore
import FirebaseAuth

struct Invitation: Identifiable, Codable {
    let id: String
    let tripId: String
    let inviterId: String
    let inviterName: String
    let inviteeId: String
    var status: String
    let tripName: String
}

class InvitationManager {
    private let db = Firestore.firestore()
    
    func sendInvitation(tripId: String, inviterId: String, inviterName: String, inviteeEmail: String, tripName: String, completion: @escaping (Error?) -> Void) {
        getUserIdFromEmail(inviteeEmail) { [weak self] inviteeId in
            guard let inviteeId = inviteeId else {
                completion(NSError(domain: "InvitationManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invitee not found"]))
                return
            }
            
            let invitation = Invitation(
                id: UUID().uuidString,
                tripId: tripId,
                inviterId: inviterId,
                inviterName: inviterName,
                inviteeId: inviteeId,
                status: "pending",
                tripName: tripName
            )
        
            do {
                try self?.db.collection("invitations").document(invitation.id).setData(from: invitation) { error in
                    completion(error)
                }
            } catch {
                completion(error)
            }
        }
    }
    
    func listenForInvitations(userId: String, completion: @escaping ([Invitation]) -> Void) -> ListenerRegistration {
        return db.collection("invitations")
            .whereField("inviteeId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching invitations: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let invitations = documents.compactMap { try? $0.data(as: Invitation.self) }
                completion(invitations)
            }
    }
    
    func respondToInvitation(invitationId: String, accept: Bool, completion: @escaping (Error?) -> Void) {
        let status = accept ? "accepted" : "rejected"
        db.collection("invitations").document(invitationId).updateData(["status": status], completion: completion)
    }
    
    private func getUserIdFromEmail(_ email: String, completion: @escaping (String?) -> Void) {
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                completion(nil)
                return
            }
            let userId = documents[0].documentID
            completion(userId)
        }
    }
}
