//
//  TripDetailView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct TripDetailView: View {
    let tripId: String
    @StateObject private var viewModel = TripDetailViewModel()
    @State private var newItemTitle = ""
    @State private var newItemDescription = ""
    @State private var newItemDate = Date()
    
    var body: some View {
        List {
            Section(header: Text("Trip Details")) {
                Text("City: \(viewModel.trip?.city ?? "")")
                Text("Duration: \(viewModel.trip?.duration ?? 0) days")
                Text("Participants: \(viewModel.trip?.participants.count ?? 0)")
            }
            
            Section(header: Text("Shared Notes")) {
                TextEditor(text: Binding(
                    get: { viewModel.trip?.sharedNotes ?? "" },
                    set: { viewModel.updateSharedNotes($0) }
                ))
            }
            
            Section(header: Text("Itinerary")) {
                ForEach(viewModel.itineraryItems) { item in
                    VStack(alignment: .leading) {
                        Text(item.title).font(.headline)
                        Text(item.description).font(.subheadline)
                        Text(item.date, style: .date)
                        HStack {
                            Button(action: { viewModel.voteForItem(item.id, upvote: true) }) {
                                Image(systemName: "hand.thumbsup")
                            }
                            Text("\(item.votes.filter { $0.value }.count)")
                            Button(action: { viewModel.voteForItem(item.id, upvote: false) }) {
                                Image(systemName: "hand.thumbsdown")
                            }
                            Text("\(item.votes.filter { !$0.value }.count)")
                        }
                    }
                }
            }
            
            Section(header: Text("Add New Item")) {
                TextField("Title", text: $newItemTitle)
                TextField("Description", text: $newItemDescription)
                DatePicker("Date", selection: $newItemDate, displayedComponents: .date)
                Button("Add Item") {
                    viewModel.addItineraryItem(title: newItemTitle, description: newItemDescription, date: newItemDate)
                    newItemTitle = ""
                    newItemDescription = ""
                    newItemDate = Date()
                }
            }
        }
        .navigationTitle("Trip Details")
        .onAppear {
            viewModel.loadTrip(tripId: tripId)
        }
    }
}

class TripDetailViewModel: ObservableObject {
    @Published var trip: Trip?
    @Published var itineraryItems: [ItineraryItem] = []
    
    private let tripManager = TripManager()
    private let itineraryManager = ItineraryManager()
    private var tripListener: ListenerRegistration?
    private var itineraryListener: ListenerRegistration?
    
    func loadTrip(tripId: String) {
        tripListener = tripManager.listenForTripUpdates(tripId: tripId) { [weak self] trip in
            self?.trip = trip
        }
        
        itineraryListener = itineraryManager.listenForItineraryUpdates(tripId: tripId) { [weak self] items in
            self?.itineraryItems = items
        }
    }
    
    func updateSharedNotes(_ notes: String) {
        guard let tripId = trip?.id else { return }
        tripManager.updateSharedNotes(tripId: tripId, notes: notes) { error in
            if let error = error {
                print("Error updating shared notes: \(error.localizedDescription)")
            }
        }
    }
    
    func addItineraryItem(title: String, description: String, date: Date) {
        guard let tripId = trip?.id, let userId = Auth.auth().currentUser?.uid else { return }
        itineraryManager.addItineraryItem(tripId: tripId, creatorId: userId, title: title, description: description, date: date) { _, error in
            if let error = error {
                print("Error adding itinerary item: \(error.localizedDescription)")
            }
        }
    }
    
    func voteForItem(_ itemId: String, upvote: Bool) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        itineraryManager.voteForItem(itemId: itemId, userId: userId, upvote: upvote) { error in
            if let error = error {
                print("Error voting for item: \(error.localizedDescription)")
            }
        }
    }
    
    deinit {
        tripListener?.remove()
        itineraryListener?.remove()
    }
}
