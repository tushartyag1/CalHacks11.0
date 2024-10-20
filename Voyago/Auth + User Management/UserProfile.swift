//
//  UserProfile.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import FirebaseFirestore

struct UserProfile: Identifiable, Codable { // Add Codable conformance
    let id: String
    var name: String
    
    // Add more fields as needed
}

class UserProfileManager {
    private let db = Firestore.firestore()
    
    func createOrUpdateProfile(userId: String, name: String, completion: @escaping (Error?) -> Void) {
        let userRef = db.collection("users").document(userId)
        userRef.setData([
            "name": name
        ], merge: true) { error in // Fix the closure parameter name
            completion(error)
        }
    }
    
    func getProfile(userId: String, completion: @escaping (UserProfile?, Error?) -> Void) {
        let userRef = db.collection("users").document(userId)
        userRef.getDocument { (document, error) in
            if let document = document, document.exists {
                do {
                    let profile = try document.data(as: UserProfile.self) // Use Firestore's built-in decoding
                    completion(profile, nil)
                } catch {
                    completion(nil, error)
                }
            } else {
                completion(nil, error)
            }
        }
    }
}

