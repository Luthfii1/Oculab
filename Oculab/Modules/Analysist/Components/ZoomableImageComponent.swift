//
//  ZoomableImageComponent.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/05/25.
//
import SwiftUI
import UIKit
import AVFoundation

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

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        guard let containerView = scrollView.viewWithTag(1),
              let imageView = containerView.viewWithTag(2) as? UIImageView else { return }

        // Only load image if it hasn't been loaded yet
        if imageView.image == nil, let url = imageURL, context.coordinator.imageLoadingTask == nil {
            // Cancel any prior task before issuing a new one
            context.coordinator.imageLoadingTask?.cancel()

            // Load image asynchronously
            let task = URLSession.shared.dataTask(with: url) { [weak coordinator = context.coordinator] data, _, _ in
                guard let coordinator = coordinator else { return }
                // Clear the stored task once it has finished
                defer { coordinator.imageLoadingTask = nil }

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

                        // Set content size to allow proper scrolling
                        scrollView.contentSize = containerView.frame.size

                        // Set initial zoom and offset
                        scrollView.zoomScale = self.zoomScale
                        scrollView.contentOffset = CGPoint(x: self.offset.width, y: self.offset.height)

                        // Add BoxesGroupComponentView only if it doesn't exist
                        if containerView.viewWithTag(3) == nil {
                            let hostingController = UIHostingController(
                                rootView: AnyView(
                                    BoxesGroupComponentView(
                                        zoomScale: self.zoomScale
                                    )
                                    .environmentObject(self.presenter)
                                )
                            )
                            hostingController.view.backgroundColor = .clear
                            hostingController.view.frame = imageView.frame
                            hostingController.view.clipsToBounds = true
                            hostingController.view.tag = 3 // Add tag to identify it
                            imageView.clipsToBounds = true
                            containerView.addSubview(hostingController.view)
                            
                            // Store the hosting controller in the coordinator to manage its lifecycle
                            context.coordinator.boxesHostingController = hostingController
                        } else {
                            // Update existing BoxesGroupComponentView if needed
                            if let existingView = containerView.viewWithTag(3) {
                                existingView.frame = imageView.frame
                                existingView.clipsToBounds = true
                            }
                            imageView.clipsToBounds = true
                        }
                    }
                }
            }
            context.coordinator.imageLoadingTask = task
            task.resume()
        }
        
        // Update the BoxesGroupComponentView's zoom scale if it exists
        if let _ = containerView.viewWithTag(3) {
            context.coordinator.updateBoxesView(with: zoomScale, presenter: presenter)
        }
        
        // ZOOM TO SELECTED BOX LOGIC
        if let selectedBox = presenter.selectedBox, let fovDetail = presenter.fovDetail {
            // Only auto-zoom if user is not currently interacting and we haven't already auto-zoomed to this box
            let boxIdentifier = "\(selectedBox.x)-\(selectedBox.y)-\(selectedBox.width)-\(selectedBox.height)"
            let currentBoxIdentifier = context.coordinator.currentSelectedBoxIdentifier ?? ""
            
            if !context.coordinator.isUserInteracting && boxIdentifier != currentBoxIdentifier {
                context.coordinator.currentSelectedBoxIdentifier = boxIdentifier
                context.coordinator.hasAutoZoomedToSelectedBox = true
                
                // Calculate the zoom and offset to center the selected box, but bias upward so the box is not hidden by the sheet
                let newZoom: CGFloat = 2.8
                let imageWidth = imageView.frame.width
                let imageHeight = imageView.frame.height
                let frameWidth = CGFloat(fovDetail.frameWidth)
                let frameHeight = CGFloat(fovDetail.frameHeight)
                
                // Convert box center from box coordinates to image coordinates
                let boxCenterX = (selectedBox.x + selectedBox.width / 2) / frameWidth * imageWidth
                let boxCenterY = (selectedBox.y + selectedBox.height / 2) / frameHeight * imageHeight
                
                let screenWidth = scrollView.bounds.width
                let screenHeight = scrollView.bounds.height
                let verticalBias: CGFloat = screenHeight * 0.3 // move box up by 30% of screen height
                
                let offsetX = max(0, boxCenterX * newZoom - screenWidth / 2)
                let offsetY = max(0, boxCenterY * newZoom - screenHeight / 2 + verticalBias)
                
                // Only animate if not already zoomed to this box
                if abs(scrollView.zoomScale - newZoom) > 0.01 || abs(scrollView.contentOffset.x - offsetX) > 5 || abs(scrollView.contentOffset.y - offsetY) > 5 {
                    UIView.animate(withDuration: 0.35) {
                        scrollView.zoomScale = newZoom
                        scrollView.contentOffset = CGPoint(x: offsetX, y: offsetY)
                    }
                }
            }
        } else {
            // RESET ZOOM/OFFSET WHEN NO BOX IS SELECTED
            if !context.coordinator.isUserInteracting {
                context.coordinator.currentSelectedBoxIdentifier = nil
                context.coordinator.hasAutoZoomedToSelectedBox = false
                
                let defaultZoom: CGFloat = 1.0
                let defaultOffset = CGPoint(x: 0, y: 0)
                
                if abs(scrollView.zoomScale - defaultZoom) > 0.01 || abs(scrollView.contentOffset.x - defaultOffset.x) > 5 || abs(scrollView.contentOffset.y - defaultOffset.y) > 5 {
                    UIView.animate(withDuration: 0.2) {
                        scrollView.zoomScale = defaultZoom
                        scrollView.contentOffset = defaultOffset
                    }
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ZoomableImageComponent
        private var isZooming = false
        var isUserInteracting = false
        var hasAutoZoomedToSelectedBox = false
        var currentSelectedBoxIdentifier: String?
        var boxesHostingController: UIHostingController<AnyView>?
        private var interactionResetTimer: Timer?
        var imageLoadingTask: URLSessionDataTask?

        init(_ parent: ZoomableImageComponent) {
            self.parent = parent
        }

        deinit {
            interactionResetTimer?.invalidate()
            imageLoadingTask?.cancel()
        }
        
        func updateBoxesView(with zoomScale: CGFloat, presenter: FOVDetailPresenter) {
            // Update the hosting controller's root view with new zoom scale
            if let hostingController = boxesHostingController {
                hostingController.rootView = AnyView(
                    BoxesGroupComponentView(zoomScale: zoomScale)
                        .environmentObject(presenter)
                )
            }
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return scrollView.viewWithTag(1)
        }
        
        func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            isZooming = true
            isUserInteracting = true
            // Cancel any pending reset timer
            interactionResetTimer?.invalidate()
        }
        
        func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
            isUserInteracting = true
            // Cancel any pending reset timer
            interactionResetTimer?.invalidate()
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            DispatchQueue.main.async {
                self.parent.zoomScale = scrollView.zoomScale
            }
            
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
                
                // Update the boxes view frame to match the image view
                if let boxesView = containerView.viewWithTag(3) {
                    boxesView.frame = frameToCenter
                }
            }
        }
        
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            isZooming = false
            DispatchQueue.main.async {
                self.parent.zoomScale = scale
            }
            
            // Start a timer to reset interaction flag - but it will be cancelled if user starts interacting again
            startInteractionResetTimer()
        }
        
        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate {
                startInteractionResetTimer()
            }
        }
        
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            startInteractionResetTimer()
        }
        
        private func startInteractionResetTimer() {
            // Cancel any existing timer
            interactionResetTimer?.invalidate()
            
            // Start a new timer with longer delay
            interactionResetTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
                self?.isUserInteracting = false
            }
        }
        
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            if !isZooming {
                DispatchQueue.main.async {
                    self.parent.offset = CGSize(
                        width: scrollView.contentOffset.x,
                        height: scrollView.contentOffset.y
                    )
                }
            }
        }
        
        @objc
        func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
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
    }
}
