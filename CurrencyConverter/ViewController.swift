//
//  ViewController.swift
//  CurrencyConverter
//
//  Created by Tatsuya Moriguchi on 10/24/20.
//  Copyright © 2020 Tatsuya Moriguchi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
//    var sourceSymbol: String = "USD"
//    var selectedCurrencies: Array<String> = ["GBP", "MXN"]
//    var formatAmount: Int = 10
    

    


    override func viewDidLoad() {
        super.viewDidLoad()
//        let urlComponents = "&source=\(sourceSymbol)&currencies\(selectedCurrencies)&format\(formatAmount)"
//        let url = CurrencyData().baseUrl + urlComponents

        //let url = "https://api.currencylayer.com/convert?access_key=19552d5b12448d31083079b95034ff63&from=USD&to=GBP&amount=10"
        
//        let url =  "http://apilayer.net/api/live?access_key=19552d5b12448d31083079b95034ff63&currencies=EUR,GBP,CAD,PLN&source=USD&format=1"
        
        //let url = "http://api.currencylayer.com/live?access_key=19552d5b12448d31083079b95034ff63&format=1"
          
        let url = "http://api.currencylayer.com/live?access_key=19552d5b12448d31083079b95034ff63&currencies=EUR,GBP,CAD,JPY&source=USD&format=1"
        
        getData(url: url)
    }
    
    
    func getData(url: String) {
        let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { data, response, error in
            
            guard let data = data, error == nil else {
                print("Something went wrong while getting data.")
                return
            }
            
            // Get and decode data
            var result: Response?
            
            
            do {
                result = try JSONDecoder().decode(Response.self, from: data)
                DispatchQueue.main.async {
                    print(result?.success as Any)
                    print(result?.terms as Any)
                    print(result?.privacy as Any)
                    
                    print(result?.timestamp as Any)
                    print(result?.source as Any)
                    print(result?.quotes as Any)
  
//                    print(result?.info.timestamp as Any)
//                    print(result?.info.quote as Any)

                }

            } catch {
                print(" JSON decoding Error: \(error)")
            }
             
        })
        task.resume()
                
    }


}


/*
 
 / "live" endpoint - request the most recent exchange rate data
 http://api.currencylayer.com/live
     ? access_key = YOUR_ACCESS_KEY
     & source = GBP
     & currencies = USD,AUD,CAD,PLN,MXN
     & format = 1
 
 */
