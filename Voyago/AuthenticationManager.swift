//
//  AuthenticationManager.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

//
//  AuthenticationManager.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

class AuthenticationManager: NSObject, ObservableObject {
    // MARK: - Published properties
    @Published var authState: AuthState = .signedOut
    @Published var errorMessage: String?
    @Published var currentNonce: String?
    
    // MARK: - Private properties
    private let db = Firestore.firestore()

    // MARK: - Enums
    enum AuthState {
        case signedOut
        case signedIn
        case newAccount
    }

    // MARK: - Initialization
    override init() {
        super.init()
        checkAuthenticationState()
    }

    // MARK: - Authentication State
    private func checkAuthenticationState() {
        if Auth.auth().currentUser != nil {
            authState = .signedIn
        } else {
            authState = .signedOut
        }
    }

    // MARK: - Create Account / Sign In
    func prepareSignInWithApple() -> ASAuthorizationAppleIDRequest {
        let nonce = randomNonceString()
        currentNonce = nonce
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        return request
    }
    
    func handleSignInWithAppleCompletion(_ result: ASAuthorization) {
        if let appleIDCredential = result.credential as? ASAuthorizationAppleIDCredential {
            // Log the data received from Apple
            print("Apple ID Credential received:")
            print("User ID: \(appleIDCredential.user)")
            print("Full Name: \(appleIDCredential.fullName?.debugDescription ?? "nil")")
            print("Email: \(appleIDCredential.email ?? "nil")")

            guard let nonce = currentNonce else {
                print("Invalid state: A login callback was received, but no login request was sent.")
                self.errorMessage = "An error occurred during sign in. Please try again."
                return
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { (authResult, error) in
                if let error = error {
                    print("Authentication error: \(error.localizedDescription)")
                    self.errorMessage = "Authentication failed. Please try again."
                    return
                }
                
                // User is signed in to Firebase with Apple.
                if let user = authResult?.user {
                    print("Firebase User ID: \(user.uid)")
                    print("Firebase User Email: \(user.email ?? "nil")")
                    print("Firebase User Display Name: \(user.displayName ?? "nil")")
                    
                    self.updateUserProfile(user: user, fullName: appleIDCredential.fullName)
                    self.saveUserToFirestore(user: user, fullName: appleIDCredential.fullName, email: appleIDCredential.email)
                    
                    DispatchQueue.main.async {
                        self.authState = .signedIn
                        self.errorMessage = nil
                    }
                }
            }
        }
    }
    
    func fetchUserProfile(userId: String, completion: @escaping (UserProfile?) -> Void) {
        db.collection("users").document(userId).getDocument { (document, error) in
            if let document = document, document.exists {
                let data = document.data()
                let profile = UserProfile(
                    id: userId,
                    name: data?["fullName"] as? String ?? "User"
                )
                completion(profile)
            } else {
                print("Error fetching user profile: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }

    // MARK: - User Profile Update
    private func updateUserProfile(user: User, fullName: PersonNameComponents?) {
        print("Updating user profile with full name: \(fullName?.debugDescription ?? "nil")")
        
        if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = "\(givenName) \(familyName)"
            
            changeRequest.commitChanges { [weak self] error in
                if let error = error {
                    print("Error updating user profile: \(error.localizedDescription)")
                    self?.errorMessage = "Failed to update user profile. Some information may be missing."
                } else {
                    print("User profile updated successfully with name: \(givenName) \(familyName)")
                }
            }
        } else {
            print("Full name not provided or incomplete")
        }
    }

    // MARK: - Firestore
    private func saveUserToFirestore(user: User, fullName: PersonNameComponents?, email: String?) {
        let userId = user.uid
        var userData: [String: Any] = [
            "email": email ?? user.email ?? "",
            "createdAt": FieldValue.serverTimestamp(),
            "lastSignInAt": FieldValue.serverTimestamp()
        ]
        
        if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
            userData["fullName"] = "\(givenName) \(familyName)"
        } else if let displayName = user.displayName {
            userData["fullName"] = displayName
        }
        
        print("Saving user data to Firestore: \(userData)")
        
        db.collection("users").document(userId).setData(userData, merge: true) { [weak self] error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
                self?.errorMessage = "Failed to save user data. Some features may be limited."
            } else {
                print("User data saved successfully to Firestore")
            }
        }
    }

    // MARK: - Sign Out
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.authState = .signedOut
                self.errorMessage = nil
            }
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
            self.errorMessage = "Failed to sign out. Please try again."
        }
    }

    // MARK: - User Deletion
    func deleteCurrentUser() {
        guard let user = Auth.auth().currentUser else {
            print("No user is currently signed in")
            self.errorMessage = "No user is currently signed in."
            return
        }

        db.collection("users").document(user.uid).delete { [weak self] error in
            if let error = error {
                print("Error deleting user data from Firestore: \(error.localizedDescription)")
                self?.errorMessage = "Failed to delete user data. Please try again."
                return
            }
            
            user.delete { [weak self] error in
                guard let self = self else { return }
                if let error = error {
                    print("Error deleting user: \(error.localizedDescription)")
                    self.errorMessage = "Failed to delete user. Please try again."
                } else {
                    print("User successfully deleted")
                    DispatchQueue.main.async {
                        self.authState = .signedOut
                        self.errorMessage = nil
                    }
                }
            }
        }
    }

    // MARK: - Utility Functions
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }

        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }

        return String(nonce)
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}

// MARK: - ASAuthorizationControllerDelegate
extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        handleSignInWithAppleCompletion(authorization)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple errored: \(error.localizedDescription)")
        self.errorMessage = "Sign in with Apple failed. Please try again."
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("Unable to find a connected window scene")
        }
        return window
    }
}
