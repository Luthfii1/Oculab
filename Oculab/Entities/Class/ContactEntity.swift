//
//  ContactEntity.swift
//  Oculab
//
//  Created by Bunga Prameswari on 07/05/25.
//

import Foundation
import SwiftData

@Model
class Contact: Codable, Identifiable {
    var id: String
    var whatsappLink: String

    init(
        id: String = UUID().uuidString,
        whatsappLink: String = "https://wa.me/<number>"
    ) {
        self.id = id
        self.whatsappLink = whatsappLink
    }

    enum CodingKeys: CodingKey {
        case id
        case whatsappLink
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.whatsappLink = try container.decode(String.self, forKey: .whatsappLink)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(whatsappLink, forKey: .whatsappLink)
    }
}
