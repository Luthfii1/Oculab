//
//  ContactListView.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import SwiftUI

struct ContactListView: View {
    var onTapMore: (String) -> Void

    let groupedContacts: [String: [String]] = [
        "A": ["Adinda Putri Maharani", "Ahmad Fahri Rahman"],
        "B": ["Brigitta Maharani Wijaya", "Budianto Santoso", "Bulan Purnama Sari"]
    ]

    var sortedKeys: [String] {
        groupedContacts.keys.sorted()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(sortedKeys, id: \.self) { key in
                VStack(alignment: .leading, spacing: 8) {
                    Text(key)
                        .font(AppTypography.s4_1)
                        .foregroundColor(AppColors.slate400)
                        .padding(.horizontal)

                    VStack(spacing: 0) {
                        ForEach(groupedContacts[key]!, id: \.self) { name in
                            HStack {
                                Text(name)
                                    .font(AppTypography.p2)
                                    .foregroundColor(AppColors.slate900)

                                Spacer()

                                Button {
                                    onTapMore(name)
                                } label: {
                                    Image(systemName: "ellipsis")
                                        .foregroundColor(AppColors.slate400)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal)
                            
                            if name != groupedContacts[key]!.last {
                                Divider()
                            }
                        }
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
        }
    }
}


//#Preview {
////    ContactListView(onTapMore: .constant({}))
//}
