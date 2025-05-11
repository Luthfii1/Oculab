//
//  FOVDetail.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 12/11/24.
//

// import SwiftUI
//
// struct FOVDetail: View {
//    var slideId: String
//    var fovData: FOVData
//    var order: Int
//    var total: Int
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                ZoomableScrollView { //UIKit
//                    GeometryReader { geo in
//                        VStack {
//                            AsyncImage(url: URL(string: fovData.image)) { phase in
//                                switch phase {
//                                case .empty:
//                                    ProgressView()
//                                        .frame(width: geo.size.width, height: geo.size.height)
//
//                                case let .success(image):
//                                    image
//                                        .resizable()
//                                        .aspectRatio(contentMode: .fit)
//                                        .frame(width: geo.size.width, height: geo.size.height)
//
//                                case .failure:
//                                    Image(systemName: "xmark.octagon")
//                                        .resizable()
//                                        .scaledToFit()
//                                        .frame(width: geo.size.width / 2)
//                                        .foregroundColor(.red)
//
//                                @unknown default:
//                                    EmptyView()
//                                }
//                            }
//                        }
//                        .frame(width: geo.size.width, height: geo.size.height)
//                    }
//                }
//
//                VStack(spacing: Decimal.d8 + Decimal.d2) {
//                    Spacer()
//                    Text("Jumlah Bakteri: \(fovData.systemCount) BTA")
//                        .font(AppTypography.h3)
//                    Text(String(format: "%.2f%% confidence level", fovData.confidenceLevel * 100))
//                        .font(AppTypography.p4)
//                    HStack {
//                        Image("Contrast")
//                        Image("Brightness")
//                        Image("Comment")
//                    }
//                }
//                .padding(.bottom, Decimal.d20)
//            }
//            .foregroundStyle(AppColors.slate0)
//            .padding(.horizontal, CGFloat(20))
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    VStack {
//                        Text("Gambar \(order + 1) dari \(total)")
//                            .font(AppTypography.s4_1)
//                        Text("ID \(slideId)")
//                            .font(AppTypography.p3)
//                    }.foregroundStyle(AppColors.slate0)
//                }
//
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button(action: {
//                        Router.shared.navigateBack()
//                    }) {
//                        HStack {
//                            Image("back")
//                                .foregroundStyle(AppColors.slate0)
//                        }
//                    }
//                }
//            }
//            .background(.black)
//        }
//        .navigationBarBackButtonHidden()
//    }
// }

// #Preview {
//    FOVDetail(
//        slideId: "A#EKNIR",
//        fovData: FOVData(
//            image: "https://is3.cloudhost.id/oculab-fov/oculab-fov/c5b14ad1-c15b-4d1c-bf2f-1dcf7fbf8d8d.png",
//            type: .BTA1TO9,
//            order: 1,
//            systemCount: 12,
//            confidenceLevel: 0.95
//        ),
//        order: 1,
//        total: 10
//    )
// }

import SwiftUI
import UIKit

struct FOVDetail: View {
    var slideId: String
    var fovData: FOVData
    var order: Int
    var total: Int

    @StateObject private var presenter: FOVDetailPresenter = .init()

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)

                ZoomableImageView(
                    imageURL: URL(string: fovData.image),
                    zoomScale: $presenter.zoomScale,
                    offset: $presenter.offset
                )

                VStack(spacing: Decimal.d8 + Decimal.d2) {
                    Spacer()
                    VStack(spacing: Decimal.d4) {
                        Text("Jumlah Bakteri: \(fovData.systemCount) BTA")
                            .font(AppTypography.h3)
                            .foregroundColor(.white)
                        Text(String(format: "%.2f%% confidence level", fovData.confidenceLevel * 100))
                            .font(AppTypography.p4)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, Decimal.d16)
                    .padding(.vertical, Decimal.d12)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(Decimal.d8)

                    HStack(spacing: Decimal.d16) {
                        Button(action: {
                            // Add contrast adjustment
                        }) {
                            Image("Contrast")
                                .foregroundColor(.white)
                        }

                        Button(action: {
                            // Add brightness adjustment
                        }) {
                            Image("Brightness")
                                .foregroundColor(.white)
                        }

                        Button(action: {
                            // Add comment functionality
                        }) {
                            Image("Comment")
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, Decimal.d16)
                    .padding(.vertical, Decimal.d12)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(Decimal.d8)
                }
                .padding(.bottom, Decimal.d20)
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Gambar \(order + 1) dari \(total)")
                            .font(AppTypography.s4_1)
                            .foregroundColor(.white)
                        Text("ID \(slideId)")
                            .font(AppTypography.p3)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.navigateBack()
                    }) {
                        HStack {
                            Image("back")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await presenter.verifyingFOV(fovId: fovData._id)
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

struct ZoomableImageView: UIViewRepresentable {
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

                        // Calculate the proper size for the image view
                        let imageSize = image.size
                        let viewSize = scrollView.bounds.size
                        let widthRatio = viewSize.width / imageSize.width
                        let heightRatio = viewSize.height / imageSize.height
                        let scale = min(widthRatio, heightRatio)

                        let scaledWidth = imageSize.width * scale
                        let scaledHeight = imageSize.height * scale

                        // Set the image view frame
                        imageView.frame = CGRect(
                            x: (viewSize.width - scaledWidth) / 2,
                            y: (viewSize.height - scaledHeight) / 2,
                            width: scaledWidth,
                            height: scaledHeight
                        )

                        // Set content size to allow proper scrolling
                        scrollView.contentSize = CGSize(
                            width: max(scaledWidth, viewSize.width),
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
        var parent: ZoomableImageView
        private var isZooming = false

        init(_ parent: ZoomableImageView) {
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

#Preview {
    FOVDetail(
        slideId: "A#EKNIR",
        fovData: FOVData(
            image: "https://is3.cloudhost.id/oculab-fov/oculab-fov/c5b14ad1-c15b-4d1c-bf2f-1dcf7fbf8d8d.png",
            type: .BTA1TO9,
            order: 1,
            systemCount: 12,
            confidenceLevel: 95.0
        ),
        order: 1,
        total: 10
    )
}
