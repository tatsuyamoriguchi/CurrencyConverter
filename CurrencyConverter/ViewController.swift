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
    
    
     
    
    
    
//    var currencySymbols: Array<String> = [] // currency symbols to display in TableView
    var currencySymbols: Array<String> = [] {
        didSet {
            tableView.reloadData()
        }
    }

    
    
//    var convertedValues: Array<Float> = [] // converted currency values to display in TableView
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
    
 
    
//    override func viewDidLoad() {
//        super.viewDidLoad()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
    
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

        
        // USDJPY retrieve rate from Core Data
        // i.e. USDJPY = 1.04
        let rate = retrieve(key: key)
        
        
        // Obtain currentTime to compare with threasholdTime
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
            // Update USD conversion data via REST API JSON
            self.getData(url: url, currencyTypesCompletionHandler: { currencyTypes, error in
                self.currencySymbols = currencyTypes!
                
            })
                
            
            print("Hey 1")
            DispatchQueue.main.async {
            print("Hey 2")
  
                print("")
                print("self.currencySymbols")
                print(self.currencySymbols)
                print("")

                var n = 0
                for i in self.currencySymbols {
                    print("Hey 3")
                    print("self.sourceSymbol: \(self.sourceSymbol)")
                    print("rate: \(rate)")
                    print("i: \(i)")
                    print("value2convert: \(value2convert)")
                    
                    
                    guard let value = self.convertValue(sourceSymbol: self.sourceSymbol, rate: rate, targetSymbol: i, value2convert: value2convert) else { return }
                    self.convertedValues.append(value)
                    print("value")
                    print(value)
                    n += 1
                }
                
                
            }
            
            
            
            
        } else {
            // Otherwise use Core Data exiting data to calculate exchange rates
            print("lastTimeStamp >= threasholdTime")
            print("Hmmm")

// Read Core Data and sort

            DispatchQueue.main.async {
                print("")
                print("self.currencySymbols")
                print(self.currencySymbols)
                print("")

                
                var n = 0
                for i in self.currencySymbols {
                    guard let value = self.convertValue(sourceSymbol: self.sourceSymbol, rate: rate, targetSymbol: i, value2convert: value2convert) else {
                        print("test2")
                        return }
                    self.convertedValues.append(value)
                    print("value")
                    print(value)
                    
                    n += 1

                }

            }
        }
        
//        DispatchQueue.main.async {
//            let refresh = UIRefreshControl()
//            refresh.beginRefreshing()
//            self.tableView.reloadData()
//            refresh.endRefreshing()
//        }

       
    }
    
    
    
    // Calculate converted values
    func convertValue(sourceSymbol: String, rate: Float, targetSymbol: String, value2convert: Float ) -> Float? {
        
        // USDJPY = 1.04
        // xUSD = 100JPY / 1.04)
        // xUSD = 96.1538462
        //USDEUR = 1.33
        // yEUR = xUSD / 1.33 = 72.2961249


//        // Get amount2convert from textfield
//        // For insance, User types 100 for JPY
//        guard let inputValue = Float(value2convert) else {
//            print("Error in inputValue")
//            return 0 }
//
//        // Get currency symbol from UIPickerView currencySymbol: sourceSymbol
//        // Combine sourceSymbol with "USD" since Core Data attribute data starts with USD
//        // due to REST API free account limitation
//        let key = "USD\(sourceSymbol)"
//
//
//        // USDJPY retrieve rate from Core Data
//        // i.e. USDJPY = 1.04
//        let rate = retrieve(key: key)
        
        
        // calculate convertedValues from calculating conversion rates
        // with amount2convert vs USD
        // Conversion Calculation rate 100JPY / 1.04 = 96.1538462JPY (=1USD)
        let rate2Convert = value2convert / rate

        // Retrieve targetRate from Core Data, i.e. 1USD = 1.33EUR
        // USDEUR: 1.33 (1USD = 1.33EUR)
        let targetRate = retrieve(key: targetSymbol)
        print("targetRate: \(targetRate)")
        
        // Calculate how much in target currency is sourceCurrency (JPY)
        // 100 JPY =  96.1538462JPY / 1.33 = 72.2961253 JPY ( = 1EUR)
        let convertedAmount = rate2Convert / targetRate
        print("convertedAmount: \(convertedAmount)")
        
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

                    print("getData() currencyTypes")
                    print(self.currencyTypes)
                     currencyTypesCompletionHandler(self.currencyTypes, nil)
                    
                    // Save the latest JSON currency rate data (vs. USD) to Core Data
                    var n = 0
                    for i in self.currencyTypes {

                        // Save currency rate value to Core Data
                        self.save(key: i, value: self.currencyValues[n])
                        
                        // Calulate convertedValue currencyValues[n] * conversion rate
                        //let convertedValue = self.currencyValues[n] * 1 // conversion rate for each currency
                        //guard let value = self.convertValue(sourceSymbol: self.sourceSymbol, rate: 1, targetSymbol: i, value2convert: 1) else { return }
                        
                        // Store currency rate value to convertedValues array
//                        self.convertedValues.append(value)
                        //self.convertedValues.append(self.currencyValues[n])

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
        print("")
        let sortedArray = quotesDict.sorted{ $0.key < $1.key }
        
        var types = [String]()
        var values = [Float]()
        for (key, value) in sortedArray {

            //print(key, value)

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

        print("")
        print("convertedValues.count ")
        print(convertedValues.count)
        return convertedValues.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = currencySymbols[indexPath.row]
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
                //print("Saved: \(key) = \(value)")
            } catch {
                print("Core Data Saving Error: \(error)")
            }
        }
    }
    
    // Retrieve data via Core Data
    func retrieve(key: String) -> Float {
        var convRate: Float?
        print("")
        print("key for retrieve: ")
        print(key)
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<CurrencyEntity>(entityName: "CurrencyEntity")
            print("")
            print("appDelegate")
            print("")
            
            do {
                let results = try context.fetch(fetchRequest)
                print("inside do {")
                for result in results {
                    // something wrong with currencyRate, USDAED's value???
                    if result.currencySymbol == key {
                    
                        print("result")
                        print(result)
                        convRate = result.currencyRate
                    
                        return convRate!
                    }
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
