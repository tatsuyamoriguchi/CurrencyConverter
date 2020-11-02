//
//  ViewController.swift
//  CurrencyConverter
//
//  Created by Tatsuya Moriguchi on 10/24/20.
//  Copyright © 2020 Tatsuya Moriguchi. All rights reserved.
//

import UIKit
import CoreData


class ViewController: UIViewController {
    
    
    // REST API access key info, Need to encrypt key!!!
    let ACCESS_KEY = "19552d5b12448d31083079b95034ff63"
    let liveKey = "live"
    let listKey = "list"

    
    var sourceSymbol: String = "USD" // default currency symbol
    var selectedCurrencies = ""
    var formatAmount: Int = 1 // default source (USD) value to convert, otherwise obtain from TextField
    var quotesDict: Dictionary? = [String: Float]() // dictionary data from JSON
    var currencyTypes: Array<String> = [] // Currency Symbols array to store to local store
    var currencyValues: Array<Float> = [] // Currency values calculated from USD $1 This will be used to calculate the conversion amond all currencies, Store to the local store
    var currencyDescriptionArray: Array<String> = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    
    
    var currencySymbols: Array<String> = [] {
        didSet {
            tableView.reloadData()
        }
    }

    
    
    var convertedValues: Array<Float> = [] {
        didSet {
            tableView.reloadData()
        }
    }


    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var amount2Convert: UITextField!
    

    // UIPickerView related properties to display available currency types
    @IBOutlet weak var sourceCurrencyPicker: UIPickerView!
    var pickerView = UIPickerView()
    var pickerData: [String] = [String]()
    var pickerDataSymbols: [String] = [String]()
    var pickerDataDescription: [String] = [String]()
     
    
    override func viewDidLoad() {
        super.viewDidLoad()

//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(false)
    
        // Goal type PickerView for Goal sorting
        self.sourceCurrencyPicker.delegate = self
        self.sourceCurrencyPicker.dataSource = self

        // If 30 min threashold condition meets, get the latest data from REST API, otherwise
        // use the local data
        getSourceData() // Get the latest available currency list from REST API
     
        tableView.delegate = self
        tableView.dataSource = self
        
    }
    
    
    

    // Get JSON data for UIPickerView
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
                    
                    // Sort data by value
                    let sortedPickerDataDict = pickerDataDict.sorted { (first, second) -> Bool in
                        return first.key < second.key
//                        return first.value < second.value
                    }
                    // Empty the array
                    //self.currencyDescriptionArray = []

                    // Store sorted keys and values into arrays
                    for i in sortedPickerDataDict {
                        
                        // To display currency code in UIPickerView
                        let currencyCodeDesc = i.key + " " + i.value
                        
                        self.pickerDataSymbols.append(i.key)
                        //self.pickerDataDescription.append(i.value)
                        self.pickerDataDescription.append(currencyCodeDesc)
                        
                        //let currencyDescription = String((i.key).dropFirst(3))
                        // i.value is currencyDescription, i.e. United States of America Dollars
                        //self.save(key: i.key, value: nil, currencyDescription: i.value)
                        self.currencyDescriptionArray.append(i.value)
                        //print("i.key - i.value: \(i.key) - \(i.value)")
                    }

                    // Store pickerDataDescription to pickerData to display in UIPickerView
                    DispatchQueue.main.async {
                        self.pickerData = self.pickerDataDescription
                        DispatchQueue.main.async {
                            // Reload data for UIPickerView
                            self.sourceCurrencyPicker.reloadAllComponents()
                        }
                    }
                }

            } catch {
                print("getSourceData() JSON Decoging Error: \(error)")
            }
        })
        task.resume()
    }
    
    
    @IBAction func convertOnPressed(_ sender: UIButton) {
        
        // Get amount2convert from textfield
        // calculate converted values
        guard let inputValue = self.amount2Convert.text else { return }

        // For insance, User types 100 for JPY
        guard let value2convert = Float(inputValue) else {
            print("Error in changing Type inputValue to Float")
            return  }

        // Get currency symbol from UIPickerView currencySymbol: sourceSymbol
        // Combine sourceSymbol with "USD" since Core Data attribute data starts with USD
        // due to REST API free account limitation
        let key = "USD\(sourceSymbol)"
        
        // retrieve source currency rate against USD from Core Data
        // i.e. USDJPY = 1.04
        let rate = CoreDataController().retrieve(key: key)
        
        // Obtain currentTime to compare with threasholdTime
        let currentTime = Date()

        // To set the threasholdTime to update currency conversion rate data to at least 30 minutes passed
        let threasholdTime = Date().addingTimeInterval(-60 * 1) // use -60 * 30
        var lastTimeStamp: Date

        
        
        // Check if timeStamp data exists, use it as lastTimeStamp next time
        if ((UserDefaults.standard.object(forKey: "timeStamp")) != nil) {
            lastTimeStamp = UserDefaults.standard.object(forKey: "timeStamp") as! Date
            
        } else {
            // If timeStamp doesn't exist, store and use currentTime as lastTimeStamp
            UserDefaults.standard.setValue(currentTime, forKey: "timeStamp")
            lastTimeStamp = currentTime
        }
        
        
        
        // Check if lastTimeStamp is before threasholdTime, update currency rates
        if lastTimeStamp < threasholdTime {
            print("lastTimeStamp < threasholdTime")
            
            // store currentTime to UserDefaults timeStamp for next time use
            UserDefaults.standard.setValue(currentTime, forKey: "timeStamp")
            
            // Download the latest conversion data (in USD since the source currency is USD only for API free account. )
            let urlComponents = "&source=USD&currencies=&format=1"
            
            let url = "\(CurrencyData().baseUrl)\(liveKey)?access_key=\(ACCESS_KEY)\(urlComponents)"
            
            // Delete Core Data entity data before updating with new data
            CoreDataController().deleteAllData("CurrencyEntity")
            
            self.convertedValues = []
            
            // Update USD conversion data via REST API JSON
            self.getData(url: url, currencyTypesCompletionHandler: { currencyTypes, error in
                
                self.currencySymbols = currencyTypes!
                
                DispatchQueue.main.async {
                    
                    //self.getCurrencyDescriptionData()
                    var n = 0
                    for i in self.currencySymbols {
                        guard let value = self.convertValue(sourceSymbol: self.sourceSymbol, rate: rate, targetSymbol: i, value2convert: value2convert) else { return }
                        self.convertedValues.append(value)
                        //print("currencySumbol - convertedValue : \(i) - \(value)")

                        n += 1
                    }
                }
            })
            
            
        } else {
            // This part doesn't load tableView data, self.currencySymbols = [] nil!!!!
            // Otherwise use Core Data exiting data to calculate exchange rates
            print("")
            print("lastTimeStamp >= threasholdTime")
            print("Hmmm")


            // Initialize convertedValues array to refresh
            self.convertedValues = []
            print("")
            print("self.convertedValues")
            print(self.convertedValues)
            print("")
            
            
            
            DispatchQueue.main.async {

                // Watch this won't duplicate currencySymbols elements
                CoreDataController().getCurrencyDescriptionData()
                
                var n = 0
                for i in self.currencySymbols {
                    guard let value = self.convertValue(sourceSymbol: self.sourceSymbol, rate: rate, targetSymbol: i, value2convert: value2convert) else { return }
                    self.convertedValues.append(value)
                    
                    n += 1
                }

            }
        }
       
    }
    
    
    
    // Calculate converted values
    func convertValue(sourceSymbol: String, rate: Float, targetSymbol: String, value2convert: Float ) -> Float? {
        
        // Passed from parameters: sourceSymbol & value2convert: i.e. 100JPY
        // Passed from parameter: rate: i.e. Get JPY exchange rate against USD: USDJPY = 104.65504
        
        // sourceUSDRate = 1 / 104.65504 = 0.009552
        let sourceUSDRate = 1 / rate
        
        // Get EUR exchange rate against USD: USDEUR = 0.856348
        let USDTargetRate = CoreDataController().retrieve(key: targetSymbol)
        
        // EURUSD = 1 * 0.856348 = 0.75187969924812
        let targetUSDRate = 1 * USDTargetRate

        // EUR = 100 * 0.961538461538462 * 0.75187969924812EURUSD  = 72.296124927703881JPY
        let convertedAmount = value2convert * sourceUSDRate * targetUSDRate
        
        return convertedAmount
    }
    

    
    
    
    // Get exchange rate values vs USD JSON data to store onto local store via Core Data
    func getData(url: String, currencyTypesCompletionHandler: @escaping (Array<String>?, Error?) -> Void) {
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
                    
                    self.quotesDict = result?.quotes
                    
  
                    // currencyValues are exchanged values caluculated by USD $1 since REST API free account
                    // cannot change the source currency type
                    (self.currencyTypes, self.currencyValues) = self.sortQuotesDict(quotesDict: self.quotesDict!)

                     currencyTypesCompletionHandler(self.currencyTypes, nil)
                    
                    // Save the latest JSON currency rate data (vs. USD) to Core Data
                    var n = 0
                    for i in self.currencyTypes {

                        // Combine key, currency symbol and curerncy description
                        // i.e. JPN Japanese Yen for readability in tableView cells
                        let combined = i + " " + self.currencyDescriptionArray[n]
                        
                        // Save currency rate value to Core Data
                        CoreDataController().saveData(key: i, value: self.currencyValues[n], currencyDescription: combined)
                        //print("currencyType - currencyValue: \(i) - \(self.currencyValues[n]) - \(combined) - \(n)")

                        n += 1
                    }
 
                }
            } catch {
                print("func getData(url: String) JSON decoding Error: \(error)")
                currencyTypesCompletionHandler(nil, error)
            }
        })
        task.resume()

    }
    
    
    

    // Sort currency symbols and values dictionary
    func sortQuotesDict(quotesDict: Dictionary<String, Float>) -> (Array<String>, Array<Float>) {

        let sortedArray = quotesDict.sorted{ $0.key < $1.key }
        
        var types = [String]()
        var values = [Float]()
        for (key, value) in sortedArray {

            types.append(key)
            values.append(value)
        }
        
        return (types, values)
    }

}



extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Maybe open another view??
        print("you tapped a row.")
    }
}


extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return convertedValues.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
//        cell.textLabel?.text = currencySymbols[indexPath.row]
        // Somewhat USDAED's description is missing and cells show each data with one wrong row
        //
        //cell.textLabel?.text = currencyDescriptionArray[indexPath.row]
        cell.textLabel?.text = pickerDataDescription[indexPath.row]  //currencyDescriptionArray[indexPath.row]
        cell.detailTextLabel?.text = String(convertedValues[indexPath.row])

        return cell
    }
    
}


// PickerView
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


