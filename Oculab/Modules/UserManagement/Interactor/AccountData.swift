//
//  AccountData.swift
//  Oculab
//
//  Created by Risa on 11/05/25.
//

import Foundation

struct Account: Hashable, Codable {
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

struct DeleteAccountResponse: Codable, Identifiable {
    var id: String
    var name: String
    var role: RolesType
    var email: String
    
    enum CodingKeys: String, CodingKey {
        case id = "userId"
        case name
        case role
        case email
    }
}

struct RegisterAccountBody: Codable {
    var role: RolesType
    var name: String
    var email: String
}

struct RegisterAccountResponse: Codable {
    var id: String
    var email: String
    var currentPassword: String
    
    enum CodingKeys: String, CodingKey {
        case id = "userId"
        case email
        case currentPassword
    }
}

struct EditAccountBody: Codable {
    var name: String?
    var role: RolesType?
    
    init(name: String? = nil, role: RolesType? = nil) {
        self.name = name
        self.role = role
    }
}

struct EditAccountResponse: Codable, Identifiable {
    var id: String
    var name: String
    var role: RolesType
    var email: String
    
    enum CodingKeys: String, CodingKey {
        case id = "userId"
        case name
        case role
        case email
    }
}
