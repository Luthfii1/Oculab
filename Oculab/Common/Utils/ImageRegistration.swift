import CoreImage
import Vision

class ImageRegistration {
    // Singleton instance of ImageRegistration
    static let shared = ImageRegistration()

    // CIContext for image rendering
    private let context = CIContext()

    // Property to store the current stitched image in memory
    private var currentStitchedImage: CIImage?

    private init() {}

    enum Mechanism: String, Identifiable, CaseIterable {
        case translational
        case homographic

        var id: String { rawValue }
        var label: String { rawValue.capitalized }
    }

    // Function to register and stitch images
    func register(
        floatingImage: PlatformImage,
        referenceImage: PlatformImage? = nil,
        registrationMechanism: ImageRegistration.Mechanism,
        _ completion: @escaping (_ compositedImage: PlatformImage, _ paddedBackground: PlatformImage)
            -> Void
    ) {
        let ciFloatingImage = CIImage(floatingImage)
        let ciReferenceImage = referenceImage != nil ? CIImage(referenceImage!) :
            (currentStitchedImage ?? ciFloatingImage)

        DispatchQueue.global(qos: .userInitiated).async {
            let imageRequestHandler = VNImageRequestHandler(ciImage: ciReferenceImage)
            let request: VNImageRegistrationRequest

            switch registrationMechanism {
            case .translational:
                request = VNTranslationalImageRegistrationRequest(targetedCIImage: ciFloatingImage)
            case .homographic:
                request = VNHomographicImageRegistrationRequest(targetedCIImage: ciFloatingImage)
            }

            do {
                try imageRequestHandler.perform([request])
            } catch {
                print(error.localizedDescription)
            }

            DispatchQueue.main.async {
                guard let alignmentObservation = request.results?.first as? VNImageAlignmentObservation else { return }

                let ciAlignedImage = self.makeAlignedImage(
                    floatingImage: ciFloatingImage,
                    alignmentObservation: alignmentObservation
                )

                let composite = ciAlignedImage.composited(over: ciReferenceImage)
                self.currentStitchedImage = composite

                let cgComposite = self.context.createCGImage(composite, from: composite.extent)!
                let compositeImage = PlatformImage(cgImage: cgComposite)

                let paddedReference = ciReferenceImage.cropped(to: composite.extent)
                let cgPaddedReferenceImage = self.context.createCGImage(paddedReference, from: composite.extent)!

                let paddedReferenceImage = PlatformImage(cgImage: cgPaddedReferenceImage)

                completion(compositeImage, paddedReferenceImage)
            }
        }
    }

    private func makeAlignedImage(
        floatingImage: CIImage,
        alignmentObservation: VNImageAlignmentObservation
    ) -> CIImage {
        if let translationObservation = alignmentObservation as? VNImageTranslationAlignmentObservation {
            return floatingImage.transformed(by: translationObservation.alignmentTransform)
        } else if let homographicObservation = alignmentObservation as? VNImageHomographicAlignmentObservation {
            let warpTransform = homographicObservation.warpTransform
            let quad = makeWarpedQuad(for: floatingImage.extent, using: warpTransform)
            let transformParameters = [
                "inputTopLeft": CIVector(cgPoint: quad.topLeft),
                "inputTopRight": CIVector(cgPoint: quad.topRight),
                "inputBottomRight": CIVector(cgPoint: quad.bottomRight),
                "inputBottomLeft": CIVector(cgPoint: quad.bottomLeft)
            ]
            return floatingImage.applyingFilter("CIPerspectiveTransform", parameters: transformParameters)
        } else {
            fatalError("Unhandled VNImageAlignmentObservation type.")
        }
    }

    private struct Quad {
        let topLeft: CGPoint
        let topRight: CGPoint
        let bottomLeft: CGPoint
        let bottomRight: CGPoint
    }

    private func warpedPoint(_ point: CGPoint, using warpTransform: simd_float3x3) -> CGPoint {
        let vector0 = SIMD3<Float>(x: Float(point.x), y: Float(point.y), z: 1)
        let vector1 = warpTransform * vector0
        return CGPoint(x: CGFloat(vector1.x / vector1.z), y: CGFloat(vector1.y / vector1.z))
    }

    private func makeWarpedQuad(for rect: CGRect, using warpTransform: simd_float3x3) -> Quad {
        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY

        let topLeft = CGPoint(x: minX, y: maxY)
        let topRight = CGPoint(x: maxX, y: maxY)
        let bottomLeft = CGPoint(x: minX, y: minY)
        let bottomRight = CGPoint(x: maxX, y: minY)

        return Quad(
            topLeft: warpedPoint(topLeft, using: warpTransform),
            topRight: warpedPoint(topRight, using: warpTransform),
            bottomLeft: warpedPoint(bottomLeft, using: warpTransform),
            bottomRight: warpedPoint(bottomRight, using: warpTransform)
        )
    }
}
