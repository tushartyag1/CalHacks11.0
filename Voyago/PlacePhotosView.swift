//
//  PlacePhotosView.swift
//  Voyago
//
//  Created by Krishna Babani on 10/19/24.
//

import SwiftUI
import GooglePlaces

struct PlacePhotosView: View {
    let photoMetadata: [GMSPlacePhotoMetadata]
    @State private var images: [UIImage] = []
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(images, id: \.self) { image in
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 200, height: 200)
                        .clipped()
                        .cornerRadius(10)
                }
            }
        }
        .onAppear {
            loadImages()
        }
    }
    
    private func loadImages() {
        let placesClient = GMSPlacesClient.shared()
        
        for metadata in photoMetadata {
            placesClient.loadPlacePhoto(metadata) { image, error in
                if let error = error {
                    print("Error loading place photo: \(error.localizedDescription)")
                    return
                }
                if let image = image {
                    DispatchQueue.main.async {
                        self.images.append(image)
                    }
                }
            }
        }
    }
}
