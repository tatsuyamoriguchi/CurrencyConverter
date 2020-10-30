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
    
    
    
    let ACCESS_KEY = "19552d5b12448d31083079b95034ff63"
    let liveKey = "live"
    let listKey = "list"

    
    var sourceSymbol: String = "USD" // default currency symbol
    var selectedCurrencies = ""
    var formatAmount: Int = 10
    var quotsDict: Dictionary? = [String: Float]()
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


 
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Goal type PickerView for Goal sorting
        self.sourceCurrencyPicker.delegate = self
        self.sourceCurrencyPicker.dataSource = self
        getSourceData()
     
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
         print("currentTime")
         print(currentTime)
         // To update conversion rates if at least 30 minutes passed
         let threasholdTime = Date().addingTimeInterval(-60 * 30)
         print("threasholdTime")
         print(threasholdTime)
         var lastTimeStamp: Date
         // Check if previous timeStamp exists or if the previous access to APi was 30 minuets ago or less
         
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




         if lastTimeStamp < threasholdTime {
             print("lastTimeStamp < threasholdTime")
             // Download the latest conversion data (in USD since the source currency is USD only for API free account. )
             let urlComponents = "&source=USD&currencies=&format=1"
             
             let url = "\(CurrencyData().baseUrl)\(liveKey)?access_key=\(ACCESS_KEY)\(urlComponents)"
             print("")
             print("url to update currency rates")
             print(url)
             
             getData(url: url)

             
         } else {
            print("lastTimeStamp >= threasholdTime")
             
             
             
         }
             
             
             
                 
         // If within 30min, access conversion rate data in Core Data
         
         
         // If more than 30 min, access API and get the latest conversion rates
         
         
         // Use the conversion rates to calculate values with currency type and amount to convert from UI
         
         
         
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
                    
                    self.quotsDict = result?.quotes
  
                    (self.currencyTypes, self.convertedValues) = self.sortQuotesDict(quotesDict: self.quotsDict!)
//                    DispatchQueue.main.async {
//                        self.tableView.reloadData()
//                    }
                    var n = 0
                    for i in self.currencyTypes {
                        self.save(key: i, value: self.convertedValues[n])
                        n += 1
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
    
    
    // Calculate converted values
    func convertValue(sourceSymbol: String, value2convert: Double ) {
        
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
        return quotsDict?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
//        cell.textLabel?.text = currencyTypes[indexPath.row]
//        cell.detailTextLabel?.text = String(convertedValues[indexPath.row])

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
//                let fetchRequest : NSFetchRequest<ConversionRate> = ConversionRate.fetchRequest()

                do {
                    let results = try context.fetch(fetchRequest)
                    for result in results {
                        convRate = result.currencyRate
                        print(convRate as Any)
                        return convRate!
                    }
                } catch {
                    print("Core Data Retrieve Error: \(error)")
                }
        }
        return convRate!
    }

}
