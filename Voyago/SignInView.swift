//
//  SignInView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack {
            Text("Welcome to Voyago")
                .font(.largeTitle)
                .padding()
            
            SignInWithAppleButton(
                .signIn,
                onRequest: { request in
                    let appleIDRequest = authManager.prepareSignInWithApple()
                    request.requestedScopes = appleIDRequest.requestedScopes
                    request.nonce = appleIDRequest.nonce
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authResults):
                        print("Authorization successful.")
                        authManager.handleSignInWithAppleCompletion(authResults)
                    case .failure(let error):
                        print("Authorization failed: " + error.localizedDescription)
                        authManager.errorMessage = "Sign in with Apple failed. Please try again."
                    }
                }
            )
            .frame(height: 44)
            .padding()
        }
        .alert(item: Binding(
            get: { authManager.errorMessage.map { ErrorWrapper(error: $0) } },
            set: { _ in authManager.errorMessage = nil }
        )) { errorWrapper in
            Alert(title: Text("Error"), message: Text(errorWrapper.error), dismissButton: .default(Text("OK")))
        }
    }
}

