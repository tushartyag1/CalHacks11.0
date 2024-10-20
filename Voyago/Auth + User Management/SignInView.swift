//
//  SignInView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import AuthenticationServices
import Glur

struct SignInView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var currentBackgroundIndex = 0
    @State private var nextBackgroundIndex = 1
    @State private var animationProgress: CGFloat = 0
    
    let backgrounds = (1...4).map { "background_\($0)" }
    let animationDuration: Double = 6.0
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                
                VStack(spacing: 8) {
                    Text("Welcome to Voyago")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("A shared adventure, planned effortlessly. No endless group chats, no scattered itineraries. Just one place where everything comes together, in perfect harmony.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
                
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
                .frame(height: 60)
                .frame(maxWidth: .infinity)
                .cornerRadius(20)
                .padding(.horizontal, 20)
                .padding(.bottom, 80)
            }
            .background(
                Image("backgroundImage")
                    .resizable()
                    .scaledToFill()
                    .glur()
                    .ignoresSafeArea()
            )
        }
        .alert(item: Binding(
            get: { authManager.errorMessage.map { ErrorWrapper(error: $0) } },
            set: { _ in authManager.errorMessage = nil }
        )) { errorWrapper in
            Alert(title: Text("Error"), message: Text(errorWrapper.error), dismissButton: .default(Text("OK")))
        }
    }
}
