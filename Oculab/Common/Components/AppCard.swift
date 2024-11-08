//
//  AppCard.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 16/10/24.
//

import SwiftUI

struct AppCard<Content: View>: View {
    var icon: String
    var title: String
    var spacing: CGFloat
    var isBorderDisabled: Bool
    var isEnablingEdit: Bool

    var content: Content

    init(
        icon: String,
        title: String,
        spacing: CGFloat,
        isBorderDisabled: Bool = false,
        isEnablingEdit: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.icon = icon
        self.title = title
        self.spacing = spacing
        self.isBorderDisabled = isBorderDisabled
        self.content = content()
        self.isEnablingEdit = isEnablingEdit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            // Icon and Title
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppColors.purple500)
                Text(title)
                    .padding(.leading, Decimal.d8)
                    .font(AppTypography.s4_1)
                if isEnablingEdit {
                    Spacer()
                    HStack(spacing: Decimal.d12) {
                        Image(systemName: "square.and.pencil")
                        Text("Edit").font(AppTypography.s6)
                    }
                    .foregroundStyle(AppColors.purple500)
                }
            }

            // Custom Content
            content
        }
        .padding(.horizontal, isBorderDisabled ? .zero : Decimal.d16)
        .padding(.vertical, Decimal.d16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .cornerRadius(Decimal.d12)
        .overlay(
            RoundedRectangle(cornerRadius: Decimal.d12)
                .stroke(isBorderDisabled ? .clear : AppColors.slate100)
        )
    }
}

#Preview {
    AppCard(icon: "person.fill", title: "Profile", spacing: Decimal.d16) {
        VStack(alignment: .leading) {
            Text("Name: Alya Annisa Kirana")
            Text("Age: 23 Years")
            Text("Gender: Female")
        }
    }

    AppCard(icon: "person.fill", title: "Profile", spacing: Decimal.d16, isBorderDisabled: true) {
        VStack(alignment: .leading) {
            Text("Name: Alya Annisa Kirana")
            Text("Age: 23 Years")
            Text("Gender: Female")
        }
    }
}
