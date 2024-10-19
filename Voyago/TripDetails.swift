//
//  TripDetails.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import FirebaseFirestore

struct TripDetails: Identifiable {
    let id: String
    let userId: String
    let tripId: String
    var budget: Double
    var interests: [String]
    var preferences: [String: Bool] // e.g., "hiking": true, "museums": false
    var status: String // "not_started", "in_progress", "completed"
}

class TripDetailsManager {
    private let db = Firestore.firestore()
    
    func saveTripDetails(userId: String, tripId: String, budget: Double, interests: [String], preferences: [String: Bool], completion: @escaping (Error?) -> Void) {
        let detailsRef = db.collection("tripDetails").document()
        detailsRef.setData([
            "userId": userId,
            "tripId": tripId,
            "budget": budget,
            "interests": interests,
            "preferences": preferences,
            "status": "not_started"
        ]) { error in
            completion(error)
        }
    }
    
    func updateTripDetailsStatus(detailsId: String, status: String, completion: @escaping (Error?) -> Void) {
        let detailsRef = db.collection("tripDetails").document(detailsId)
        detailsRef.updateData([
            "status": status
        ]) { error in
            completion(error)
        }
    }
    
    func getTripDetailsStatus(tripId: String, completion: @escaping ([String: String]?, Error?) -> Void) {
        db.collection("tripDetails")
            .whereField("tripId", isEqualTo: tripId)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                var statuses: [String: String] = [:]
                for document in querySnapshot!.documents {
                    let data = document.data()
                    if let userId = data["userId"] as? String,
                       let status = data["status"] as? String {
                        statuses[userId] = status
                    }
                }
                completion(statuses, nil)
            }
    }
}
