//
//  FinishedExaminationCard.swift
//  Oculab
//
//  Created by Bunga Prameswari on 23/05/25.
//

import SwiftUI

struct FinishedExaminationCard: View {
    var slideId: String
    var result: String
    var patientName: String
    var patientDOB: String
    var dpjpName: String
    
    private var isPositive: Bool {
        result.lowercased().contains("positif") || result.lowercased().contains("positive")
    }
    
    private var resultBackgroundColor: Color {
        isPositive ? AppColors.red50 : AppColors.blue50
    }
    
    private var resultTextColor: Color {
        isPositive ? AppColors.red600 : AppColors.blue500
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Decimal.d8) {
            // Slide ID with icon and result tag
            HStack {
                HStack(spacing: Decimal.d8) {
                    Image(systemName: "doc.text.fill")
                        .padding(Decimal.d8)
                        .background(AppColors.purple50)
                        .foregroundStyle(AppColors.purple500)
                        .cornerRadius(Decimal.d8)
                    Text(slideId)
                        .font(AppTypography.s4_1)
                        .foregroundStyle(AppColors.slate900)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Text(result)
                    .font(AppTypography.s6)
                    .foregroundStyle(resultTextColor)
                    .padding(.horizontal, Decimal.d12)
                    .padding(.vertical, Decimal.d4)
                    .background(resultBackgroundColor)
                    .cornerRadius(Decimal.d6)
            }
            
            Text("Pasien")
                .font(AppTypography.s6)
                .foregroundStyle(AppColors.slate300)
            Text("\(patientName) (\(patientDOB))")
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate900)
            
            Text("DPJP")
                .font(AppTypography.s6)
                .foregroundStyle(AppColors.slate300)
            Text(dpjpName)
                .font(AppTypography.p3)
                .foregroundStyle(AppColors.slate900)
        }
        .padding(Decimal.d12)
        .cornerRadius(Decimal.d12)
        .overlay(
            RoundedRectangle(cornerRadius: Decimal.d12)
                .stroke(AppColors.slate100)
        )
    }
}

#Preview {
    VStack(spacing: Decimal.d16) {
        FinishedExaminationCard(
            slideId: "24/11/1/0123A",
            result: "Positif 3+",
            patientName: "Indri Klarissa Ramadhanti",
            patientDOB: "19/12/00",
            dpjpName: "dr. Siti Nurhayati Rahmaniyah, Sp.P"
        )
        
        FinishedExaminationCard(
            slideId: "24/11/1/0123A",
            result: "Negatif",
            patientName: "Indri Klarissa Ramadhanti",
            patientDOB: "19/12/00",
            dpjpName: "dr. Siti Nurhayati Rahmaniyah, Sp.P"
        )
    }
    .padding()
}
