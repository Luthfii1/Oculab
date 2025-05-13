//
//  Account.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//


import Foundation

struct Account: Decodable {
    let id: String
    let name: String
    let role: RolesType
    let email: String
    let username: String?
    let accessPin: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case role
        case email
        case username
        case accessPin
    }
}
