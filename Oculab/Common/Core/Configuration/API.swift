//
//  API.swift
//  Oculab
//
//  Created by Luthfi Misbachul Munir on 28/10/24.
//

import Foundation

class API {
    static let BE: String = BE_PROD
    
    static let BE_VERCEL: String = "https://oculab-be.vercel.app"
    static let BE_PROD: String = "https://api.oculab.ai"
    static let BE_STAGING: String = "https://staging.oculab.ai"

    static let ML: String = "https://oculab-ml.vercel.app"

    /// Socket.IO base URL (same host as REST API).
    static var socketURL: URL {
        URL(string: BE)!
    }

    static var analysisProgressPath: String {
        BE + "/aiAnalysisProgress/"
    }
}
