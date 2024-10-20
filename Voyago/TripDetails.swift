//
//  TripDetails.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import FirebaseFirestore

enum ParticipantStatus: String, Codable {
    case inviteSent = "invite_sent"
    case invited = "invited"
    case accepted = "accepted"
    case rejected = "rejected"
    case notStarted = "not_started"
    case inProgress = "in_progress"
    case completed = "completed"
}

struct TripDetails: Identifiable, Codable {
    let id: String
    let userId: String
    let tripId: String
    var budget: Double?
    var interests: [String]?
    var preferences: [String: Bool]?
    var paceOfTravel: String?
    var crowdPreference: String?
    var transportationPreference: String?
    var dailyStartTime: Date?
    var dailyEndTime: Date?
    var customItineraryAdditions: String?
    var status: ParticipantStatus
}

class TripDetailsManager {
    private let db = Firestore.firestore()
    
    func saveTripDetails(
        userId: String,
        tripId: String,
        budget: Double?,
        interests: [String],
        preferences: [String: Bool],
        paceOfTravel: String,
        crowdPreference: String,
        transportationPreference: String,
        dailyStartTime: Date,
        dailyEndTime: Date,
        customItineraryAdditions: String,
        completion: @escaping (Error?) -> Void
    ) {
        let tripDetails = TripDetails(
            id: UUID().uuidString,
            userId: userId,
            tripId: tripId,
            budget: budget,
            interests: interests,
            preferences: preferences,
            paceOfTravel: paceOfTravel,
            crowdPreference: crowdPreference,
            transportationPreference: transportationPreference,
            dailyStartTime: dailyStartTime,
            dailyEndTime: dailyEndTime,
            customItineraryAdditions: customItineraryAdditions,
            status: .notStarted
        )
        
        do {
            try db.collection("tripDetails").document(tripDetails.id).setData(from: tripDetails) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
    
    func getTripDetails(userId: String, tripId: String, completion: @escaping (TripDetails?, Error?) -> Void) {
        db.collection("tripDetails")
            .whereField("userId", isEqualTo: userId)
            .whereField("tripId", isEqualTo: tripId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    completion(nil, NSError(domain: "TripDetailsManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Trip details not found"]))
                    return
                }
                
                do {
                    let tripDetails = try document.data(as: TripDetails.self)
                    completion(tripDetails, nil)
                } catch {
                    completion(nil, error)
                }
            }
    }
    
    func updateTripDetails(tripDetails: TripDetails, completion: @escaping (Error?) -> Void) {
        do {
            try db.collection("tripDetails").document(tripDetails.id).setData(from: tripDetails, merge: true) { error in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
    
    func updateUserStatus(userId: String, tripId: String, status: ParticipantStatus, completion: @escaping (Error?) -> Void) {
        db.collection("tripDetails")
            .whereField("userId", isEqualTo: userId)
            .whereField("tripId", isEqualTo: tripId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(error)
                    return
                }
                
                guard let document = querySnapshot?.documents.first else {
                    completion(NSError(domain: "TripDetailsManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Trip details not found"]))
                    return
                }
                
                document.reference.updateData(["status": status.rawValue], completion: completion)
            }
    }
    
    func listenForTripDetailsStatus(tripId: String, completion: @escaping ([String: ParticipantStatus]) -> Void) -> ListenerRegistration {
            return db.collection("tripDetails")
                .whereField("tripId", isEqualTo: tripId)
                .addSnapshotListener { querySnapshot, error in
                    guard let documents = querySnapshot?.documents else {
                        print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                        completion([:])
                        return
                    }
                    
                    var statuses: [String: ParticipantStatus] = [:]
                    for document in documents {
                        if let userId = document.data()["userId"] as? String,
                           let statusRawValue = document.data()["status"] as? String,
                           let status = ParticipantStatus(rawValue: statusRawValue) {
                            statuses[userId] = status
                        }
                    }
                    completion(statuses)
                }
        }
}
