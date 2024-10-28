//
//  APIResponse.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 22/10/24.
//

import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let message: String
    let data: T
}
