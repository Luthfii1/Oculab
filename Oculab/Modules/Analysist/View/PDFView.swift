//
//  PDFView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 14/10/24.
//

import PDFKit
import SwiftUI

struct PDFPageView: View {
    var kopData = Kop()
    var patientData = TempPatientData()
    var preparatData = TempPreparatData()
    var hasilData = TempHasilData()

    var body: some View {
        PDFKitView(pdfDocument: PDFDocument(data: generatePDF())!)
    }

    @MainActor
    private func generatePDF() -> Data {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842)) // A4 size

        return pdfRenderer.pdfData { context in
            context.beginPage()
            let context = context.cgContext

            // Define common attributes
            let regularText = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)]
            let boldText = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10)]
            let boldLargeText = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)]

            // Draw PDF content
            drawHeader(regularText)
            drawInfoSection(
                title: patientData.name,
                labels: ["NIK", "Umur", "Jenis Kelamin", "No. BPJS"],
                values: [patientData.nik, "\(patientData.age) Tahun", patientData.sex, patientData.bpjs],
                xTitle: 33,
                yStart: 149,
                boldText,
                regularText,
                boldLargeText
            )
            drawInfoSection(
                title: "Informasi Sediaan",
                labels: ["ID Pemeriksaan", "Diambil di", "Petugas"],
                values: [preparatData.id, preparatData.place, preparatData.laborant],
                xTitle: 246,
                yStart: 149,
                boldText,
                regularText,
                boldLargeText
            )
            drawLines(context)
            drawHasilPemeriksaan(regularText)

            drawInterpretasi(
                title: "Interpretasi Mikroskopis",
                description: "{Pelaporan BTA pada Sediaan dengan Pewarnaan Z-N berdasarkan Rekomendasi IUALTD/WHO. Hasil positif pada sediaan BTA (Bakteri Tahan Asam) menjadi indikasi awal adanya infeksi mikobakteri dan potensi penyakit TB. Positifnya hasil sediaan dan tingkatan BTA mencerminkan beban bakteri relatif dan terkait dengan gejala penyakit. Terapi pasien untuk TB dapat dimulai berdasarkan hasil sediaan dan presentasi klinis, dengan perubahan status BTA yang penting untuk memantau respons terapi}",
                yContent: 388,
                boldText,
                regularText
            )
            drawInterpretasi(
                title: "Catatan Petugas",
                description: "{Ada kemungkinan infeksi penyakit tuberculosis}",
                yContent: 640,
                boldText,
                regularText
            )
            drawLines(context)
            drawHasilPemeriksaan(regularText)
            drawImage()
        }
    }

    // Draw header section with logo, description, phone, email
    private func drawHeader(_ regularText: [NSAttributedString.Key: Any]) {
        UIImage(named: "logo")?.draw(at: CGPoint(x: 32, y: 32))
        NSAttributedString(string: kopData.desc, attributes: regularText).draw(at: CGPoint(x: 32, y: 72))
        NSAttributedString(string: kopData.notelp, attributes: regularText).draw(at: CGPoint(x: 427, y: 54))
        NSAttributedString(string: kopData.email, attributes: regularText).draw(at: CGPoint(x: 427, y: 70))
        UIImage(named: "line")?.draw(at: CGPoint(x: 0, y: 97))
    }

    private func drawInterpretasi(
        title: String,
        description: String,
        yContent: CGFloat,
        _ boldText: [NSAttributedString.Key: Any],
        _ regularText: [NSAttributedString.Key: Any]
    ) {
        let xContent: CGFloat = 33
        let yTitle: CGFloat = yContent
        let yDesc: CGFloat = yContent + 17
        let textWidth: CGFloat = 530
        let textHeight: CGFloat = 200

        NSAttributedString(string: title, attributes: boldText).draw(at: CGPoint(x: xContent, y: yTitle))

        let descriptionRect = CGRect(x: xContent, y: yDesc, width: textWidth, height: textHeight)
        NSAttributedString(string: description, attributes: regularText).draw(in: descriptionRect)
    }

    private func drawImage() {
        guard let image = UIImage(named: "GradeDescription") else { return }

        let imageRect = CGRect(x: 33, y: 475, width: 305, height: 160)
        image.draw(in: imageRect)
    }

    private func drawInfoSection(
        title: String,
        labels: [String],
        values: [String],
        xTitle: CGFloat,
        yStart: CGFloat,
        _ boldText: [NSAttributedString.Key: Any],
        _ regularText: [NSAttributedString.Key: Any],
        _ boldLargeText: [NSAttributedString.Key: Any]
    ) {
        NSAttributedString(string: title, attributes: boldLargeText).draw(at: CGPoint(x: xTitle, y: yStart))

        let xLabel = xTitle
        let xValue: CGFloat = xTitle + 87 // Fixed offset for values
        let yOffset: CGFloat = 17

        for (index, label) in labels.enumerated() {
            let yPosition = yStart + 27 + (CGFloat(index) * yOffset)
            NSAttributedString(string: label, attributes: boldText).draw(at: CGPoint(x: xLabel, y: yPosition))
            NSAttributedString(string: values[index], attributes: regularText).draw(at: CGPoint(
                x: xValue,
                y: yPosition
            ))
        }
    }

    // Draw the result table for bacteriological examination
    private func drawHasilPemeriksaan(_ regularText: [NSAttributedString.Key: Any]) {
        let boldAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 12)]
        let labels = ["Tujuan Pemeriksaan", "Jenis Uji", "ID Sediaan", "Hasil Pemeriksaan"]
        let values = [hasilData.tujuan, hasilData.jenisUji, hasilData.idSediaan, hasilData.hasil]

        for (index, label) in labels.enumerated() {
            let xPosition: CGFloat = [33, 186, 287, 412][index]
            NSAttributedString(string: label, attributes: boldAttributes).draw(at: CGPoint(x: xPosition, y: 317))
            NSAttributedString(string: values[index], attributes: regularText).draw(at: CGPoint(x: xPosition, y: 353))
        }

        NSAttributedString(string: "HASIL PEMERIKSAAN BAKTERIOLOGIS", attributes: boldAttributes)
            .draw(at: CGPoint(x: 166, y: 274))
    }

    // Draw lines for the table and other sections
    private func drawLines(_ context: CGContext) {
        context.setStrokeColor(UIColor.lightGray.cgColor)
        context.setLineWidth(1.0)

        context.move(to: CGPoint(x: 231, y: 152))
        context.addLine(to: CGPoint(x: 231, y: 252))

        // Horizontal lines for table
        for yOffset in [259, 306, 343] {
            context.move(to: CGPoint(x: 33, y: CGFloat(yOffset)))
            context.addLine(to: CGPoint(x: 563, y: CGFloat(yOffset)))
        }
        context.strokePath()
    }

    // Save PDF to file system
    @MainActor
    func savePDF() {
        let pdfData = generatePDF()
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let documentURL = documentDirectory.appendingPathComponent("GeneratedPDF.pdf")
            do {
                try pdfData.write(to: documentURL)
                print("PDF saved at: \(documentURL)")
            } catch {
                print("Error saving PDF: \(error.localizedDescription)")
            }
        }
    }
}

// Placeholder data structs
struct Kop {
    var desc = "Pathologist Expert Companion for Accessible TB Care"
    var notelp = "+62 838 0000 0000"
    var email = "ai.oculab@gmail.com"
}

struct TempPatientData {
    var name = "{Alya Annisa Kirana}"
    var nik = "{167012039484700}"
    var age = 23
    var sex = "{Perempuan}"
    var bpjs = "-"
}

struct TempPreparatData {
    var id = "{OCU-40}"
    var place = "{Puskesmas Rawa Buntu}"
    var laborant = "{Bunga Prameswari, S.Tr.Kes}"
}

struct TempHasilData {
    var tujuan = "{Skrining}"
    var jenisUji = "{Sewaktu}"
    var hasil = "{Positif (3+)}"
    var idSediaan = "{24/11/1/0123A}"
}

// PDF Viewer
struct PDFKitView: UIViewRepresentable {
    let pdfDocument: PDFDocument

    init(pdfDocument: PDFDocument) {
        self.pdfDocument = pdfDocument
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {}
}

// Preview the PDF page view
#Preview {
    PDFPageView()
}
