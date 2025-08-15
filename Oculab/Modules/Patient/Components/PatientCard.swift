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
        VStack(alignment: .leading, spacing: AppConstants.PatientUI.cardSpacing) {
            HStack {
                // Patient icon
                Image(systemName: AppIcon.personFill)
                    .foregroundColor(AppColors.orange500)
                    .frame(width: AppConstants.PatientUI.cardIconSize, height: AppConstants.PatientUI.cardIconSize)
                    .background(Color.orange.opacity(AppConstants.PatientUI.cardIconOpacity))
                    .clipShape(Rectangle())
                    .cornerRadius(AppConstants.PatientUI.cardCornerRadius)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppConstants.PatientUI.cardContentSpacing) {
                Text(name)
                    .font(AppTypography.s4_1)
                    .foregroundColor(AppColors.slate900)
                    .lineLimit(2)

                Text(AppData.makeSentence([AppTextPatientCompCard.birthDatePrefix, birthDate]))
                    .font(AppTypography.p4)
                    .foregroundColor(AppColors.slate900)
            }
            
        }
        .padding(AppConstants.PatientUI.cardPadding)
        .frame(height: AppConstants.PatientUI.cardHeight)
        .background(AppColors.slate0)
        .cornerRadius(AppConstants.PatientUI.cardBorderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.PatientUI.cardBorderRadius)
                .stroke(AppColors.slate100, lineWidth: AppConstants.PatientUI.cardStrokeWidth)
        )
    }
}

#Preview {
    PatientCard(name: "Risa", birthDate: "2003")
}
