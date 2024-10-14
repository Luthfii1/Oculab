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

    var dataTitle = ["NIK", "Umur", "Jenis Kelamin", "No. BPJS"]
    var preparatTitle = ["ID Pemeriksaan", "Diambil di", "Petugas"]

    var body: some View {
//        Text("test").foregroundColor(AppColors.purple300)
        PDFKitView(pdfData: PDFDocument(data: generatePDF())!)
    }

    // Generating PDF
    @MainActor
    private func generatePDF() -> Data {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842)) // A4 paper size

        let data = pdfRenderer.pdfData { context in

            context.beginPage()

            let regularTextAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)]
            let boldTextAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 14)]

            drawHeader(regularTextAttributes: regularTextAttributes)
            drawPatientInfo(boldTextAttributes: boldTextAttributes)
            drawDataLabels()

            drawPreparatLabels()
        }

        return data
    }

    private func drawHeader(regularTextAttributes: [NSAttributedString.Key: Any]) {
        // Logo
        let logo = UIImage(named: "logo")
        logo?.draw(at: CGPoint(x: 32, y: 32))

        // Description, phone, and email
        kopData.desc.draw(at: CGPoint(x: 32, y: 72), withAttributes: regularTextAttributes)
        kopData.notelp.draw(at: CGPoint(x: 427, y: 54), withAttributes: regularTextAttributes)
        kopData.email.draw(at: CGPoint(x: 427, y: 70), withAttributes: regularTextAttributes)

        // Draw line
        let line = UIImage(named: "line")
        line?.draw(at: CGPoint(x: 0, y: 97))
    }

    private func drawDataLabels() {
        let labelAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10)]
        var currentY = 176
        for title in dataTitle {
            let attributedString = NSAttributedString(string: title, attributes: labelAttributes)
            attributedString.draw(at: CGPoint(x: 33, y: currentY))
            currentY += 17
        }
    }

    private func drawPreparatLabels() {
        let labelAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10)]
        var currentY = 176
        for title in preparatTitle {
            let attributedString = NSAttributedString(string: title, attributes: labelAttributes)
            attributedString.draw(at: CGPoint(x: 246, y: currentY))
            currentY += 17
        }
    }

    // Draw Patient Info
    private func drawPatientInfo(boldTextAttributes: [NSAttributedString.Key: Any]) {
        patientData.name.draw(at: CGPoint(x: 33, y: 149), withAttributes: boldTextAttributes)
        patientData.nik.draw(at: CGPoint(x: 128, y: 176))

        let age = "\(patientData.age) Tahun"
        age.draw(at: CGPoint(x: 128, y: 193))

        patientData.sex.draw(at: CGPoint(x: 128, y: 210))
        patientData.bpjs.draw(at: CGPoint(x: 128, y: 227))
    }

    // Saving PDF
    @MainActor func savePDF() {
        let fileName = "GeneratedPDF.pdf"
        let pdfData = generatePDF()

        if let documentDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let documentURL = documentDirectories.appendingPathComponent(fileName)
            do {
                try pdfData.write(to: documentURL)
                print("PDF saved at: \(documentURL)")
            } catch {
                print("Error saving PDF: \(error.localizedDescription)")
            }
        }
    }
}

struct Kop {
    var desc = "Pathologist Expert Companion for Accessible TB Care"
    var notelp = "+62 838 0000 0000"
    var email = "ai.oculab@gmail.com"
}

struct TempPatientData {
    var name = "Alya Annisa Kirana"
    var nik = "167012039484700"
    var age = 23
    var sex = "Perempuan"
    var bpjs = "-"
}

// PDF Viewer
struct PDFKitView: UIViewRepresentable {
    let pdfDocument: PDFDocument

    init(pdfData pdfDoc: PDFDocument) {
        self.pdfDocument = pdfDoc
    }

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = pdfDocument
        pdfView.autoScales = true
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = pdfDocument
    }
}

#Preview {
    PDFPageView()
}
