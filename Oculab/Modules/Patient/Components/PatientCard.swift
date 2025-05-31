//
//  PatientCard.swift
//  Oculab
//
//  Created by Risa on 30/05/25.
//

import SwiftUI

 struct PatientCard: View {
    let name: String
    let birthDate: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Patient icon
                Image(systemName: "person.fill")
                    .foregroundColor(AppColors.orange500)
                    .frame(width: 32, height: 32)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Rectangle())
                    .cornerRadius(8)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(AppTypography.s4_1)
                    .foregroundColor(AppColors.slate900)
                    .lineLimit(2)
                
                Text("Tanggal Lahir: \(birthDate)")
                    .font(AppTypography.p4)
                    .foregroundColor(AppColors.slate900)
            }
            
        }
        .padding(12)
        .frame(height: 100)
        .background(AppColors.slate0)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.slate100, lineWidth: 1)
        )
    }
}

#Preview {
    PatientCard(name: "Risa", birthDate: "2003")
}
