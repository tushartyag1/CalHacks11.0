//
//  ContentView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import GoogleGenerativeAI

struct ContentView: View {
    let model = GenerativeModel(name: "gemini-pro", apiKey: APIKey.default)
    @State private var userPrompt = ""
    @State private var response: String = "I’m Gemini AI, your friendly digital sidekick. What’s on your mind?"
    @State private var isLoading = false
    @State private var wittyPrompts = [
        "Ask me anything, but keep it PG!",
        "Hit me with your best question!",
        "I promise not to tell anyone. What’s up?",
        "Be honest, did you come here for AI wisdom or just for fun?",
        "Let’s make it weird—ask me something you wouldn’t ask a human."
    ]
    
    var body: some View {
        ZStack {
            // Minimalist black background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Response Section
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 250)
                        .padding(.horizontal)
                    
                    ScrollView {
                        Text(response)
                            .font(.custom("Helvetica Neue", size: 24, relativeTo: .headline).weight(.light))
                            .foregroundColor(.white)
                            .padding(.horizontal)
                    }
                    .frame(maxHeight: 250)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(3)
                    }
                }
                
                // Witty Prompt Text
                Text(wittyPrompts.randomElement()!)
                    .font(.custom("Helvetica Neue", size: 18, relativeTo: .caption).weight(.light))
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // TextField Input
                VStack(spacing: 10) {
                    TextField("Ask anything...", text: $userPrompt, axis: .vertical)
                        .lineLimit(3)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(15)
                        .foregroundColor(.white)
                        .font(.custom("Helvetica Neue", size: 20, relativeTo: .body).weight(.regular))
                        .disableAutocorrection(true)
                    
                    Button(action: {
                        generateResponse()
                    }) {
                        Text("Submit")
                            .font(.custom("Helvetica Neue", size: 20, relativeTo: .body).weight(.semibold))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
            }
            .padding()
        }
    }
    
    func generateResponse() {
        guard !userPrompt.isEmpty else {
            showFunnyResponse("C’mon, you’ve got something! Just type it!")
            return
        }
        
        isLoading = true
        response = ""
        
        Task {
            do {
                let result = try await model.generateContent(userPrompt)
                isLoading = false
                response = result.text ?? "AI is speechless... Try again?"
                userPrompt = ""
            } catch {
                isLoading = false
                response = "Oops! Even AI makes mistakes sometimes. Try again!"
            }
        }
    }
    
    func showFunnyResponse(_ text: String) {
        response = text
    }
}

#Preview {
    ContentView()
}
