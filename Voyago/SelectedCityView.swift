//
//  SelectedCityView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/20/24.
//

import SwiftUI
import GooglePlaces

struct SelectedCityView: View {
    let placeID: String
    @ObservedObject var viewModel: CreateTripViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let place = viewModel.selectedPlace {
                    cityContent(place: place)
                } else {
                    ProgressView()
                }
            }
            .padding()
        }
        .navigationBarTitle("Trip Details", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.left")
            Text("Back")
        })
        .onAppear {
            viewModel.fetchPlaceDetails(placeID: placeID)
        }
    }
    
    private func cityContent(place: GMSPlace) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(place.name ?? "Selected City")
                .font(.custom("ClashDisplay-Semibold", size: 34))
                .foregroundColor(.accentColor)
            
            Text(place.formattedAddress ?? "")
                .font(.custom("ClashDisplay-Regular", size: 18))
                .foregroundColor(.secondary)
            
            if let photos = place.photos, !photos.isEmpty {
                PlacePhotosView(photoMetadata: Array(photos.prefix(5)))
                    .frame(height: 200)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(place.types ?? [], id: \.self) { type in
                        Text(type)
                            .font(.custom("ClashDisplay-Regular", size: 14))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.accentColor.opacity(0.1))
                            .foregroundColor(.accentColor)
                            .cornerRadius(15)
                    }
                }
            }
            
            Text("Trip Details")
                .font(.custom("ClashDisplay-Semibold", size: 28))
                .foregroundColor(.accentColor)
                .padding(.top)
            
            DatePicker("Start Date", selection: $viewModel.startDate, in: Date()..., displayedComponents: .date)
                .font(.custom("ClashDisplay-Regular", size: 18))
            
            DatePicker("End Date", selection: $viewModel.endDate, in: viewModel.startDate..., displayedComponents: .date)
                .font(.custom("ClashDisplay-Regular", size: 18))
            
            Spacer()
            
            NavigationLink(destination: InviteFriendsView(tripId: viewModel.tripId, inviteFriend: viewModel.inviteFriend)) {
                Text("Create Trip")
                    .font(.custom("ClashDisplay-Semibold", size: 18))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .cornerRadius(10)
            }
            .simultaneousGesture(TapGesture().onEnded {
                viewModel.createTrip()
            })
        }
    }
}
