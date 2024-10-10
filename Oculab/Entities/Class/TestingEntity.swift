//
//  TestingEntity.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 10/10/24.
//

import Foundation

struct TestingEntity: Decodable, Identifiable {
    let id: Int
    let title: String
    let body: String
}
