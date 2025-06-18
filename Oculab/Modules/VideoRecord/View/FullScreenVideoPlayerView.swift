//
//  FullScreenVideoPlayerView.swift
//  Oculab
//
//  Created by Rangga Yudhistira Brata on 24/05/25.
//

import SwiftUI
import AVKit

struct FullScreenVideoPlayerView: View {
    let videoURL: URL
    var onClose: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VideoPlayer(player: AVPlayer(url: videoURL)) {
                // Optional: Kosongkan untuk sembunyikan overlay bawaan
            }
            .onAppear {
                let player = AVPlayer(url: videoURL)
                player.play()
            }
            .edgesIgnoringSafeArea(.all)
            
            // Tombol "Close"
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .padding()
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
}
