//
//  BoxesGroupComponent.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 20/05/25.
//

import SwiftUI

struct BoxesGroupComponentView: View {
    // MARK: - Properties

    var presenter: FOVDetailPresenter
    var width: Double
    var height: Double
    var zoomScale: CGFloat
    let interactionMode: InteractionMode

    // **PERBAIKAN KUNCI 1**: Kembalikan ke @State untuk memungkinkan update UI instan (optimistic).
    @State private var localBoxes: [BoxModel]

    // Terima array asli untuk perbandingan
    private let sourceBoxes: [BoxModel]

    @Binding var selectedBox: BoxModel?
    var onBoxSelected: ((BoxModel) -> Void)?

    init(
        presenter: FOVDetailPresenter,
        width: Double,
        height: Double,
        zoomScale: CGFloat,
        boxes: [BoxModel],
        interactionMode: InteractionMode,
        selectedBox: Binding<BoxModel?>,
        onBoxSelected: ((BoxModel) -> Void)? = nil
    ) {
        self.presenter = presenter
        self.width = width
        self.height = height
        self.zoomScale = zoomScale

        // Simpan data asli dari presenter
        self.sourceBoxes = boxes
        // Inisialisasi State dengan data awal
        self._localBoxes = State(initialValue: boxes)

        self.interactionMode = interactionMode
        self._selectedBox = selectedBox
        self.onBoxSelected = onBoxSelected
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Gunakan salinan lokal untuk ForEach agar UI bisa update instan
            ForEach(localBoxes) { box in
                BoxComponentView(
                    box: box,
                    selectedBox: selectedBox,
                    zoomScale: zoomScale
                )
                .position(
                    x: box.x * zoomScale,
                    y: box.y * zoomScale
                )
                .onTapGesture {
                    selectedBox = box
                    onBoxSelected?(box)
                }
                .disabled(interactionMode != .verify)
            }
        }
        .frame(width: width * zoomScale, height: height * zoomScale)
        // **PERBAIKAN KUNCI 2**: Tambahkan .onChange untuk sinkronisasi.
        // Jika data dari presenter berubah (misalnya setelah menambah kotak baru),
        // perbarui salinan lokal kita.
        .onChange(of: sourceBoxes) { newSourceBoxes in
            self.localBoxes = newSourceBoxes
        }
        .sheet(item: $selectedBox) { selected in
            TrayView(
                selectedBox: $selectedBox,
                boxes: localBoxes, // Gunakan data lokal
                onVerify: {
                    updateBoxStatus(id: selected.id, to: .verified)
                },
                onFlag: {
                    updateBoxStatus(id: selected.id, to: .flagged)
                },
                onReject: {
                    updateBoxStatus(id: selected.id, to: .trashed)
                }
            )
        }
    }

    private func updateBoxStatus(id: String, to status: BoxStatus) {
        // **PERBAIKAN KUNCI 3**: Lakukan "Optimistic Update".
        // 1. Ubah data di salinan lokal SECARA LANGSUNG untuk UI instan.
        if let index = localBoxes.firstIndex(where: { $0.id == id }) {
            localBoxes[index].status = status
        }

        // 2. Kirim permintaan ke server di latar belakang.
        Task {
            await presenter.updateStatus(boxId: id, newStatus: status)
            // Jika gagal, presenter yang seharusnya bertanggung jawab
            // untuk memuat ulang data yang benar.
        }
    }
}

// ... Sisa kode (BoxStatus, BoxModel) tidak perlu diubah ...
enum BoxStatus: String, Decodable {
    case none = "UNVERIFIED"
    case verified = "VERIFIED"
    case trashed = "DELETED"
    case flagged = "FLAGGED"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let statusString = try container.decode(String.self)

        switch statusString.uppercased() {
        case "VERIFIED":
            self = .verified
        case "FLAGGED":
            self = .flagged
        case "DELETED":
            self = .trashed
        case "UNVERIFIED":
            self = .none
        default:
            self = .none
        }
    }
}

struct BoxModel: Identifiable, Equatable, Decodable {
    let id: String
    var width: Double
    var height: Double
    var x: Double
    var y: Double
    var status: BoxStatus

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case width
        case height
        case x = "xCoordinate"
        case y = "yCoordinate"
        case status
    }
}
