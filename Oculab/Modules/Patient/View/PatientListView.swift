//
//  PatientListView.swift
//  Oculab
//
//  Created by Risa on 30/05/25.
//

import SwiftUI

struct PatientListView: View {
    @StateObject private var presenter = AccountPresenter()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("Riwayat")
                        .font(AppTypography.h1)
                        .foregroundColor(AppColors.slate900)
                }
                
                AppSearchBar(
                    searchText: $presenter.searchText,
                    placeholder: "Cari nama pasien",
                    onSearch: {
                        presenter.searchAccounts(query: presenter.searchText)
                    }
                )

                AppButton(
                    title: "Tambah Pasien Baru",
                    leftIcon: "plus",
                    colorType: .secondary,
                    action: {
                        presenter.navigateTo(.newAccount)
                    }
                )
                
                if !presenter.searchText.isEmpty && presenter.displayedSortedGroupedAccounts.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("Tidak ada hasil untuk \"\(presenter.searchText)\"")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            presenter.clearSearch()
                        }) {
                            Text("Hapus Pencarian")
                                .font(.system(size: 14))
                                .foregroundColor(.purple)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 40)
                } else {
                    if presenter.isUserLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 40)
                    } else {
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ], spacing: 16) {
                                PatientCard(name: "Rasyad Caesaradhi", birthDate: "19/12/00")
                                PatientCard(name: "Indri Klarissa", birthDate: "19/12/00")
                                PatientCard(name: "Bunga Prameswari", birthDate: "19/12/00")
                                PatientCard(name: "Alifiyah Ariandri", birthDate: "19/12/00")
                                PatientCard(name: "Misbachul Munir", birthDate: "19/12/00")
                                PatientCard(name: "Annisa Az Zahra", birthDate: "19/12/00")
                                PatientCard(name: "Rasyad Caesaradhi", birthDate: "19/12/00")
                                PatientCard(name: "Indri Klarissa", birthDate: "19/12/00")
                                PatientCard(name: "Bunga Prameswari", birthDate: "19/12/00")
                                PatientCard(name: "Alifiyah Ariandri", birthDate: "19/12/00")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, Decimal.d20)
            .background(Color(.systemBackground))
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    PatientListView()
}
