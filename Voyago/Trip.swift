//
//  Trip.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import FirebaseFirestore
import GooglePlaces

struct PlaceDetails: Codable {
    let name: String?
    let formattedAddress: String?
    // Add any other properties that you expect to be in the place data
    // If some properties might be missing, make them optional with '?'
    
    enum CodingKeys: String, CodingKey {
        case name
        case formattedAddress = "formatted_address"
        // Add other cases as needed
    }
}

struct Trip: Identifiable, Codable {
    @DocumentID var id: String?
    let creatorId: String
    let place: PlaceDetails
    let startDate: Date
    let endDate: Date
    var participants: [String]
    var itinerary: [String]
    var sharedNotes: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case creatorId
        case place
        case startDate
        case endDate
        case participants
        case itinerary
        case sharedNotes
    }
    
    var formattedDuration: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
    }
}

class TripManager {
    private let db = Firestore.firestore()
    
    func createTrip(creatorId: String, place: GMSPlace, startDate: Date, endDate: Date, completion: @escaping (String?, Error?) -> Void) {
        let tripRef = db.collection("trips").document()
        
        let placeDetails = PlaceDetails(
            name: place.name,
            formattedAddress: place.formattedAddress
            // Add any other place details you want to save
        )
        
        let trip = Trip(
            id: tripRef.documentID,
            creatorId: creatorId,
            place: placeDetails,
            startDate: startDate,
            endDate: endDate,
            participants: [creatorId],
            itinerary: [],
            sharedNotes: ""
        )
        
        do {
            try tripRef.setData(from: trip) { error in
                if let error = error {
                    completion(nil, error)
                } else {
                    completion(tripRef.documentID, nil)
                }
            }
        } catch {
            completion(nil, error)
        }
    }
    
    func listenForTripUpdates(tripId: String, completion: @escaping (Trip?) -> Void) -> ListenerRegistration {
        let tripRef = db.collection("trips").document(tripId)
        return tripRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }
            
            do {
                let trip = try document.data(as: Trip.self)
                completion(trip)
            } catch {
                print("Error decoding trip: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    func listenForUserTrips(userId: String, completion: @escaping ([Trip]) -> Void) -> ListenerRegistration {
        return db.collection("trips")
            .whereField("participants", arrayContains: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                    completion([])
                    return
                }
                
                let trips = documents.compactMap { document -> Trip? in
                    try? document.data(as: Trip.self)
                }
                completion(trips)
            }
    }
    
    func addParticipant(tripId: String, userId: String, completion: @escaping (Error?) -> Void) {
        let tripRef = db.collection("trips").document(tripId)
        tripRef.updateData([
            "participants": FieldValue.arrayUnion([userId])
        ], completion: completion)
    }
    
    func updateSharedNotes(tripId: String, notes: String, completion: @escaping (Error?) -> Void) {
        let tripRef = db.collection("trips").document(tripId)
        tripRef.updateData([
            "sharedNotes": notes
        ], completion: completion)
    }
    
    func fetchTrip(tripId: String, completion: @escaping (Result<Trip, Error>) -> Void) {
        db.collection("trips").document(tripId).getDocument { (document, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists else {
                completion(.failure(NSError(domain: "TripManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "Trip not found"])))
                return
            }
            
            do {
                let trip = try document.data(as: Trip.self)
                completion(.success(trip))
            } catch {
                print("Error decoding trip: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    
    func deleteTrip(tripId: String, userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("trips").document(tripId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
