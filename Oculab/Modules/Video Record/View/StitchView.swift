//
//  StitchView.swift
//  Oculab
//
//  Created by Muhammad Rasyad Caesarardhi on 01/11/24.
//

import SwiftUI

struct StitchedImageView: View {
    var stitchedImage: UIImage?

    var body: some View {
        VStack {
            if let image = stitchedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            } else {
                Text("No stitched image available")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .navigationTitle("Stitched Image")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StitchedImageView_Previews: PreviewProvider {
    static var previews: some View {
        StitchedImageView(stitchedImage: nil) // Preview with no image
        StitchedImageView(stitchedImage: UIImage(named: "example_image")) // Preview with an example image
    }
}
