//
//  AnalysisResultView.swift
//  Oculab
//
//  Created by Risa on 14/10/24.
//

import SwiftUI

struct AnalysisResultView: View {
    @State var selectedTBGrade: String? = nil
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
                        print("Simpan Tapped")
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
                        stepTitles: ["Data Pasien", "Data Sediaan", "Hasil"],
                        currentStep: 2
                    )
                    .padding(.vertical, Decimal.d16)

                    ScrollView {
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

                                // Example placeholder for image results
                                FolderCardComponent(
                                    title: .BTA0,
                                    numOfImage: 9
                                )
                                FolderCardComponent(
                                    title: .BTA1TO9,
                                    numOfImage: 9
                                )
                                FolderCardComponent(
                                    title: .BTAABOVE9,
                                    numOfImage: 9
                                )
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
                                    StatusTagComponent(type: .draft)
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
                                        type: .SCANTY,
                                        confidenceLevel: .lowConfidence
                                    )

                                }.font(AppTypography.p4)

                                VStack(alignment: .leading, spacing: Decimal.d16) {
                                    AppDropdown(
                                        title: "Interpretasi Petugas",
                                        placeholder: "Pilih kategori",
                                        isRequired: false,
                                        rightIcon: "chevron.down",
                                        isDisabled: false,
                                        choices: GradingType.allCases.map { $0.rawValue },
                                        isExtended: true,
                                        selectedChoice: $selectedTBGrade
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

                    Spacer()
                }
                .navigationBarHidden(true)
            }
        }
    }
}

#Preview {
    AnalysisResultView()
}
