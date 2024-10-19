//
//  ItineraryManager.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import FirebaseFirestore

class ItineraryManager {
    private let db = Firestore.firestore()
    
    func addItineraryItem(tripId: String, creatorId: String, title: String, description: String, date: Date, completion: @escaping (String?, Error?) -> Void) {
        let itemRef = db.collection("itineraryItems").document()
        itemRef.setData([
            "tripId": tripId,
            "creatorId": creatorId,
            "title": title,
            "description": description,
            "date": date,
            "votes": [:]
        ]) { error in
            if let error = error {
                completion(nil, error)
            } else {
                completion(itemRef.documentID, nil)
            }
        }
    }
    
    func voteForItem(itemId: String, userId: String, upvote: Bool, completion: @escaping (Error?) -> Void) {
        let itemRef = db.collection("itineraryItems").document(itemId)
        itemRef.updateData([
            "votes.\(userId)": upvote
        ], completion: completion)
    }
    
    func listenForItineraryUpdates(tripId: String, completion: @escaping ([ItineraryItem]) -> Void) -> ListenerRegistration {
        return db.collection("itineraryItems")
            .whereField("tripId", isEqualTo: tripId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                let items = documents.compactMap { document -> ItineraryItem? in
                    let data = document.data()
                    return ItineraryItem(
                        id: document.documentID,
                        tripId: data["tripId"] as? String ?? "",
                        creatorId: data["creatorId"] as? String ?? "",
                        title: data["title"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        date: (data["date"] as? Timestamp)?.dateValue() ?? Date(),
                        votes: data["votes"] as? [String: Bool] ?? [:]
                    )
                }
                completion(items)
            }
    }
}
