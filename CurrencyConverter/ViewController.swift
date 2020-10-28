//
//  ViewController.swift
//  CurrencyConverter
//
//  Created by Tatsuya Moriguchi on 10/24/20.
//  Copyright © 2020 Tatsuya Moriguchi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    
    
    let ACCESS_KEY = "19552d5b12448d31083079b95034ff63"
    let liveKey = "live"
    let listKey = "list"

    
    var sourceSymbol: String = "USD" // default currency symbol
    var selectedCurrencies = ""
    var formatAmount: Int = 10
    var quotsDict: Dictionary = [String: Float]()
    var currencyTypes: Array<String> = []
    var convertedValues: Array<Float> = []

    @IBOutlet weak var tableView: UITableView!

    
    @IBOutlet weak var amount2Convert: UITextField!
    
    // UIPickerView related properties
    @IBOutlet weak var sourceCurrencyPicker: UIPickerView!
    var pickerView = UIPickerView()
    var pickerData: [String] = [String]()
    var pickerDataSymbols: [String] = [String]()
    var pickerDataDescription: [String] = [String]()

    @IBAction func convertOnPressed(_ sender: UIButton) {
        
        let urlComponents = "&source=\(sourceSymbol)&currencies=\(selectedCurrencies)&format=\(formatAmount)"
        
        let url = "\(CurrencyData().baseUrl)\(liveKey)?access_key=\(ACCESS_KEY)\(urlComponents)"
     
        getData(url: url)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Goal type PickerView for Goal sorting
        self.sourceCurrencyPicker.delegate = self
        self.sourceCurrencyPicker.dataSource = self
        getSourceData()
         
     
        tableView.delegate = self
        tableView.dataSource = self
        
        
        //if let row = pickerDataDescription.indexOf("United States Dollars") {
//             pickerView.selectRow(2, inComponent: 0, animated: false)
         //}
        
    }

    func getSourceData()  {
        var pickerDataDict = [String:String]()
        let urlComponents = "&source=\(sourceSymbol)&currencies=\(selectedCurrencies)&format=\(formatAmount)"
        let url = "\(CurrencyData().baseUrl)\(listKey)?access_key=\(ACCESS_KEY)\(urlComponents)"
        
        let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { data, response, error in
            
            guard let data = data, error == nil else {
                print("Something went wrong while getting data.")
                return
            }
            
            // Get and decode data
            var result: SourceResponse?
            
            
            do {
                result = try JSONDecoder().decode(SourceResponse.self, from: data)
                
                DispatchQueue.main.async {
                    pickerDataDict = result!.currencies
                    
                    let sortedPickerDataDict = pickerDataDict.sorted { (first, second) -> Bool in
                        return first.value < second.value
                    }
                    
                    for i in sortedPickerDataDict {
                        self.pickerDataSymbols.append(i.key)
                        self.pickerDataDescription.append(i.value)
                    }

                    
                    // Sort dictionary by Description
//                    let byValue = {
//                        (elem1:(key: String, val: String), elem2:(key: String, val: String))->Bool in
//                        if elem1.val < elem2.val {
//                            return true
//                        } else {
//                            return false
//                        }
//                    }
//                    let sortedPickerDataDict = pickerDataDict.sorted(by: byValue)
//
                    
                    
//                    print("pickerDataDict")
//                    print(pickerDataDict)
//
                    //let sortedPickerDataDict = pickerDataDict.sorted { $0.1 < $1.1 }
                    //var sortedKeys = Array(dict.keys).sorted({dict[$0] < dict[$1]})
//                    print("")
//                    print("sortedPickerDataDict")
//                    print(sortedPickerDataDict)

//                    self.pickerDataSymbols = Array(pickerDataDict.keys)
                    print("self.pickerDataSymbols")
                    print(self.pickerDataSymbols)
                    print("")
//                    self.pickerDataDescription = Array(pickerDataDict.values)
                    print("self.pickerDataDescription")
                    print(self.pickerDataDescription)
                    
                    
                    DispatchQueue.main.async {
                        self.pickerData = self.pickerDataDescription
//                        print("self.pickerData")
//                        print(self.pickerData)
                        DispatchQueue.main.async {
                            self.sourceCurrencyPicker.reloadAllComponents()
                        }
                    }
//                    print(self.pickerDataSymbols)
//                    print("")
//                    print("------------------------")
//                    print("")
//                    print(self.pickerDataDescription)
                    
//                    print("result!.currencies")
//                    print(result!.currencies)
//                    print("    Hello    ")
//                    print("pickerDataDict")
//                    print(pickerDataDict)
                    
                }

            } catch {
                print("getSourceData() JSON Decoging Error: \(error)")
                
            }
        })
        task.resume()
        
        
        
        
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
//                    print(result?.success as Any)
//                    print(result?.terms as Any)
//                    print(result?.privacy as Any)
//
//                    print(result?.timestamp as Any)
//                    print(result?.source as Any)
//                    print(result?.quotes as Any)
                    self.quotsDict = result?.quotes as! [String : Float]
                    (self.currencyTypes, self.convertedValues) = self.sortQuotesDict(quotesDict: self.quotsDict)
//                    print("self.quotsDict")
//                    print(self.quotsDict)
//                    print(self.currencyTypes)
//                    print(self.convertedValues)
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
  
                }

            } catch {
                print("func getData(url: String) JSON decoding Error: \(error)")
            }
             
        })
        task.resume()
                
    }
    
    func sortQuotesDict(quotesDict: Dictionary<String, Float>) -> (Array<String>, Array<Float>) {
        
        
        for i in quotesDict {
            
            currencyTypes.append(i.key)
            convertedValues.append(i.value)
            
        }
        
        
        
        return (currencyTypes, convertedValues)
    }


}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("you tapped a row.")
    }
    
}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quotsDict.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = currencyTypes[indexPath.row]
        cell.detailTextLabel?.text = String(convertedValues[indexPath.row])

        //cell.textLabel?.text = "Hello"
        return cell
    }
    
}

extension ViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        return pickerData[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        sourceSymbol = pickerDataSymbols[row]
        print("you selected a row, \(row), \(sourceSymbol)")
    }
}
