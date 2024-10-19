//
//  APIKey.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import Foundation

enum APIKey {
  static var `default`: String {
    guard let filePath = Bundle.main.path(forResource: "Keys", ofType: "plist")
    else {
      fatalError("Couldn't find file 'Keys.plist'.")
    }
    let plist = NSDictionary(contentsOfFile: filePath)
    guard let value = plist?.object(forKey: "GEMINI_API_KEY") as? String else {  // Updated key
      fatalError("Couldn't find key 'GEMINI_API_KEY' in 'GenAI-Info.plist'.")
    }
    if value.starts(with: "_") {
      fatalError(
        "Follow the instructions at https://ai.google.dev/tutorials/setup to get an API key."
      )
    }
    return value
  }
}

