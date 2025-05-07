//
//  ZoomableScrollView.swift
//  Oculab
//
//  Created by Bunga Prameswari on 04/05/25.
//

import SwiftUI
import UIKit

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()

        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .black
        scrollView.contentInsetAdjustmentBehavior = .never

        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.frame = scrollView.bounds
        scrollView.addSubview(hostedView)

        context.coordinator.scrollView = scrollView
        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = content
        context.coordinator.centerContent()
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableScrollView
        var hostingController: UIHostingController<Content>
        weak var scrollView: UIScrollView?

        init(_ parent: ZoomableScrollView) {
            self.parent = parent
            self.hostingController = UIHostingController(rootView: parent.content)
            hostingController.view.backgroundColor = .clear
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController.view
        }

        func scrollViewDidZoom(_: UIScrollView) {
            centerContent()
        }

        func centerContent() {
            guard let scrollView = scrollView,
                  let contentView = hostingController.view else { return }

            let offsetX = max((scrollView.bounds.width - contentView.frame.width) * 0.5, 0)
            let offsetY = max((scrollView.bounds.height - contentView.frame.height) * 0.5, 0)
            contentView.center = CGPoint(
                x: scrollView.contentSize.width * 0.5 + offsetX,
                y: scrollView.contentSize.height * 0.5 + offsetY
            )
        }
    }
}
