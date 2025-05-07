//
//  FOVAlbum.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 12/11/24.
//

import SwiftUI

struct FOVAlbum: View {
    var fovGroup: FOVType
    @ObservedObject var presenter: AnalysisResultPresenter = .init()
    var examId: String

    let columns = [
        GridItem(.adaptive(minimum: 74))
    ]

    var selectedFOVs: [FOVData] {
        switch fovGroup {
        case .BTA0:
            return presenter.groupedFOVs?.bta0 ?? []
        case .BTA1TO9:
            return presenter.groupedFOVs?.bta1to9 ?? []
        case .BTAABOVE9:
            return presenter.groupedFOVs?.btaabove9 ?? []
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                Spacer().frame(height: Decimal.d24)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Array(selectedFOVs.enumerated()), id: \.element._id) { index, fov in
                        Button {
                            presenter.navigateToDetailed(fovData: fov, order: index, total: selectedFOVs.count)
                        } label: {
                            AsyncImage(url: URL(string: fov.image)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView().frame(height: 74)
                                case let .success(image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 74, height: 74)
                                        .clipped()
                                case .failure:
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 114)
                                        .foregroundColor(.red)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Decimal.d20)
            .navigationTitle("Album Gambar \(fovGroup.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.navigateBack()
                    }) {
                        HStack {
                            Image("back")
                        }
                    }
                }
            }
            .onAppear {
                Task {
                    await presenter.fetchData(examinationId: examId)
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    FOVAlbum(fovGroup: .BTA1TO9, examId: "f58d4d5c-b591-45c3-9e4e-080b1b11dd4a")
}
