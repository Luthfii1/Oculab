//
//  FOVDetailPresenter.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 11/05/25.
//

import Foundation
import SwiftUI

class FOVDetailPresenter: ObservableObject {
    var interactor: FOVDetailInteractor? = FOVDetailInteractor()

    @Published var zoomScale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var description: String?
    @Published var isError: Bool = false
    @Published var boxes: [BoxModel] = []
    @Published var selectedBox: BoxModel?
    @Published var fovDetail: FOVDetailData?
    @Published var interactionMode: InteractionMode = .panAndZoom
    @Published var newBoxRect: CGRect?
    
    // Frame information for coordinate transformation
    @Published var imageFrame: CGRect = .zero
    @Published var containerFrame: CGRect = .zero
    @Published var originalImageSize: CGSize = .zero

    func resetView() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            zoomScale = 1.0
            offset = .zero
        }
    }

    func getInstructionText() -> String {
        switch interactionMode {
        case .verify:
            return "Ketuk kotak anotasi bakteri yang ingin Anda verifikasi, tandai, atau hilangkan"
        case .add:
            return "Ketuk area lapangan pandang untuk menambahkan/menghapus anotasi bakteri"
        default:
            return ""
        }
    }

    func setInteractionMode(_ mode: InteractionMode) {
        withAnimation(.easeInOut) {
            interactionMode = mode
        }
    }

    func resetThenZoomToBox(_ box: BoxModel, screenGeometry: CGSize) {
        withAnimation(.easeOut(duration: 0.3)) {
            zoomScale = 1.0
            offset = .zero
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [self] in
            zoomToBox(box, screenGeometry: screenGeometry)
        }
    }

    func zoomToBox(_ box: BoxModel, screenGeometry: CGSize) {
        let newZoom: CGFloat = 2.0

        let boxCenterX = box.x + box.width / 2
        let boxCenterY = box.y + box.height / 2

        let screenCenterX = screenGeometry.width / 2
        let trayHeight = screenGeometry.height * 0.35
        let visibleAreaHeight = screenGeometry.height - trayHeight
        let visibleCenterY = visibleAreaHeight / 2

        let boxCenterScreenX = boxCenterX * newZoom
        let boxCenterScreenY = boxCenterY * newZoom

        let targetOffsetX = screenCenterX - boxCenterScreenX
        let targetOffsetY = visibleCenterY - boxCenterScreenY - 50

        withAnimation(.easeInOut(duration: 0.35)) {
            zoomScale = newZoom
            offset = CGSize(width: targetOffsetX, height: targetOffsetY)
        }
    }

    func confirmNewBox(_ finalRect: CGRect, fovId: UUID) {
        let originalX = (finalRect.origin.x - offset.width) / zoomScale
        let originalY = (finalRect.origin.y - offset.height) / zoomScale
        let originalWidth = finalRect.size.width / zoomScale
        let originalHeight = finalRect.size.height / zoomScale

        print("Box confirmed! Sending to BE...")
        print("x: \(originalX), y: \(originalY), width: \(originalWidth), height: \(originalHeight)")

        let newClientBox = BoxModel(
            id: UUID().uuidString,
            width: originalWidth,
            height: originalHeight,
            x: originalX,
            y: originalY,
            status: .none
        )
        boxes.append(newClientBox)

        Task {
            await addBox(
                fovId: fovId,
                x: originalX,
                y: originalY,
                width: originalWidth,
                height: originalHeight
            )
        }

        newBoxRect = nil
        interactionMode = .panAndZoom
    }

    func cancelNewBox() {
        newBoxRect = nil
        interactionMode = .panAndZoom
    }

    @MainActor
    func fetchData(fovId: UUID) async {
        do {
            let result = try await interactor?.fetchData(fovId: fovId)
            if let result {
                fovDetail = result
                boxes = result.boxes
            }
            print("fovDetail: \(String(describing: fovDetail))")
        } catch {
            switch error {
            case let NetworkError.apiError(apiResponse):
                print("Error type: \(apiResponse.data.errorType)")
                print("Error description: \(apiResponse.data.description)")

            case let NetworkError.networkError(message):
                print("Network error: \(message)")

            default:
                print("Unknown error: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func verifyingFOV(fovId: UUID) async {
        do {
            _ = try await interactor?.verifyingFOV(fovId: fovId)
        } catch {
            switch error {
            case let NetworkError.apiError(apiResponse):
                handleErrorState(isError: true, errorData: apiResponse.data)
            case let NetworkError.networkError(message):
                handleErrorState(
                    isError: true,
                    errorData: ApiErrorData(errorType: "NETWORK_ERROR", description: message)
                )
            default:
                handleErrorState(
                    isError: true,
                    errorData: ApiErrorData(errorType: "UNKNOW_ERROR", description: error.localizedDescription)
                )
            }
        }
    }

    @MainActor
    func updateBoxStatus(boxId: String, newStatus: BoxStatus) async {
        do {
            guard let index = boxes.firstIndex(where: { $0.id == boxId }) else { return }
            boxes[index].status = newStatus

            _ = try await interactor?.updateBoxStatus(boxId: boxId, newStatus: newStatus.rawValue)
        } catch {
            handleErrorState(
                isError: true,
                errorData: ApiErrorData(errorType: "UPDATE_ERROR", description: error.localizedDescription)
            )
        }
    }

    @MainActor
    func addBox(fovId: UUID, x: Double, y: Double, width: Double, height: Double) async {
        do {
            _ = try await interactor?.addBox(fovId: fovId, x: x, y: y, width: width, height: height)
        } catch {
            handleErrorState(
                isError: true,
                errorData: ApiErrorData(errorType: "ADD_ERROR", description: error.localizedDescription)
            )
        }
    }

    private func handleErrorState(isError: Bool, errorData: ApiErrorData? = nil) {
        DispatchQueue.main.async {
            if isError, let errorData = errorData {
                print("Error type: \(errorData.errorType)")
                print("Error description: \(errorData.description)")
                self.description = errorData.description
            }
            self.isError = isError
        }
    }
}

enum InteractionMode {
    case panAndZoom
    case verify
    case add
}
