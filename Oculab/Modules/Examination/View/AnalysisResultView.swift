//
//  AnalysisResultView.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import SwiftUI

struct AnalysisResultView: View {
    var examinationId: String

    @StateObject private var presenter = AnalysisResultPresenter()

    @State var selectedTBGrade: String = ""
    @State var numOfBTA: String = ""
    @State var inspectorNotes: String = ""
    @State private var currentStep: Int = 3
    @State var isVerifPopUpVisible = false
    @State var isLeavePopUpVisible = false

    var body: some View {
        ZStack {
            AppPopup(
                image: "Confirm-Leave",
                title: "Pemeriksaan Belum Selesai",
                description: "Pemeriksaan disimpan sebagai draft dan dapat diakses di halaman riwayat",
                buttons: [
                    AppButton(
                        title: "Keluar",
                        colorType: .destructive(.primary),
                        size: .large,
                        isEnabled: true
                    ) {
                        presenter.popToRoot()
                    },

                    AppButton(
                        title: "Periksa Kembali",
                        colorType: .destructive(.secondary),
                        isEnabled: true
                    ) {
                        isLeavePopUpVisible = false
                        print("Kembali ke Pemeriksaan")
                    }
                ],
                isVisible: $isLeavePopUpVisible
            )

            AppPopup(
                image: "Confirm",
                title: "Simpan Hasil Pemeriksaan",
                description: "Hasil pemeriksaan yang sudah disimpan tidak dapat diubah kembali",
                buttons: [
                    AppButton(
                        title: "Simpan",
                        colorType: .primary,
                        size: .large,
                        isEnabled: true
                    ) {
                        print("Simpan Tapped")
                    },

                    AppButton(
                        title: "Periksa Kembali",
                        colorType: .tertiary,
                        isEnabled: true
                    ) {
                        isVerifPopUpVisible = false
                        print("Periksa Kembali Tapped")
                    }
                ],
                isVisible: $isVerifPopUpVisible
            )

            NavigationView {
                VStack {
                    HStack {
                        Button(action: {
                            isLeavePopUpVisible = true
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(AppColors.slate100, lineWidth: 1)
                                    .frame(width: 36, height: 36)

                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.slate900)
                            }
                        }

                        Spacer()

                        Text("Pemeriksaan Baru")
                            .font(AppTypography.s4_1)
                            .foregroundColor(AppColors.slate900)

                        Spacer()
                        Spacer().frame(width: 44)
                    }
                    .padding(.horizontal)
                    .frame(height: 24)

                    AppStepper(
                        stepTitles: ["Data Pemeriksaan", "Hasil Pemeriksaan"],
                        currentStep: 1
                    )
                    .padding(.vertical, Decimal.d16)

                    if let errorMessage = presenter.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    } else if let examination = presenter.examinationResult {
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: Decimal.d24) {
                                VStack(alignment: .leading, spacing: Decimal.d16) {
                                    HStack {
                                        Image(systemName: "photo")
                                            .foregroundColor(AppColors.purple500)
                                        Text("Hasil Gambar")
                                            .font(AppTypography.s4_1)
                                            .padding(.leading, Decimal.d8)
                                    }
                                    Text("Ketuk untuk lihat detail gambar")
                                        .font(AppTypography.p3)
                                        .foregroundStyle(AppColors.slate300)

                                    if presenter.groupedFOVs?.bta0.isEmpty == true && presenter.groupedFOVs?.bta1to9
                                        .isEmpty == true && presenter.groupedFOVs?.btaabove9.isEmpty == true
                                    {
                                        ProgressView()
                                    } else {
                                        AsyncImage(url: URL(string: examination.imagePreview)) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(height: 114)
                                            case let .success(image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(height: 114)
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
                                        .cornerRadius(Decimal.d8)

                                        if presenter.groupedFOVs?.bta0.isEmpty != true {
                                            Button {} label: {
                                                FolderCardComponent(
                                                    title: .BTA0,
                                                    numOfImage: presenter.groupedFOVs?.bta0.count ?? 0
                                                )
                                            }
                                        }

                                        if presenter.groupedFOVs?.bta1to9.isEmpty != true {
                                            Button {} label: {
                                                FolderCardComponent(
                                                    title: .BTA1TO9,
                                                    numOfImage: presenter.groupedFOVs?.bta1to9.count ?? 0
                                                )
                                            }
                                        }

                                        if presenter.groupedFOVs?.btaabove9.isEmpty != true {
                                            Button {} label: {
                                                FolderCardComponent(
                                                    title: .BTAABOVE9,
                                                    numOfImage: presenter.groupedFOVs?.btaabove9.count ?? 0
                                                )
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, Decimal.d16)
                                .padding(.vertical, Decimal.d16)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .background(.white)
                                .cornerRadius(Decimal.d12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Decimal.d12)
                                        .stroke(AppColors.slate100)
                                )
                                .padding(.horizontal, Decimal.d20)

                                VStack(alignment: .leading, spacing: Decimal.d24) {
                                    HStack {
                                        Image(systemName: "photo")
                                            .foregroundColor(AppColors.purple500)
                                        Text("Hasil Interpretasi")
                                            .font(AppTypography.s4_1)
                                            .padding(.leading, Decimal.d8)
                                        Spacer()
                                        StatusTagComponent(type: .NEEDVALIDATION)
                                    }

                                    VStack(alignment: .leading, spacing: Decimal.d16) {
                                        Text("Interpretasi Sistem")
                                            .font(AppTypography.s4_1)

                                        HStack(alignment: .top) {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(AppColors.orange500)
                                            Text("Interpretasi sistem bukan merupakan hasil akhir untuk pasien")
                                        }

                                        GradingCardComponent(
                                            type: examination.systemGrading,
                                            confidenceLevel: presenter.confidenceLevel,
                                            n: presenter.resultQuantity
                                        )

                                    }.font(AppTypography.p4)

                                    VStack(alignment: .leading, spacing: Decimal.d16) {
                                        AppDropdown(
                                            title: "Interpretasi Petugas",
                                            placeholder: "Pilih kategori",
                                            isRequired: false,
                                            rightIcon: "chevron.down",
                                            isDisabled: false,
                                            choices: GradingType.allCases.dropLast().map { ($0.rawValue, $0.rawValue) },
                                            selectedChoice: $selectedTBGrade, isAddingNewPatient: .constant(false)
                                        )

                                        if selectedTBGrade == GradingType.SCANTY.rawValue {
                                            AppTextField(
                                                title: "Jumlah BTA",
                                                isRequired: false,
                                                placeholder: "Contoh: 8",
                                                isError: false,
                                                isDisabled: false,
                                                isNumberOnly: true,
                                                text: $numOfBTA
                                            )
                                        }

                                        AppTextBox(
                                            title: "Catatan Petugas",
                                            placeholder: "Contoh: Hanya terdapat 20 bakteri dari 60 lapangan pandang yang terkumpul",
                                            isRequired: false,
                                            isDisabled: false,
                                            text: $inspectorNotes
                                        )

                                        AppButton(
                                            title: "Simpan Hasil Pemeriksaan",
                                            rightIcon: "checkmark",
                                            colorType: .primary,
                                            size: .large,
                                            isEnabled: {
                                                if selectedTBGrade == GradingType.SCANTY.rawValue {
                                                    return !numOfBTA.isEmpty && Int(numOfBTA) != nil
                                                } else {
                                                    return selectedTBGrade != nil
                                                }
                                            }()
                                        ) {
                                            isVerifPopUpVisible = true
                                            print("Primary Button Tapped")
                                        }
                                    }
                                }
                                .padding(.horizontal, Decimal.d16)
                                .padding(.vertical, Decimal.d16)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .background(.white)
                                .cornerRadius(Decimal.d12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Decimal.d12)
                                        .stroke(AppColors.slate100)
                                )
                                .padding(.horizontal, Decimal.d20)
                            }
                        }
                    } else {
                        Spacer()
                        Text("Loading examination data...")
                            .foregroundColor(.gray)
                            .padding()
                        Spacer()
                    }
                }
                .onAppear {
                    presenter.fetchData(examinationId: examinationId)
                }

                Spacer()
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    AnalysisResultView(examinationId: "6f4e5288-3dfd-4be4-8a2e-8c60f09f07e2")
}
