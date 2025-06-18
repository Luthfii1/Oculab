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

    func resetView() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            zoomScale = 1.0
            offset = .zero
        }
    }

    @MainActor
    func fetchData(fovId: UUID) async {
        do {
            let result = try await interactor?.fetchData(fovId: fovId)
            if let result {
                fovDetail = result
                boxes = result.boxes
            }
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
