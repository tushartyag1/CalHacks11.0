//
//  VoyagoApp.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import FirebaseCore
import GooglePlaces

struct PlistReader {
    static func value(for key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            return nil
        }
        return dict[key] as? String
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        if let apiKey = PlistReader.value(for: "GOOGLE_PLACES_API_KEY") {
            GMSPlacesClient.provideAPIKey(apiKey)
        } else {
            print("Failed to load Google Places API Key")
        }
        
        return true
    }
}

@main
struct VoyagoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            Group {
                switch authManager.authState {
                case .signedIn:
                    TabView {
                        Tab("Gemini", systemImage: "tray.and.arrow.down.fill") {
                            MainView()
                        }
                        Tab("Gemini", systemImage: "tray.and.arrow.down.fill") {
                            ContentView()
                        }
                    }
                case .newAccount:
                    SignInView()
                case .signedOut:
                    SignInView()
                }
            }
            .environmentObject(authManager)
        }
    }
}
