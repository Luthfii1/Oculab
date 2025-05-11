//
//  ZoomableImageComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/05/25.
//

import SwiftUI
import UIKit

struct ZoomableImageComponent: UIViewRepresentable {
    let imageURL: URL?
    @Binding var zoomScale: CGFloat
    @Binding var offset: CGSize

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 1.0
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .black
        scrollView.decelerationRate = .fast
        scrollView.contentInsetAdjustmentBehavior = .never

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.tag = 1
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)

        // Add double tap gesture
        let doubleTapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTapGesture.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTapGesture)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let imageView = scrollView.viewWithTag(1) as? UIImageView else { return }

        // Only load image if it hasn't been loaded yet
        if imageView.image == nil, let url = imageURL {
            // Load image asynchronously
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageView.image = image

                        // Calculate the proper size for the image view to fill width
                        let imageSize = image.size
                        let viewSize = scrollView.bounds.size

                        // Calculate height to maintain aspect ratio while filling width
                        let scale = viewSize.width / imageSize.width
                        let scaledHeight = imageSize.height * scale

                        // Set the image view frame to fill width
                        imageView.frame = CGRect(
                            x: 0,
                            y: (viewSize.height - scaledHeight) / 2,
                            width: viewSize.width,
                            height: scaledHeight
                        )

                        // Set content size to allow proper scrolling
                        scrollView.contentSize = CGSize(
                            width: viewSize.width,
                            height: max(scaledHeight, viewSize.height)
                        )

                        // Set initial zoom and offset
                        scrollView.zoomScale = zoomScale
                        scrollView.contentOffset = CGPoint(x: offset.width, y: offset.height)
                    }
                }
            }.resume()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableImageComponent
        private var isZooming = false

        init(_ parent: ZoomableImageComponent) {
            self.parent = parent
        }

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(1)
        }

        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            isZooming = true
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            parent.zoomScale = scrollView.zoomScale

            // Center the image when zoomed out
            if let imageView = scrollView.viewWithTag(1) {
                let boundsSize = scrollView.bounds.size
                var frameToCenter = imageView.frame

                if frameToCenter.width < boundsSize.width {
                    frameToCenter.origin.x = (boundsSize.width - frameToCenter.width) / 2
                } else {
                    frameToCenter.origin.x = 0
                }

                if frameToCenter.height < boundsSize.height {
                    frameToCenter.origin.y = (boundsSize.height - frameToCenter.height) / 2
                } else {
                    frameToCenter.origin.y = 0
                }

                imageView.frame = frameToCenter
            }
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            isZooming = false
            parent.zoomScale = scale
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if !isZooming {
                parent.offset = CGSize(
                    width: scrollView.contentOffset.x,
                    height: scrollView.contentOffset.y
                )
            }
        }

        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scrollView = gesture.view?.superview as? UIScrollView,
                  let imageView = gesture.view as? UIImageView else { return }

            if scrollView.zoomScale > 1.0 {
                // Zoom out
                scrollView.setZoomScale(1.0, animated: true)
            } else {
                // Zoom in to the tapped point
                let point = gesture.location(in: imageView)
                let rect = CGRect(x: point.x - 50, y: point.y - 50, width: 100, height: 100)
                scrollView.zoom(to: rect, animated: true)
            }
        }
    }
}
