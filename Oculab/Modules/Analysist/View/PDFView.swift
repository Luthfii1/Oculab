//
//  PDFView.swift
//  Oculab
//
//  Created by Alifiyah Ariandri on 14/10/24.
//

import PDFKit
import SwiftUI

struct PDFPageView: View {
    @StateObject private var presenter = PDFPresenter()
    @Environment(\.dismiss) private var dismiss  
    
    var body: some View {
        NavigationView {
            PDFKitView(pdfDocument: PDFDocument(data: generatePDF())!)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
//                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                    .foregroundColor(.black)
                                
                                Text("Kembali")
                                    .foregroundStyle(.black)
                            }
                        }
                    }
                    
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            sharePDF()
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.black)
                        }
                    }
                }
        }
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
                title: presenter.data.patient.name,
                labels: ["NIK", "Umur", "Jenis Kelamin", "No. BPJS"],
                values: [
                    presenter.data.patient.nik,
                    "\(presenter.data.patient.age) Tahun",
                    presenter.data.patient.sex,
                    presenter.data.patient.bpjs
                ],
                xTitle: 33,
                yStart: 149,
                boldText,
                regularText,
                boldLargeText
            )
            drawInfoSection(
                title: "Informasi Sediaan",
                labels: ["ID Pemeriksaan", "Diambil di", "Petugas"],
                values: [
                    presenter.data.preparat.id,
                    presenter.data.preparat.place,
                    presenter.data.preparat.laborant
                ],
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
                description: presenter.data.hasil.descInterpretasi,
                yContent: 388,
                boldText,
                regularText
            )
            drawInterpretasi(
                title: "Catatan Petugas",
                description: presenter.data.hasil.descNotesPetugas,
                yContent: 640,
                boldText,
                regularText
            )
            drawLines(context)
            drawHasilPemeriksaan(regularText)
            drawIUATLDStandard()
            drawSignatures(boldText, regularText)
        }
    }

    // Draw header section with logo, description, phone, email
    private func drawHeader(_ regularText: [NSAttributedString.Key: Any]) {
        UIImage(named: "logo")?.draw(at: CGPoint(x: 32, y: 32))
        NSAttributedString(string: presenter.data.kopSurat.desc, attributes: regularText).draw(at: CGPoint(x: 32, y: 72))
        
        // Phone number with icon
        let phoneIcon = UIImage(named: "phoneIcon")?.resizeImage(targetSize: CGSize(width: 12, height: 12))
        let phoneText = NSAttributedString(string: presenter.data.kopSurat.notelp, attributes: regularText)
        let phoneTextSize = phoneText.size()
        let phoneIconSize = phoneIcon?.size ?? .zero
        let phoneX = 563 - phoneTextSize.width - phoneIconSize.width - 4 // 4 is padding between text and icon
        phoneText.draw(at: CGPoint(x: phoneX, y: 54))
        phoneIcon?.draw(at: CGPoint(x: phoneX + phoneTextSize.width + 4, y: 54))
        
        // Email with icon
        let emailIcon = UIImage(named: "envelopeIcon")?.resizeImage(targetSize: CGSize(width: 12, height: 12))
        let emailText = NSAttributedString(string: presenter.data.kopSurat.email, attributes: regularText)
        let emailTextSize = emailText.size()
        let emailIconSize = emailIcon?.size ?? .zero
        let emailX = 563 - emailTextSize.width - emailIconSize.width - 4
        emailText.draw(at: CGPoint(x: emailX, y: 70))
        emailIcon?.draw(at: CGPoint(x: emailX + emailTextSize.width + 4, y: 70))
        
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

    private struct TableRow {
        let left: String
        let right: String
    }
    
    private func drawIUATLDStandard() {
        let boldAttributes = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10)]
        let regularAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 8)]
        
        // Table dimensions
        let startX: CGFloat = 33
        let startY: CGFloat = 475
        let tableWidth: CGFloat = 500
        let rowHeight: CGFloat = 25
        let headerHeight: CGFloat = 25
        let leftColumnWidth: CGFloat = tableWidth / 5
        let rightColumnWidth: CGFloat = (tableWidth * 4) / 5
        let rightColumnPadding: CGFloat = 10
        let leftColumnPadding: CGFloat = 10  // Added padding for left column
        let verticalPadding: CGFloat = 5
        
        // Draw headers
        let leftHeader = NSAttributedString(string: "Pelaporan", attributes: boldAttributes)
        let rightHeader = NSAttributedString(string: "Hasil Pengamatan", attributes: boldAttributes)
        
        // Position headers
        let leftHeaderX = startX + leftColumnPadding
        let rightHeaderX = startX + leftColumnWidth + rightColumnPadding
        
        // Draw headers with vertical padding
        leftHeader.draw(at: CGPoint(x: leftHeaderX, y: startY + verticalPadding))
        rightHeader.draw(at: CGPoint(x: rightHeaderX, y: startY + verticalPadding))
        
        // Table data
        let rows: [TableRow] = [
            TableRow(left: "Negatif", right: "Tidak ditemukan BTA dalam 100 lapang pandang"),
            TableRow(left: "Scanty", right: "Ditemukan 1-9 BTA dalam 100 lapang pandang"),
            TableRow(left: "Positif (1+)", right: "Ditemukan 10-99 BTA dalam 100 lapang pandang"),
            TableRow(left: "Positif (2+)", right: "Ditemukan 1-9 BTA dalam setiap lapang pandang, minimal dalam 50 lapang pandang"),
            TableRow(left: "Positif (3+)", right: "Ditemukan ≥10 BTA dalam setiap lapang pandang, minimal dalam 20 lapang pandang")
        ]
        
        // Draw content
        for (index, row) in rows.enumerated() {
            let yPosition = startY + headerHeight + (CGFloat(index) * rowHeight)
            
            // Create attributed strings for left and right text
            let leftText = NSAttributedString(string: row.left, attributes: regularAttributes)
            let rightText = NSAttributedString(string: row.right, attributes: regularAttributes)
            
            // Calculate x positions for left-aligned text
            let leftTextX = startX + leftColumnPadding
            let rightTextX = startX + leftColumnWidth + rightColumnPadding
            
            // Draw left-aligned text with vertical padding
            leftText.draw(at: CGPoint(x: leftTextX, y: yPosition + verticalPadding))
            
            // Draw right text with wrapping and vertical padding
            let rightTextRect = CGRect(
                x: rightTextX,
                y: yPosition + verticalPadding,
                width: rightColumnWidth - rightColumnPadding - 20,
                height: rowHeight - (verticalPadding * 2)
            )
            rightText.draw(in: rightTextRect)
        }
        
        // Draw table lines
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.lightGray.cgColor)
            context.setLineWidth(1.0)
            
            // Draw horizontal lines
            for i in 0...6 {
                let y = startY + (CGFloat(i) * rowHeight)
                context.move(to: CGPoint(x: startX, y: y))
                context.addLine(to: CGPoint(x: startX + tableWidth, y: y))
            }
            
            // Draw vertical lines
            let totalHeight = headerHeight + (5 * rowHeight)
            
            // Left line
            context.move(to: CGPoint(x: startX, y: startY))
            context.addLine(to: CGPoint(x: startX, y: startY + totalHeight))
            
            // Middle line
            context.move(to: CGPoint(x: startX + leftColumnWidth, y: startY))
            context.addLine(to: CGPoint(x: startX + leftColumnWidth, y: startY + totalHeight))
            
            // Right line
            context.move(to: CGPoint(x: startX + tableWidth, y: startY))
            context.addLine(to: CGPoint(x: startX + tableWidth, y: startY + totalHeight))
            
            context.strokePath()
        }
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
        let boldRedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.red
        ]
        let labels = ["Tujuan Pemeriksaan", "Jenis Uji", "ID Sediaan", "Hasil Pemeriksaan"]
        let values = [
            presenter.data.hasil.tujuan,
            presenter.data.hasil.jenisUji,
            presenter.data.hasil.idSediaan,
            presenter.data.hasil.hasil
        ]

        for (index, label) in labels.enumerated() {
            let xPosition: CGFloat = [33, 186, 287, 412][index]
            NSAttributedString(string: label, attributes: boldAttributes).draw(at: CGPoint(x: xPosition, y: 317))
            // Use bold red attributes for the result value (index 3)
            let attributes = index == 3 ? boldRedAttributes : regularText
            NSAttributedString(string: values[index], attributes: attributes).draw(at: CGPoint(x: xPosition, y: 353))
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

    private func drawSignatures(_ boldText: [NSAttributedString.Key: Any], _ regularText: [NSAttributedString.Key: Any]) {
        let startY: CGFloat = 700
        let signatureSize = CGSize(width: 100, height: 50)
        let lineWidth: CGFloat = 1.0
        
        // Left signature (Petugas Lab)
        let leftX: CGFloat = 33
        let leftTitle = NSAttributedString(string: "Petugas Lab", attributes: boldText)
        leftTitle.draw(at: CGPoint(x: leftX, y: startY))
        
        // Draw signature image placeholder
        if let signatureImage = UIImage(named: "ttd") {
            signatureImage.draw(in: CGRect(x: leftX, y: startY + 20, width: signatureSize.width, height: signatureSize.height))
        }
        
        // Draw horizontal line
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(lineWidth)
            context.move(to: CGPoint(x: leftX, y: startY + 80))
            context.addLine(to: CGPoint(x: leftX + signatureSize.width, y: startY + 80))
            context.strokePath()
        }
        
        // Draw name
        let leftName = NSAttributedString(string: "{Bunga Prameswari, S.Tr.Kes}", attributes: regularText)
        leftName.draw(at: CGPoint(x: leftX, y: startY + 90))
        
        // Right signature (Dokter PJ)
        let rightX: CGFloat = 400
        let rightTitle = NSAttributedString(string: "Dokter PJ Pemeriksaan Lab", attributes: boldText)
        rightTitle.draw(at: CGPoint(x: rightX, y: startY))
        
        // Draw signature image placeholder
        if let signatureImage = UIImage(named: "ttd") {
            signatureImage.draw(in: CGRect(x: rightX, y: startY + 20, width: signatureSize.width, height: signatureSize.height))
        }
        
        // Draw horizontal line
        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.black.cgColor)
            context.setLineWidth(lineWidth)
            context.move(to: CGPoint(x: rightX, y: startY + 80))
            context.addLine(to: CGPoint(x: rightX + signatureSize.width, y: startY + 80))
            context.strokePath()
        }
        
        // Draw name
        let rightName = NSAttributedString(string: "{dr. John Doe}", attributes: regularText)
        rightName.draw(at: CGPoint(x: rightX, y: startY + 90))
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

    private func sharePDF() {
        let pdfData = generatePDF()
        let activityVC = UIActivityViewController(activityItems: [pdfData], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
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
