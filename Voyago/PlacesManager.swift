//
//  PlacesManager.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import GooglePlaces

class PlacesManager {
    static let shared = PlacesManager()
    private let client: GMSPlacesClient
    
    private init() {
        client = GMSPlacesClient.shared()
    }
    
    func findPlaces(query: String, completion: @escaping ([GMSAutocompletePrediction]) -> Void) {
        let filter = GMSAutocompleteFilter()
        filter.type = .establishment
        
        client.findAutocompletePredictions(fromQuery: query, filter: filter, sessionToken: nil) { (results, error) in
            guard error == nil else {
                print("Autocomplete error: \(error!.localizedDescription)")
                completion([])
                return
            }
            
            guard let results = results else {
                completion([])
                return
            }
            
            completion(results)
        }
    }
    
    func fetchPlaceDetails(placeID: String, completion: @escaping (GMSPlace?) -> Void) {
        let fields: GMSPlaceField = [.name, .formattedAddress, .coordinate, .types, .priceLevel, .rating, .photos]
        client.fetchPlace(fromPlaceID: placeID, placeFields: fields, sessionToken: nil) { (place, error) in
            if let error = error {
                print("Error fetching place details: \(error.localizedDescription)")
                completion(nil)
            } else if let place = place {
                completion(place)
            }
        }
    }
}
