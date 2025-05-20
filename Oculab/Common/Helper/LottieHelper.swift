//
//  LottieHelper.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 20/05/25.
//

import SwiftUI
import Lottie

struct LottieHelper: UIViewRepresentable {
    
    var animationName: String
    var contentMode: UIView.ContentMode = .scaleAspectFit
    var loopMode: LottieLoopMode = .loop
    var onAnimationDidFinish: (() -> Void)? = nil

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView()
        animationView.animation = LottieAnimation.named(animationName)
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode
        animationView.play()
        return animationView
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {
        uiView.animation = LottieAnimation.named(animationName)
        uiView.play()
    }
}
