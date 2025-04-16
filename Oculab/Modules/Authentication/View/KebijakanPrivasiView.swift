//
//  KebijakanPrivasiView.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 03/12/24.
//

import SwiftUI

struct KebijakanPrivasiView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Rectangle()
                        .hidden()

                    Text(
                        "Mohon untuk membaca seluruh kebijakan privasi yang terlampir dengan cermat dan seksama sebelum menggunakan setiap fitur dan/atau layanan yang tersedia dalam Oculab"
                    )
                    .font(AppTypography.p3)
                    .foregroundStyle(AppColors.slate900)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ketentuan Umum")
                            .font(AppTypography.s5)
                            .foregroundStyle(AppColors.slate900)

                        VStack(alignment: .leading, spacing: 0) {
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Negatif: Tidak ditemukan BTA minimal dalam 100 lapang pandang")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Scanty: 1-9 BTA dalam 100 lapang pandang")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text("Positif 1+: 10 – 99 BTA dlm 100 lapang pandang")
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text(
                                    "Positif 2+: 1 – 10 BTA setiap 1 lapang pandang, minimal terdapat di 50 lapang pandang"
                                )
                            }
                            HStack(alignment: .top) {
                                Text("•")
                                Text(
                                    "Positif 3+: ≥ 10 BTA setiap 1 lapang pandang, minimal terdapat di 20 lapang pandang"
                                )
                            }
                        }
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate900)
                        .padding(.leading, Decimal.d12)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Definisi")
                            .font(AppTypography.s5)
                            .foregroundStyle(AppColors.slate900)

                        Text(
                            "Setiap kata atau istilah berikut yang digunakan di dalam Kebijakan Privasi ini memiliki arti seperti berikut di bawah, kecuali jika kata atau istilah yang bersangkutan di dalam pemakaiannya dengan tegas menentukan lain:"
                        )
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate900)

                        VStack(alignment: .leading, spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(alignment: .top) {
                                    Text("a.")
                                    Text(
                                        "“OCULAB” adalah platform yang dipergunakan di wilayah Republik Indonesia untuk tujuan:"
                                    )
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .top) {
                                        Text("i.")
                                        Text(
                                            "Mencakup Data Sumber Daya Manusia Kesehatan baik tenaga medis, tenaga keteknisian medis, dan tenaga Kesehatan lainnya yang diverifikasi oleh Dinas Kesehatan Kabupaten/ Kota dan divalidasi oleh Dinas Kesehatan Provinsi."
                                        )
                                    }
                                    HStack(alignment: .top) {
                                        Text("ii.")
                                        Text("Penyelenggaraan informasi Sumber Daya Manusia Kesehatan;")
                                    }
                                    HStack(alignment: .top) {
                                        Text("iii.")
                                        Text("Sistem informasi Kesehatan bagi Sumber Daya Manusia Kesehatan; dan")
                                    }
                                    HStack(alignment: .top) {
                                        Text("iv.")
                                        Text(
                                            "upaya kesehatan lainnya yang bersifat promotif, preventif, kuratif, dan rehabilitatif serta tujuan-tujuan lainnya selama diizinkan berdasarkan ketentuan peraturan perundang-undangan yang berlaku."
                                        )
                                    }
                                }
                                .padding(.leading, Decimal.d24)
                            }

                            HStack(alignment: .top) {
                                Text("b.")
                                Text(
                                    "“Platform” adalah platform SATUSEHAT SDMK, sistem, dan/atau aplikasi layanan integrasi dan interoperabilitas data Sumber Daya Manusia Kesehatan yang dikelola dan diselenggarakan oleh Kementerian Kesehatan. Termasuk daftar Riwayat hidup, riwayat Pendidikan, riwayat pekerjaan dan kebutuhan data terkait lainnya."
                                )
                            }
                            HStack(alignment: .top) {
                                Text("c.")
                                Text(
                                    "“Platform” adalah platform SATUSEHAT SDMK, sistem, dan/atau aplikasi layanan integrasi dan interoperabilitas data Sumber Daya Manusia Kesehatan yang dikelola dan diselenggarakan oleh Kementerian Kesehatan. Termasuk daftar Riwayat hidup, riwayat Pendidikan, riwayat pekerjaan dan kebutuhan data terkait lainnya."
                                )
                            }
                            HStack(alignment: .top) {
                                Text("d.")
                                Text(
                                    "“Pengguna”, berarti setiap Sumber Daya Manusia Kesehatan yang menggunakan SATUSEHAT SDMK."
                                )
                            }
                            HStack(alignment: .top) {
                                Text("e.")
                                Text(
                                    "“Tenaga Kesehatan”, berarti setiap orang yang mengabdikan diri dalam bidang Kesehatan serta memiliki pengetahuan dan/ atau keterampilan melalui Pendidikan di bidang Kesehatan yang untuk jenis tertentu memerlukan kewenangan untuk melakukan Upaya Kesehatan."
                                )
                            }
                            HStack(alignment: .top) {
                                Text("f.")
                                Text(
                                    "“Fasilitas Pelayanan Kesehatan”, suatu alat dan/ atau tempat yang digunakan untuk menyelenggarakan Upaya pelayanan Kesehatan, baik promotif, preventif, kuratif maupun rehabilitatif yang dilakukan oleh pemerintah, pemerintah daerah, dan/ atau Masyarakat."
                                )
                            }
                            HStack(alignment: .top) {
                                Text("g.")
                                Text(
                                    "“Data Pribadi” atau “Data Kesehatan” berarti setiap dan seluruh data pribadi dan data kondisi kesehatan Pengguna, termasuk namun tidak terbatas pada nama, nomor identifikasi, lokasi Pengguna, kontak Pengguna, serta dokumen dan data lainnya sebagaimana diminta pada formulir pendaftaran akun atau informasi kesehatan termasuk setiap dan seluruh data kesehatan Pengguna seperti rekam medis, jenis kelamin, kondisi kesehatan, pengobatan, alergi, vaksinasi, imunisasi, tindakan, riwayat medis, resep, laporan, anjuran dan informasi medis atau catatan kondisi kesehatan lainnya."
                                )
                            }
                            HStack(alignment: .top) {
                                Text("h.")
                                Text(
                                    "“Pengendali Data” adalah setiap orang, badan publik, dan/atau organisasi internasional yang bertindak sendiri-sendiri atau bersama-sama dalam menentukan tujuan dan melakukan kendali pemrosesan Data Pribadi atau Data Kesehatan atau informasi lainnya. “Prosesor Data” adalah setiap orang, badan publik, dan/atau organisasi internasional yang bertindak sendiri-sendiri atau bersama-sama dalam melakukan pemrosesan Data Pribadi atau Data Kesehatan atau informasi lainnya yang ditunjuk Pengendali Data."
                                )
                            }
                        }
                        .font(AppTypography.p3)
                        .foregroundStyle(AppColors.slate900)
                        .padding(.leading, Decimal.d12)
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Kebijakan Privasi Oculab")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Router.shared.navigateBack()
                    }) {
                        HStack {
                            Image("back")
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
}

#Preview {
    KebijakanPrivasiView()
}
