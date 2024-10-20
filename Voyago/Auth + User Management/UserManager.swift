//
//  UserManager.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//


import FirebaseFirestore

class UserManager {
    private let db = Firestore.firestore()
    
    func getUserIdByEmail(_ email: String, completion: @escaping (String?) -> Void) {
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completion(nil)
            } else if let document = querySnapshot?.documents.first {
                completion(document.documentID)
            } else {
                completion(nil)
            }
        }
    }
}
