//
//  CurrencyData.swift
//  CurrencyConverter
//
//  Created by Tatsuya Moriguchi on 10/24/20.
//  Copyright © 2020 Tatsuya Moriguchi. All rights reserved.
//

import Foundation


class CurrencyData {
    // Need to encrypt access_key by git-secret or git-encrypt
//    let baseUrl = "http://api.currencylayer.com/live?access_key=19552d5b12448d31083079b95034ff63"
    let baseUrl = "http://api.currencylayer.com/"
}


struct SourceResponse: Codable {
    var success: Bool
    var terms: String?
    var privacy: String?
    var currencies: [String: String]
}


struct Response: Codable {
    var success: Bool
    var terms: String?
    var privacy: String?
    var timestamp: Int
    var source: String?
    var quotes: [String: Float]
}

