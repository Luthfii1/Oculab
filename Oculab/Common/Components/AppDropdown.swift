//
//  AppDropdown.swift
//  Oculab
//
//  Created by Risa on 15/10/24.
//

import SwiftUI

struct AppDropdown: View {
    var title: String
    @State private var isExtended = true
    var data: [(key: String, value: String)]
    var titleSize: Font

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(AppTypography.s4_1)
            VStack(alignment: .leading) {
                HStack {
                    Text(title)
                        .padding(.leading, Decimal.d8)
                    Spacer()

                    Image(systemName: isExtended ? "chevron.up" : "chevron.down")
                }

                if isExtended {
                    ExtendedAppDropdown(data: data, titleSize: titleSize)
                }
            }
            .font(AppTypography.s4_1)
            .padding(.horizontal, Decimal.d12)
            .padding(.vertical, Decimal.d16)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(.white)
            .cornerRadius(Decimal.d12)
            .overlay(
                RoundedRectangle(cornerRadius: Decimal.d12)
                    .stroke(AppColors.slate100)
            )
            .padding(.horizontal, Decimal.d20)
            .onTapGesture {
                withAnimation {
                    isExtended.toggle()
                }
            }
        }
    }
}

struct ExtendedAppDropdown: View {
    var data: [(key: String, value: String)]
    var titleSize: Font

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(data, id: \.key) { item in
                VStack(alignment: .leading) {
                    Text(item.key)
                        .font(titleSize)
                        .foregroundColor(AppColors.slate300)
                    Spacer().frame(height: Decimal.d4)
                    Text(item.value)
                        .font(AppTypography.p2)
                }
                .padding(.top, Decimal.d8)
            }
        }
    }
}

#Preview {
    AppDropdown(
        title: "Data Pasien",
        data: [
            (key: "Nama Pasien", value: "Alya Annisa Kirana"),
            (key: "NIK Pasien", value: "167012039484700"),
            (key: "Umur Pasien", value: "23 Tahun"),
            (key: "Jenis Kelamin", value: "Perempuan"),
            (key: "Nomor BPJS", value: "06L30077675")
        ],
        titleSize: AppTypography.s5
    )
}
