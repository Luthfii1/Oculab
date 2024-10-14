//
//  ExtendableCard.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 14/10/24.
//

import SwiftUI

struct ExtendableCard: View {
    var icon: String
    var title: String
    @State private var isExtended = true
    var data: [(key: String, value: String)]
    var titleSize: Font

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.purple500)
                Text(title)
                    .padding(.leading, Decimal.d8)
                Spacer()

                Image(systemName: isExtended ? "chevron.up" : "chevron.down")
            }

            if isExtended {
                ExtendedCard(data: data, titleSize: titleSize)
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

struct ExtendedCard: View {
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
    ExtendableCard(
        icon: "person.fill",
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
