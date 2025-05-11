//
//  BottomActionSheet.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import SwiftUI

struct BottomActionSheet: View {
    var userName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(userName)
                .font(AppTypography.s4)
                .foregroundColor(AppColors.slate900)
                .padding(.top, 32)
                .padding(.bottom, 4)

            Button {
                // Ubah logic here
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Ubah Detail Akun")
                        .font(AppTypography.p3)
                }
                .foregroundColor(AppColors.slate900)
            }
            .padding(.vertical, 4)

            Button {
                // Hapus logic here
            } label: {
                HStack {
                    Image(systemName: "trash")
                    Text("Hapus Akun")
                        .font(AppTypography.p3)
                }
                .foregroundColor(AppColors.red500)
            }
            .padding(.vertical, 4)


            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .presentationDetents([.fraction(0.2)])
        .presentationDragIndicator(.visible)
    }
}


#Preview {
    BottomActionSheet(userName: "Icune")
}
