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
                    if let error = error {
                        print("Error saving invitation: \(error.localizedDescription)")
                        completion(error)
                    } else {
                        print("Invitation saved successfully: \(invitation)")
                        self?.addInvitationToTrip(tripId: tripId, invitationId: invitation.id) { error in
                            completion(error)
                        }
                    }
                }
            } catch {
                print("Error encoding invitation: \(error.localizedDescription)")
                completion(error)
            }
        }
    }
    
    func listenForTripInvitations(tripId: String, completion: @escaping ([Invitation]) -> Void) -> ListenerRegistration {
        print("Listening for invitations for trip: \(tripId)")
        return db.collection("invitations")
            .whereField("tripId", isEqualTo: tripId)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching trip invitations: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No invitation documents found for trip")
                    completion([])
                    return
                }
                
                print("Found \(documents.count) invitation documents for trip")
                let invitations = documents.compactMap { document -> Invitation? in
                    do {
                        let invitation = try document.data(as: Invitation.self)
                        print("Parsed trip invitation: \(invitation)")
                        return invitation
                    } catch {
                        print("Error parsing trip invitation document: \(error.localizedDescription)")
                        return nil
                    }
                }
                completion(invitations)
            }
    }
    
    func listenForInvitations(userId: String, completion: @escaping ([Invitation]) -> Void) -> ListenerRegistration {
        print("Listening for invitations for user: \(userId)")
        return db.collection("invitations")
            .whereField("inviteeId", isEqualTo: userId)
            .whereField("status", isEqualTo: "pending")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("Error fetching user invitations: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No invitation documents found for user")
                    completion([])
                    return
                }
                
                print("Found \(documents.count) invitation documents for user")
                let invitations = documents.compactMap { document -> Invitation? in
                    do {
                        let invitation = try document.data(as: Invitation.self)
                        print("Parsed user invitation: \(invitation)")
                        return invitation
                    } catch {
                        print("Error parsing user invitation document: \(error.localizedDescription)")
                        return nil
                    }
                }
                completion(invitations)
            }
    }
    
    func respondToInvitation(invitationId: String, accept: Bool, completion: @escaping (Error?) -> Void) {
        let status = accept ? "accepted" : "rejected"
        db.collection("invitations").document(invitationId).updateData(["status": status], completion: completion)
    }
    
    private func getUserIdFromEmail(_ email: String, completion: @escaping (String?) -> Void) {
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting user: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let document = querySnapshot?.documents.first else {
                print("No user found with email: \(email)")
                completion(nil)
                return
            }
            
            let userId = document.documentID
            print("Found user ID: \(userId) for email: \(email)")
            completion(userId)
        }
    }
    
    private func addInvitationToTrip(tripId: String, invitationId: String, completion: @escaping (Error?) -> Void) {
        db.collection("trips").document(tripId).updateData([
            "invitations": FieldValue.arrayUnion([invitationId])
        ], completion: completion)
    }
}
