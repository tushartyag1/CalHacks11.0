//
//  ItineraryItem.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI

struct ItineraryItem: Identifiable {
    let id: String
    let tripId: String
    let creatorId: String
    var title: String
    var description: String
    var date: Date
}
