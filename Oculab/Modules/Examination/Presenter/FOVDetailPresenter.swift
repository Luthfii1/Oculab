//
//  FOVDetailPresenter.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 08/06/25.
//

import Foundation

class FOVDetailPresenter: ObservableObject {
    // b13046c1-16cb-4a68-a657-225537390109
    var view: FOVDetail?
    var interactor: FOVDetailInteractor? = FOVDetailInteractor()

    @Published var fovDetail: FOVDetailData?
    @Published var boxes: [BoxModel] = []

    // MARK: State for view

    func popToRoot() {
        Router.shared.popToRoot()
    }

    @MainActor
    func fetchData(fovId: String) async {
        do {
            let result = try await interactor?.fetchData(fovId: fovId)
            if let result {
                fovDetail = result
                boxes = result.boxes
            }
            print(boxes)

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
}
