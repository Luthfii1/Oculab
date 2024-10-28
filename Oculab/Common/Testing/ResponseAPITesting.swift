//
//  ResponseAPITesting.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 23/10/24.
//

import Foundation

struct Todo: Decodable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}
