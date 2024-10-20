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
        guard let path = Bundle.main.path(forResource: "Keys", ofType: "plist") else {
            print("Keys.plist file not found")
            return nil
        }
        guard let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            print("Failed to load Keys.plist as dictionary")
            return nil
        }
        guard let value = dict[key] as? String else {
            print("Key '\(key)' not found in Keys.plist or value is not a string")
            return nil
        }
        return value
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        print("Attempting to load Google Places API Key")
        if let apiKey = PlistReader.value(for: "GOOGLE_PLACES_API_KEY") {
            print("Google Places API Key loaded successfully")
            GMSPlacesClient.provideAPIKey(apiKey)
            print("API Key provided to GMSPlacesClient")
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
                    HomeView()
                case .newAccount, .signedOut:
                    SignInView()
                }
            }
            .environmentObject(authManager)
        }
    }
}
