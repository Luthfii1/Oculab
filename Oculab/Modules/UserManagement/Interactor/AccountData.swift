//
//  AccountData.swift
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

struct RegisterAccountBody: Codable {
    var role: RolesType
    var name: String
    var email: String
}

struct UpdatePasswordBody: Codable {
    var previousPassword: String
    var newPassword: String
}

struct AccountResponse: Codable, Identifiable {
    var id: String
    var name: String
    var role: RolesType
    var email: String
    var username: String?
    var accessPin: String?
}

struct RegisterAccountResponse: Codable {
    var id: String
    var username: String
    var currentPassword: String
    
    enum CodingKeys: String, CodingKey {
        case id = "userId"
        case username
        case currentPassword
    }
    
    init(id: String, username: String, currentPassword: String) {
        self.id = id
        self.username = username
        self.currentPassword = currentPassword
    }
}
struct UpdatePasswordResponse: Codable {
    var userId: String
    var username: String
    var currentPassword: String
}

