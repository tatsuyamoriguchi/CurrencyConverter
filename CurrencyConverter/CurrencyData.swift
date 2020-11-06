//
//  CurrencyData.swift
//  CurrencyConverter
//
//  Created by Tatsuya Moriguchi on 10/24/20.
//  Copyright © 2020 Tatsuya Moriguchi. All rights reserved.
//

import Foundation


class CurrencyData {

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

