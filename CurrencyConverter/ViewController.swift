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
    
    var currencySymbols: Array<String> = [] // currency symbols to display in TableView
    var convertedValues: Array<Float> = [] // converted currency values to display in TableView

    
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
                        return first.value < second.value
                    }
                    // Store sorted keys and values into arrays
                    for i in sortedPickerDataDict {
                        self.pickerDataSymbols.append(i.key)
                        self.pickerDataDescription.append(i.value)
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
        
        let currentTime = Date()
        print("")
        print("currentTime")
        print(currentTime)
        // To set the threasholdTime to update currency conversion rate data to at least 30 minutes passed
        let threasholdTime = Date().addingTimeInterval(-60 * 1) // use -60 * 30
        print("threasholdTime")
        print(threasholdTime)
 
        var lastTimeStamp: Date
        
        // Check if timeStamp data exists, use it as lastTimeStamp
        if ((UserDefaults.standard.object(forKey: "timeStamp")) != nil) {
            lastTimeStamp = UserDefaults.standard.object(forKey: "timeStamp") as! Date
            print("")
            print("lastTimeStamp")
            print(lastTimeStamp)
            
        } else {
            // If timeStamp doesn't exist, store and use currentTime as lastTimeStamp
            UserDefaults.standard.setValue(currentTime, forKey: "timeStamp")
            lastTimeStamp = currentTime
        }
        
        
        
        // Check if lastTimeStamp is before threasholdTime, update currency rates
        if lastTimeStamp < threasholdTime {
            print("lastTimeStamp < threasholdTime")
            UserDefaults.standard.setValue(currentTime, forKey: "timeStamp")
            // Download the latest conversion data (in USD since the source currency is USD only for API free account. )
            let urlComponents = "&source=USD&currencies=&format=1"
            
            let url = "\(CurrencyData().baseUrl)\(liveKey)?access_key=\(ACCESS_KEY)\(urlComponents)"
            print("")
            print("url to update currency rates")
            print(url)
            
            // Delete Core Data entity data to update with new one
            deleteAllData("CurrencyEntity")
            // Get JSON data to update
            getData(url: url)
            
            
            DispatchQueue.main.async {
                // calculate converted values
                guard let inputValue = self.amount2Convert.text else { return }
                
                var n = 0
                for i in self.currencyTypes {
                    guard let value = self.convertValue(sourceSymbol: self.sourceSymbol, targetSymbol: i, value2convert: inputValue) else { return }
                    self.currencyValues.append(value)
                    
                    n += 1
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }

            }
            
            
            
        } else {
            // Otherwise use Core Data exiting data to calculate exchange rates
            print("lastTimeStamp >= threasholdTime")
            print("Hmmm")
            DispatchQueue.main.async {
                // calculate converted values
                guard let inputValue = self.amount2Convert.text else {
                    print("test")
                    return }
                
                var n = 0
                for i in self.currencyTypes {
                    guard let value = self.convertValue(sourceSymbol: self.sourceSymbol, targetSymbol: i, value2convert: inputValue) else {
                        print("test2")
                        return }
                    self.currencyValues.append(value)
                    print(value)
                    
                    n += 1
                }
                
                // Need reloadData timing???
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }

            }
        }
       
    }
    
    
    
    // Calculate converted values
    func convertValue(sourceSymbol: String, targetSymbol: String, value2convert: String ) -> Float? {
        // Get currency symbol from UIPickerView currencySymbol
        
        // Get amount2convert from textfield
        //guard let inputValue = Float(amount2Convert.text!) else { return Float(1) }
        // calculate convertedValues from calculating conversion rates
        // with amount2convert vs USD
        // i.e. USDJPY = 1.04
        // User types 100 for JPY
        // Conversion Calculation rate = 100 * 1.04 = 104
        // USDEUR: 1.33
        // 100 JPY =  104 * 1.33 = 138.32 EUR
        
        // Combine sourceSymbol with "USD" since Core Data attribute data starts with USD
        // due to free account limitation
        guard let inputValue = Float(value2convert) else {
            print("Error in inputValue")
            return 0 }
        let key = "USD\(sourceSymbol)"
        let rate = retrieve(key: key)
        let rate2Convert = inputValue * rate
        let targetRate = retrieve(key: targetSymbol)
        let convertedAmount = rate2Convert * targetRate
        
        
        return convertedAmount
    }
    

    
    
    
    // Get exchange rate value vs USD JSON data to store to local store via Core Data
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
                    
                    self.quotesDict = result?.quotes
  
                    // currencyValues are exchanged values caluculated by USD $1 since REST API free account
                    // cannot change the source currency type
                    (self.currencyTypes, self.currencyValues) = self.sortQuotesDict(quotesDict: self.quotesDict!)

                    // Save the latest JSON currency rate data (vs. USD) to Core Data
                    var n = 0
                    for i in self.currencyTypes {

                        // Save currency rate value to Core Data
                        self.save(key: i, value: self.currencyValues[n])
                        
                        // Calulate convertedValue currencyValues[n] * conversion rate
                        //let convertedValue = self.currencyValues[n] * 1 // conversion rate for each currency
                        guard let value = self.convertValue(sourceSymbol: self.sourceSymbol, targetSymbol: i, value2convert: self.amount2Convert.text!) else { return }
                        // Store currency rate value to convertedValues array
                        self.convertedValues.append(value)

                        n += 1
                    }
 
                }
            } catch {
                print("func getData(url: String) JSON decoding Error: \(error)")
            }
            
        })
        task.resume()
                
    }
    
    
    

    // Sort currency symbols and values dictionary
    func sortQuotesDict(quotesDict: Dictionary<String, Float>) -> (Array<String>, Array<Float>) {
        print("")
        let sortedArray = quotesDict.sorted{ $0.key < $1.key }
        
        var types = [String]()
        var values = [Float]()
        for (key, value) in sortedArray {

            print(key, value)

            types.append(key)
            values.append(value)
        }
        print("")
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
        return quotesDict?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = currencyTypes[indexPath.row]
        cell.detailTextLabel?.text = String(currencyValues[indexPath.row])

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


extension ViewController {
    // Save key and value data to Core Data
    func save(key: String, value: Float) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let context = appDelegate.persistentContainer.viewContext
            guard let entityDescription = NSEntityDescription.entity(forEntityName: "CurrencyEntity", in: context) else { return }
            let newValue = NSManagedObject(entity: entityDescription, insertInto: context)
            newValue.setValue(key, forKey: "currencySymbol")
            newValue.setValue(value, forKey: "currencyRate")
            
            do {
                try context.save()
                print("Saved: \(key) = \(value)")
            } catch {
                print("Core Data Saving Error: \(error)")
            }
        }
    }
    
    // Retrieve data via Core Data
    func retrieve(key: String) -> Float {
        var convRate: Float?
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<CurrencyEntity>(entityName: "CurrencyEntity")
            
            do {
                let results = try context.fetch(fetchRequest)
                for result in results {
                    // something wrong with currencyRate, USDAED's value???
                    convRate = result.currencyRate
//                    print("\(String(describing: result.currencySymbol)) convRate as Any :\(convRate as Any)")
                    return convRate!
                }
            } catch {
                print("Core Data Retrieve Error: \(error)")
            }
        }
        return 0
    }
    
    
    
    func deleteAllData(_ entity:String) {
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<CurrencyEntity>(entityName: entity)
            fetchRequest.returnsObjectsAsFaults = false
            do {
                let results = try context.fetch(fetchRequest)
                for object in results {
                    let objectData = object
                    context.delete(objectData)
                }
            } catch let error {
                print("Detele all data in \(entity) error :", error)
            }
        }
        
    }

}
