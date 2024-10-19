//
//  Trip.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import FirebaseFirestore
import GooglePlaces

struct Trip: Identifiable {
    let id: String
    let creatorId: String
    let place: PlaceDetails
    let duration: Int
    var participants: [String]
    var itinerary: [String]
    var sharedNotes: String
}

struct PlaceDetails: Codable {
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let types: [String]
    let priceLevel: Int
    let rating: Double
}

class TripManager {
    private let db = Firestore.firestore()
    
    func createTrip(creatorId: String, place: GMSPlace, duration: Int, completion: @escaping (String?, Error?) -> Void) {
        let tripRef = db.collection("trips").document()
        
        let placeDetails = PlaceDetails(
            name: place.name ?? "",
            address: place.formattedAddress ?? "",
            latitude: place.coordinate.latitude,
            longitude: place.coordinate.longitude,
            types: place.types ?? [],
            priceLevel: Int(place.priceLevel.rawValue),
            rating: Double(place.rating ?? 0)
        )
        
        do {
            let placeData = try Firestore.Encoder().encode(placeDetails)
            
            tripRef.setData([
                "creatorId": creatorId,
                "place": placeData,
                "duration": duration,
                "participants": [creatorId],
                "itinerary": [],
                "sharedNotes": ""
            ]) { error in
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
    
    func getTrip(tripId: String, completion: @escaping (Trip?, Error?) -> Void) {
        let tripRef = db.collection("trips").document(tripId)
        tripRef.getDocument { (document, error) in
            if let document = document, document.exists {
                do {
                    let data = document.data()
                    let placeData = data?["place"] as? [String: Any] ?? [:]
                    let placeDetails = try Firestore.Decoder().decode(PlaceDetails.self, from: placeData)
                    
                    let trip = Trip(
                        id: tripId,
                        creatorId: data?["creatorId"] as? String ?? "",
                        place: placeDetails,
                        duration: data?["duration"] as? Int ?? 0,
                        participants: data?["participants"] as? [String] ?? [],
                        itinerary: data?["itinerary"] as? [String] ?? [],
                        sharedNotes: data?["sharedNotes"] as? String ?? ""
                    )
                    completion(trip, nil)
                } catch {
                    completion(nil, error)
                }
            } else {
                completion(nil, error)
            }
        }
    }

    func listenForTripUpdates(tripId: String, completion: @escaping (Trip?) -> Void) -> ListenerRegistration {
        let tripRef = db.collection("trips").document(tripId)
        return tripRef.addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                print("Error fetching document: \(error!)")
                completion(nil)
                return
            }
            guard let data = document.data() else {
                print("Document data was empty.")
                completion(nil)
                return
            }
            do {
                let placeData = data["place"] as? [String: Any] ?? [:]
                let placeDetails = try Firestore.Decoder().decode(PlaceDetails.self, from: placeData)
                
                let trip = Trip(
                    id: tripId,
                    creatorId: data["creatorId"] as? String ?? "",
                    place: placeDetails,
                    duration: data["duration"] as? Int ?? 0,
                    participants: data["participants"] as? [String] ?? [],
                    itinerary: data["itinerary"] as? [String] ?? [],
                    sharedNotes: data["sharedNotes"] as? String ?? ""
                )
                completion(trip)
            } catch {
                print("Error decoding place details: \(error)")
                completion(nil)
            }
        }
    }

    func listenForUserTrips(userId: String, completion: @escaping ([Trip]) -> Void) -> ListenerRegistration {
        return db.collection("trips")
            .whereField("participants", arrayContains: userId)
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("Error fetching documents: \(error!)")
                    return
                }
                let trips = documents.compactMap { document -> Trip? in
                    let data = document.data()
                    do {
                        let placeData = data["place"] as? [String: Any] ?? [:]
                        let placeDetails = try Firestore.Decoder().decode(PlaceDetails.self, from: placeData)
                        
                        return Trip(
                            id: document.documentID,
                            creatorId: data["creatorId"] as? String ?? "",
                            place: placeDetails,
                            duration: data["duration"] as? Int ?? 0,
                            participants: data["participants"] as? [String] ?? [],
                            itinerary: data["itinerary"] as? [String] ?? [],
                            sharedNotes: data["sharedNotes"] as? String ?? ""
                        )
                    } catch {
                        print("Error decoding place details: \(error)")
                        return nil
                    }
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
        ]) { error in
            completion(error)
        }
    }
}
