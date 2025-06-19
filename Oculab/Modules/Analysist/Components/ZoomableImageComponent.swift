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
    @EnvironmentObject var presenter: FOVDetailPresenter
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

        let containerView = UIView()
        containerView.backgroundColor = .black
        containerView.tag = 1
        scrollView.addSubview(containerView)

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.tag = 2
        imageView.isUserInteractionEnabled = true
        containerView.addSubview(imageView)

        // Add double tap gesture
        let doubleTapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleDoubleTap(_:))
        )
        doubleTapGesture.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTapGesture)

        // Add single tap gesture for box creation
        let singleTapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleSingleTap(_:))
        )
        singleTapGesture.numberOfTapsRequired = 1
        containerView.addGestureRecognizer(singleTapGesture)

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        print("=== UPDATE UI VIEW DEBUG ===")
        print("Interaction mode: \(presenter.interactionMode)")
        print("Zoom scale: \(zoomScale)")
        print("Offset: \(offset)")
        print("New box rect: \(String(describing: presenter.newBoxRect))")
        print("ScrollView isScrollEnabled: \(scrollView.isScrollEnabled)")
        print("============================")
        
        guard let containerView = scrollView.viewWithTag(1),
              let imageView = containerView.viewWithTag(2) as? UIImageView else { return }

        // Disable scrolling when in add mode
        scrollView.isScrollEnabled = presenter.interactionMode != .add

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

                        // Set the container view frame
                        containerView.frame = CGRect(
                            x: 0,
                            y: 0,
                            width: viewSize.width,
                            height: max(scaledHeight, viewSize.height)
                        )

                        // Set the image view frame
                        imageView.frame = CGRect(
                            x: 0,
                            y: (containerView.bounds.height - scaledHeight) / 2,
                            width: viewSize.width,
                            height: scaledHeight
                        )
                        
                        // Store frame information in presenter for coordinate transformation
                        presenter.imageFrame = imageView.frame
                        presenter.containerFrame = containerView.frame
                        presenter.originalImageSize = imageSize
                        
                        print("=== IMAGE FRAME DEBUG ===")
                        print("Image size: \(imageSize)")
                        print("View size: \(viewSize)")
                        print("Scale: \(scale)")
                        print("Scaled height: \(scaledHeight)")
                        print("Container frame: \(containerView.frame)")
                        print("Image view frame: \(imageView.frame)")
                        print("ScrollView bounds: \(scrollView.bounds)")
                        print("========================")

                        // Set content size to allow proper scrolling
                        scrollView.contentSize = containerView.frame.size

                        // Set initial zoom and offset
                        scrollView.zoomScale = zoomScale
                        scrollView.contentOffset = CGPoint(x: offset.width, y: offset.height)

                        // Add BoxesGroupComponentView
                        let hostingController = UIHostingController(
                            rootView: BoxesGroupComponentView(
                                zoomScale: zoomScale
                            )
                            .environmentObject(presenter)
                        )
                        hostingController.view.backgroundColor = .clear
                        hostingController.view.frame = imageView.frame
                        containerView.addSubview(hostingController.view)
                    }
                }
            }.resume()
        }

         // TODO: ZOOM TO SELECTED BOX LOGIC
//         if let selectedBox = presenter.selectedBox, let _ = presenter.fovDetail {
//             let newZoom: CGFloat = 2.0
//             let boxCenterX = selectedBox.x + selectedBox.width / 2
//             let boxCenterY = selectedBox.y + selectedBox.height / 2
//             let screenWidth = scrollView.bounds.width
//             let screenHeight = scrollView.bounds.height
//             let offsetX = screenWidth / 2 - boxCenterX * newZoom
//             let offsetY = screenHeight / 2 - boxCenterY * newZoom
//
//             // Only animate if not already zoomed to this box
//             if abs(scrollView.zoomScale - newZoom) > 0.01 || abs(scrollView.contentOffset.x - offsetX) > 0.5 || abs(scrollView.contentOffset.y - offsetY) > 0.5 {
//                 UIView.animate(withDuration: 0.35) {
//                     scrollView.zoomScale = newZoom
//                     scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
//                 }
//             }
//         }

         // TODO: RESET ZOOM/OFFSET WHEN NO BOX IS SELECTED 
        // if presenter.selectedBox == nil {
        //     let defaultZoom: CGFloat = 1.0
        //     let defaultOffset = CGPoint(x: 0, y: 0)
        //     if abs(scrollView.zoomScale - defaultZoom) > 0.01 || abs(scrollView.contentOffset.x - defaultOffset.x) > 0.5 || abs(scrollView.contentOffset.y - defaultOffset.y) > 0.5 {
        //         UIView.animate(withDuration: 0.35) {
        //             scrollView.zoomScale = defaultZoom
        //             scrollView.contentOffset = defaultOffset
        //         }
        //     }
        // }
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
            if let containerView = scrollView.viewWithTag(1),
               let imageView = containerView.viewWithTag(2) {
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
            guard let scrollView = gesture.view?.superview?.superview as? UIScrollView,
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

        @objc func handleSingleTap(_ gesture: UITapGestureRecognizer) {
            print("Single tap detected! Interaction mode: \(parent.presenter.interactionMode)")
            guard let containerView = gesture.view,
                  let imageView = containerView.viewWithTag(2) as? UIImageView else { 
                print("Failed to get containerView or imageView from gesture")
                return 
            }
            
            print("=== TAP DEBUG ===")
            print("Container frame: \(containerView.frame)")
            print("Image view frame: \(imageView.frame)")
            print("Tap location in container: \(gesture.location(in: containerView))")
            print("Tap location in image: \(gesture.location(in: imageView))")
            print("==================")
            
            if parent.presenter.interactionMode == .add && parent.presenter.newBoxRect == nil {
                let containerLocation = gesture.location(in: containerView)
                let imageLocation = gesture.location(in: imageView)
                
                // Use the location relative to the image view for accurate positioning
                print("Creating new box at container location: \(containerLocation), image location: \(imageLocation)")
                let initialSize = CGSize(width: 100, height: 100)
                parent.presenter.newBoxRect = CGRect(
                    origin: CGPoint(
                        x: imageLocation.x - initialSize.width / 2,
                        y: imageLocation.y - initialSize.height / 2
                    ),
                    size: initialSize
                )
                print("New box rect set: \(String(describing:(parent.presenter.newBoxRect)) ?? "nil")")
            } else {
                print("Not in add mode or box already exists. Mode: \(parent.presenter.interactionMode), newBoxRect: \(String(describing:(parent.presenter.newBoxRect)) ?? "nil")")
            }
        }
    }
}
