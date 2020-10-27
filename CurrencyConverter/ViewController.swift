//
//  ViewController.swift
//  CurrencyConverter
//
//  Created by Tatsuya Moriguchi on 10/24/20.
//  Copyright © 2020 Tatsuya Moriguchi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
    var sourceSymbol: String = "USD"
    var selectedCurrencies = "EUR,GBP,JPY"
    var formatAmount: Int = 10
    

    


    override func viewDidLoad() {
        super.viewDidLoad()

        let urlComponents = "&source=\(sourceSymbol)&currencies=\(selectedCurrencies)&format=\(formatAmount)"
        let url = CurrencyData().baseUrl + urlComponents
                  
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
  
                }

            } catch {
                print(" JSON decoding Error: \(error)")
            }
             
        })
        task.resume()
                
    }


}
