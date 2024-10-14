//
//  VideoRecordView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 14/10/24.
//

import SwiftUI

struct VideoRecordView: View {
    @StateObject private var videoRecordPresenter = VideoRecordPresenter()

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: Camera View

            CameraView()
                .environmentObject(videoRecordPresenter)
                .ignoresSafeArea()

            // MARK: Video Control

            ZStack {
                if videoRecordPresenter.hasTaken {
                    Group {
                        // Button save video
                        Button {
                            print("save video")
                        } label: {
                            Text("Simpan Gambar")
                                .foregroundStyle(.black)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(.white)
                                .font(.callout)
                                .clipShape(RoundedRectangle(cornerRadius: .infinity))
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)

                        // Button retake video
                        Button {
                            print("retake video")
                        } label: {
                            HStack(alignment: .center, spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .resizable()
                                    .renderingMode(.template)
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundStyle(.white)
                                    .frame(width: 24, height: 24)

                                Text("Ambil Ulang")
                                    .foregroundStyle(.white)
                                    .font(.callout)
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    // Button start record
                    Button {
                        print("button pressed")
                    } label: {
                        Image(systemName: "button.programmable")
                            .resizable()
                            .renderingMode(.template)
                            .aspectRatio(contentMode: .fit)
                            .foregroundStyle(.white)
                            .frame(width: 60, height: 60)
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 48)
            .padding(.horizontal, 20)
        }
        .ignoresSafeArea(.all)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    VideoRecordView()
}
