//
//  CurrencyData.swift
//  CurrencyConverter
//
//  Created by Tatsuya Moriguchi on 10/24/20.
//  Copyright © 2020 Tatsuya Moriguchi. All rights reserved.
//

import Foundation


class CurrencyData {
    
    let YOUR_ACCESS_KEY = "19552d5b12448d31083079b95034ff63"
    let baseUrl = "https://api.currencylayer.com/convert? access_key = YOUR_ACCESS_KEY"
    
    
}

/*
 {
   "success":true,
   "terms":"https:\/\/currencylayer.com\/terms",
   "privacy":"https:\/\/currencylayer.com\/privacy",
   "timestamp":1603644007,
   "source":"USD",
   "quotes":{
     "USDEUR":0.842993,
     "USDGBP":0.766548,
     "USDCAD":1.312704,
     "USDPLN":3.85147
   }
 }
 */

//struct Response: Codable {
//
//    var success: Bool
//    var terms: String?
//    var privacy: String?
//    var timestamp: Int
//    var source: String
//    var quotes: [[String: Float]]
// }


struct Response: Codable {
    var success: Bool
    var terms: String?
    var privacy: String?
    var timestamp: Int
    var source: String?
    var quotes: [String: Float]
}



/*
 struct USD : Decodable {

     private enum CodingKeys : String, CodingKey {
         case type = "TYPE"
         case market = "MARKET"
         case price = "PRICE"
         case percentChange24h = "CHANGEPCT24HOUR"
     }
     let type : String
     let market : String
     let price : Double
     let percentChange24h : Double
 }
 */




/*
{
  "success":true,
  "terms":"https:\/\/currencylayer.com\/terms",
  "privacy":"https:\/\/currencylayer.com\/privacy",
  "timestamp":1603730406,
  "source":"USD",
  "quotes":{
    "USDEUR":0.846175,
    "USDGBP":0.768375,
    "USDCAD":1.321635,
    "USDPLN":3.872499
  }
}
*/











//struct QueryData: Codable {
//    var from: String?
//    var to: String?
//    var amount: Int?
//}
//
//struct InfoData: Codable {
//    var timestamp: Int?
//    var quote: Float?
//}

