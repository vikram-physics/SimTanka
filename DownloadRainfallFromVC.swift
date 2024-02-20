//
//  DownloadRainfallFromVC.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 12/11/22.
//
// Main class for downloading monthly rainfall
// using Visual Crossing API
// and Saving to CoreData
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html


import Foundation
import SwiftUI
import CoreData

class DownloadRainfallFromVC:  NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    @AppStorage("baseYear") private var baseYear = 0 // the year user started using SimTanka
    @AppStorage("rainRecordsAvailable") private var rainRecordsAvailable = false // is true if past five years rainfall records were downloaded
    
    @Published var downloading = false
    @Published var downloadMsg = String()
    
    // core data
    private let dailyRainController: NSFetchedResultsController<DailyRainVC>
    private let dbContext: NSManagedObjectContext
    
    // daily rainfall records stored in CoreData
    var dailyRainArrayCD : [DailyRainVC] = []
    
    // for charts
    @Published var arrayOfDailyRain: [DisplayDailyRain] = [] // for displaying in chart view
    @Published var arrayOfMonthRain: [DisplayMonthRain] = [] // for displaying in chart view
    @Published var arrayOfAnnualRain: [DisplayAnnualRain] = [] // for displayig in chart view
    @Published var arrayPast30daysRainfall:[DisplayAnnualRain] = []
    
    var totalRainfallmm = 0.0
    // for error
    @Published var errorOccurred: Bool = false
    
    
    init(managedObjectContext: NSManagedObjectContext) {
        let fetchDailyRainfall:NSFetchRequest<DailyRainVC> = DailyRainVC.fetchRequest()
        fetchDailyRainfall.sortDescriptors = [NSSortDescriptor(key: "year", ascending: true)]
        
        dailyRainController = NSFetchedResultsController(fetchRequest: fetchDailyRainfall, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        self.dbContext = managedObjectContext
        
        super.init()
        
        dailyRainController.delegate = self
        
        // fetch the stored data
        
        do {
            try dailyRainController.performFetch()
            dailyRainArrayCD = dailyRainController.fetchedObjects ?? []
        } catch {
            print("Could not fetch daily rainfall records")
        }
        
        // populate annual rainfall array from daily rainfall array
        if dailyRainArrayCD.count != 0 {
            
        }
    }
    
    func CreateURLrequestFor(month:Int, year:Int, latitude: Double, longitude: Double) -> URLRequest {
        
        // create start date
        let calendar = Calendar.current
        let dateComponents = DateComponents(year: year, month: month, day: 1)
        let startDate = calendar.date(from: dateComponents)!
        
        // convert start date into string
        let startDateFormatter = DateFormatter()
        startDateFormatter.dateFormat = "yyyy'-'MM'-'dd"
        let startString = startDateFormatter.string(from: startDate)
        
        // find the number of days
        let interval = calendar.dateInterval(of: .month, for: startDate)!
        let days = calendar.dateComponents([.day], from: interval.start, to: interval.end)
        
        // create end date
        let endDateComponents = DateComponents(year: year, month: month, day: days.day)
        let endDate = calendar.date(from: endDateComponents)!
        
        // convert end date into string
        let endString = startDateFormatter.string(from: endDate)
        
        
        // creating VC timeline weather api
        var urlString = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/"
        
        // convert latitude and location to string
        let locationString = String(latitude) + "," + String(longitude)
        
        // add  location to urlString
        urlString = urlString + locationString + "/"
        
        // add date1 - start date
        urlString = urlString + startString + "/"
        
        // add date2 - end date
        urlString = urlString + endString
        
        // create an instance of url component
        var urlComponents = URLComponents(string: urlString)!
        
       
        
        
        // create query
        
        // item for units returns rainfall in mm
        let queryItemUnit = URLQueryItem(name: "unitGroup", value: "metric")
        // maxDistance of the met. station for obtaining rainfall
        let queryItemMaxDistance = URLQueryItem(name: "maxDistance", value: "50000")
        // vc key for open source
        let queryItemKey = URLQueryItem(name: "key", value: "") // provided by Visual Crossing
        // daily historical observations
        let queryItemInclude = URLQueryItem(name: "include", value: "remote,obs,days")
        // get rainfall for the day
        let queryItemElements = URLQueryItem(name: "elements", value: "datetime,precip")
        
        let queryItems = [queryItemUnit, queryItemMaxDistance, queryItemElements, queryItemInclude, queryItemKey]

        urlComponents.queryItems = queryItems
        
        let testURL = urlComponents.url!
       
        return URLRequest(url: testURL)
        
    }
    
    func URLrequestForDailyRain(day:Int, month:Int, year:Int, latitude: Double, longitude: Double) -> URLRequest {
        
        // create date for which we want rainfall
         let rainDate = Helper.DateFromDayMonthYear(day: day, month: month, year: year)
        
        // convert date into string
       
        let startDateFormatter = DateFormatter()
        startDateFormatter.dateFormat = "yyyy'-'MM'-'dd"
        let rainDateString = startDateFormatter.string(from: rainDate)
        
        // creating VC timeline weather api
        var urlString = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/"
        
        // convert latitude and location to string
        let locationString = String(latitude) + "," + String(longitude)
        
        // add  location to urlString
        urlString = urlString + locationString + "/"
        
        // add date
        urlString = urlString + rainDateString
        
        // create an instance of url component
        var urlComponents = URLComponents(string: urlString)!
        
        // create query
        
        // item for units returns rainfall in mm
        let queryItemUnit = URLQueryItem(name: "unitGroup", value: "metric") // rainfall in mm
        // vc key for open source
        let queryItemKey = URLQueryItem(name: "key", value: "")
        // daily historical observations
        let queryItemInclude = URLQueryItem(name: "include", value: "obs,days")
        // get rainfall for the day
        let queryItemElements = URLQueryItem(name: "elements", value: "datetime,precip")
        
        let queryItems = [queryItemUnit, queryItemKey, queryItemInclude, queryItemElements]

        urlComponents.queryItems = queryItems
        
        // url created
        let url = urlComponents.url!
        
        return URLRequest(url: url)
        
    }
   
    
    func FetchMonthlyRainInMM(month: Int, year: Int, latitude: Double, longitude: Double) async throws -> DisplayMonthRain {
        
        let request = CreateURLrequestFor(month: month, year: year, latitude: latitude, longitude: longitude)
        let (data, response) = try await URLSession.shared.data(for: request)
       
        // test
        // print(String(data: data, encoding: .utf8)!)
        
        guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                      DispatchQueue.main.async {
                          print("no data")
                          self.downloading = false
                          self.errorOccurred = true 
                      }
                
                throw DownloadError.invalidServerResponse
            }
        
        let deCoder = JSONDecoder()
        
        let decodedRainfall = try deCoder.decode(VCrainData.self, from: data)
        
        // save decoded data
        SaveRainfallData(result: decodedRainfall)
        
        DispatchQueue.main.async {
            // append the dailyraindata
            for dayCount in decodedRainfall.days {
                self.arrayOfDailyRain.append(DisplayDailyRain(day: dayCount.day, month: dayCount.month, year: dayCount.year, rainMM: dayCount.precip ?? 0.0)) // null rainfal in downloaded data is treated as zero rainfall
                // save to coredata
            }
            
        }
        
        // for testing
       /* for dayR in decodedRainfall.days {
            print("Rainfall on \(dayR.day) - \(dayR.month) - \(dayR.year) = ", dayR.precip ?? 0.0) // treating null rainfall as zero
        } */
        
        let totalRainInMonth = decodedRainfall.days.reduce(0) {$0 + ($1.precip ?? 0.0) }
        return DisplayMonthRain(month: month, year: year, monthRainMM:totalRainInMonth)
    }
    
    func FetchDailyRainInMM(day: Int, month: Int, year: Int, latitude: Double, longitude: Double) async throws -> DisplayDailyRain {
        
        let request = URLrequestForDailyRain(day: day, month: month, year: year, latitude: latitude, longitude: longitude)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // for testing
       // print(String(data: data, encoding: .utf8)!)
        guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                      DispatchQueue.main.async {
                        //  print("no data")
                          self.downloading = false
                          self.errorOccurred = true
                      }
                throw DownloadError.invalidServerResponse
            }
       
        let deCoder = JSONDecoder()
        
        let decodedRainfall = try deCoder.decode(VCrainData.self, from: data)
        
        
       /*  for dayR in decodedRainfall.days {
            print("Rainfall on \(day) - \(month) - \(year) = ", dayR.precip)
        } */
       // dummy return change it!!!!
        return DisplayDailyRain(day: 1, month: 1, year: 2022, rainMM: decodedRainfall.days[0].precip ?? 0.0)
    }
    
    func FetchAndSavePastFiveYearsDailyRainfall(latitude: Double, longitude: Double) async throws {
        
        
        // to be called only at the start of using SimTanka
        // to be changed to baseYear - 6 ... baseYear - 2
        // to take into the account when user starts using SimTanka at the beginning of the year
        // and the daily rainfall records have not been updated
        
        for year in baseYear - 6...baseYear - 2 {
            
            DispatchQueue.main.async {
               self.arrayOfMonthRain = []
            }
            
            for month in 1...12 {

                DispatchQueue.main.async {
                    self.downloadMsg = "Downloading rainfall for \(Helper.intMonthToShortString(monthInt: month))-\(year)"
                }
                
                let result = try await FetchMonthlyRainInMM(month: month, year: year, latitude: latitude, longitude: longitude)
                
                // save result to core data
                
                DispatchQueue.main.async {
                    
                    self.arrayOfMonthRain.append(result)
                   // print(result)
                }
            }
            
            DispatchQueue.main.async {
                let annualRain = self.arrayOfMonthRain.reduce(0){ $0 + $1.monthRainMM}
                self.arrayOfAnnualRain.append(DisplayAnnualRain(year: year, annualRainMM: annualRain))
            }
        }
        
        DispatchQueue.main.async {
            self.downloadMsg = "Finished downloading rainfall"
            self.rainRecordsAvailable = true
        }
    }
    
    func SaveRainfallData(result: VCrainData) {
        
        
        DispatchQueue.main.async {
            for day in result.days {
                
                // check if we have already downloaded and saved this record
                if self.DailyRecordExistsFor(day: Int(day.day), month: Int(day.month), year: Int(day.year)) == false {
                    // create a new record
                    let newRecord = DailyRainVC(context: self.dbContext)
                    
                    // write in new record
                    newRecord.day = day.day
                    newRecord.month = day.month
                    newRecord.year = day.year
                    newRecord.dailyRainMM = day.precip ?? 0.0
                    
                    // try and save
                    do {
                        try self.dbContext.save()
                    } catch {
                        print("VC daily rainfall could not be saved")
                    }
                }
               
                
            }
        }
        
        
    }
    
    func LastFiveYearsAnnualRain() {
        // for displaying annual rainfall once it has been
        // down loaded
        
        // initialize
        DispatchQueue.main.async {
            self.downloadMsg = "Annual rainfall"
            self.arrayOfAnnualRain = []
        }
        
        
        // find current year
        //let currentYear = Helper.CurrentYear()
        
        let yearArray = ArrayOfLastFiveYearsWithDailyRainfall()
        
        for year in yearArray {
            // find all dailyrain records with the given year
            let yearPredicate = NSPredicate(format: "year=%i", year)
            
            // apply the filter
            let dayForYearArray = self.dailyRainArrayCD.filter( {
                day in
                yearPredicate.evaluate(with: day)
            })
            
            // add up the rainfall
            let annualRainInMM = dayForYearArray.reduce(0){ $0 + $1.dailyRainMM}
            let newDisplayRecord = DisplayAnnualRain(year: year, annualRainMM: annualRainInMM)
            
            DispatchQueue.main.async {
                self.arrayOfAnnualRain.append(newDisplayRecord)
            }
        }
        
       /* for year in self.EarliestYearForWhichRainRecordsExsist() ... self.LatestYearForWhichRainRecordExsist() {
            
            // find all dailyrain records with the given year
            let yearPredicate = NSPredicate(format: "year=%i", year)
            
            // apply the filter
            let dayForYearArray = self.dailyRainArrayCD.filter( {
                day in
                yearPredicate.evaluate(with: day)
            })
            
            // add up the rainfall
            let annualRainInMM = dayForYearArray.reduce(0){ $0 + $1.dailyRainMM}
            let newDisplayRecord = DisplayAnnualRain(year: year, annualRainMM: annualRainInMM)
            
            DispatchQueue.main.async {
                self.arrayOfAnnualRain.append(newDisplayRecord)
            }
        } */
        
       
        
    }
    
    func ForPlotThirtyDayRainfall()  -> [DisplayAnnualRain] {
        
        var displayArray:[DisplayAnnualRain] = []
        
        // days in current month
        let today = Date()
        let startDay = Helper.DayFromDate(date: today)
        let endDayCurrentMonth = Helper.DayFromDate(date: today.endOfMonth())
        let currentMonth = Helper.MonthFromDate(date: today)
        
        // days in next month
        let daysToAdd = 30
        var dateComponent = DateComponents()
        dateComponent.day = daysToAdd
        let futureDate = Calendar.current.date(byAdding: dateComponent, to: today)!
        let startDayNextMonth = Helper.DayFromDate(date: futureDate.startOfMonth())
        let endDayNextMonth = Helper.DayFromDate(date: futureDate)
        let nextMonth = Helper.MonthFromDate(date: futureDate)
        
       
        
        var yearsToSim = ArrayOfLastFiveYearsWithDailyRainfall()
        
        // check if the current month is december and the next month is January of the next year
        if currentMonth == 12 && nextMonth == 1 {
            
            _ = yearsToSim.removeLast() // we remove the most recent year for which there is no Jan rainfall
           
        }
        
        var monthsRainfallMM = 0.0
        
        for simYear in yearsToSim {
            
            monthsRainfallMM = 0.0
            
            for day in startDay...endDayCurrentMonth {
                
                monthsRainfallMM += self.DailyRainfallInM(day: day, month: currentMonth, year: simYear)
               
            }
            
            // if the final date falls in the next month
                
            if nextMonth != currentMonth {
                
                for day in startDayNextMonth...endDayNextMonth {
                    
                    monthsRainfallMM += self.DailyRainfallInM(day: day, month: nextMonth, year: simYear)
                }
                
            }
            
            displayArray.append(DisplayAnnualRain(year: simYear, annualRainMM: monthsRainfallMM))
            
        }
        
        
        return displayArray
    }
    
    func HistoricalRainfallForNext30Days() async  {
        
        // function that populates an array [[year, rain]] for past five years where rain is rainfall from the initial today to thirty days in future
        
        var tmpArray:[DisplayAnnualRain] = []
       
       
        
       DispatchQueue.main.async {
                    self.arrayPast30daysRainfall = []
                }
        
        // days in current month
        let today = Date()
        let startDay = Helper.DayFromDate(date: today)
        let endDayCurrentMonth = Helper.DayFromDate(date: today.endOfMonth())
        let currentMonth = Helper.MonthFromDate(date: today)
        
        // days in next month
        let daysToAdd = 30
        var dateComponent = DateComponents()
        dateComponent.day = daysToAdd
        let futureDate = Calendar.current.date(byAdding: dateComponent, to: today)!
        let startDayNextMonth = Helper.DayFromDate(date: futureDate.startOfMonth())
        let endDayNextMonth = Helper.DayFromDate(date: futureDate)
        let nextMonth = Helper.MonthFromDate(date: futureDate)
        
       
        
        var yearsToSim = ArrayOfLastFiveYearsWithDailyRainfall()
      
        // check if the current month is december and the next month is January of the next year
        if currentMonth == 12 && nextMonth == 1 {
            
            _ = yearsToSim.removeLast() // we remove the most recent year for which there is no Jan rainfall
           
        }
        
        var monthsRainfallMM = 0.0
        
        for simYear in yearsToSim {
            
            monthsRainfallMM = 0.0
            await dbContext.perform {
                for day in startDay...endDayCurrentMonth {
                    
                    monthsRainfallMM += self.DailyRainfallInM(day: day, month: currentMonth, year: simYear)
                   
                }
            }
            
            
        // if the final date falls in the next month
            
            if nextMonth != currentMonth {
                
                await dbContext.perform {
                    for day in startDayNextMonth...endDayNextMonth {
                        
                        monthsRainfallMM += self.DailyRainfallInM(day: day, month: nextMonth, year: simYear)
                    }
                }
                
                
            }
            
            self.totalRainfallmm = monthsRainfallMM
            
            print(simYear, totalRainfallmm)
            
            tmpArray.append(DisplayAnnualRain(year: simYear, annualRainMM: totalRainfallmm))
           
           /* DispatchQueue.main.async {
                
                self.arrayPast30daysRainfall.append(DisplayAnnualRain(year: simYear, annualRainMM: self.totalRainfallmm))
               
                    } */
           // arrayPast30days.append(DisplayAnnualRain(year: simYear, annualRainMM: totalRainfallmm))
            
        }
        
        DispatchQueue.main.async {
         //   self.arrayPast30daysRainfall = tmpArray
        }
        
    /*    DispatchQueue.main.async {
            self.avgRainMMForNext30Days = 0.0
            self.avgRainMMForNext30Days = self.totalRainfallmm / Double(numberOfYears)
            
            

                print("Average Rainfall for the next thirty days: \(self.avgRainMMForNext30Days) mm")
        } */
       
    }
    
    func DailyRainfallInM(day: Int, month: Int, year: Int) -> Double {
        
    
        // get the desired daily record from core data
        let dayPredicate = NSPredicate(format: "day=%i", day)
        let monthPredicate = NSPredicate(format: "month=%i", month)
        let yearPredicate = NSPredicate(format: "year=%i", year)
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [dayPredicate, monthPredicate, yearPredicate])
        
        let filterDailyRecord = self.dailyRainArrayCD.filter ({ record in
            
            compoundPredicate.evaluate(with: record)
            
        })
        
        // check if there is any record
        if filterDailyRecord.count != 0 {
           
           return filterDailyRecord[0].dailyRainMM
            
        } else {
            
            return 0.0 // assume no rainfall for the day for which record is not there
        }
        
        
    }
    
    func LatestYearForWhichRainRecordExsist() -> Int {
        
        
        // sort the records in descending order
        let descRainRecords = self.dailyRainArrayCD.sorted(by: {$0.year > $1.year})
        
        //descRainRecords = descRainRecords.sorted(by: {$0.month > $1.month})
        
       //descRainRecords = descRainRecords.sorted(by: {$0.day > $1.day})
        
        //first record has the latest year
        //print( "latest record is for year = ", descRainRecords[0].year, " month = ", descRainRecords[0].month, " day = ", descRainRecords[0].day)
        
        return Int(descRainRecords[0].year) // latest year for which daily rain records exsist
        
    }
    
    func EarliestYearForWhichRainRecordsExsist() -> Int {
        
        // sort the records in ascending order
        let ascendRainRecords = self.dailyRainArrayCD.sorted(by: {$0.year < $1.year})
        
        return Int(ascendRainRecords[0].year)
    }
    
    func UpdateDailyRainfallRecords(latitude: Double, longitude: Double) async throws {
        
        // to be called after five years rainfall records have been downloaded
        
        let latestYear = LatestYearForWhichRainRecordExsist()
        
        // find the current year
        
        let currentYear = Helper.CurrentYear()
        
        for year in latestYear + 1 ... currentYear - 1 {
            
            DispatchQueue.main.async {
                self.downloading = true
               self.arrayOfMonthRain = []
            }
            
            for month in 1...12 {

                DispatchQueue.main.async {
                    self.downloadMsg = "Downloading rainfall for \(Helper.intMonthToShortString(monthInt: month))-\(year)"
                }
                
                let result = try await FetchMonthlyRainInMM(month: month, year: year, latitude: latitude, longitude: longitude)
                
                // save result to core data
                
                DispatchQueue.main.async {
                    
                    self.arrayOfMonthRain.append(result)
                   // print(result)
                }
            }
            
            DispatchQueue.main.async {
                let annualRain = self.arrayOfMonthRain.reduce(0){ $0 + $1.monthRainMM}
                self.arrayOfAnnualRain.append(DisplayAnnualRain(year: year, annualRainMM: annualRain))
            }
            
        }
        
        DispatchQueue.main.async {
            self.downloading = false
            self.downloadMsg = "Your rainfall records have been updated."
        }
        
    }
    
    func DailyRecordExistsFor(day:Int, month: Int, year: Int) -> Bool {
        
        // create the predicates
        let dayPredicate = NSPredicate(format: "day=%i", day)
        let monthPredicate = NSPredicate(format: "month=%i", month)
        let yearPredicate = NSPredicate(format: "year=%i", year)
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [dayPredicate, monthPredicate, yearPredicate])
        
        let filterDailyRecord = self.dailyRainArrayCD.filter ({ record in
            
            compoundPredicate.evaluate(with: record)
            
        })
        
        // check if there is any record for this date
        if filterDailyRecord.count == 0 {
            return false
        } else {
            return true
        }
        
    }
    
    func DoWeHaveAlltheRecordsForTheYear(year: Int) -> Bool {
        
        // find number of days in the given year
        let numberOfDays = Helper.NumberOfDaysInYear(year: year)
        
        // find all the records with give year
        // find all dailyrain records with the given year
        let yearPredicate = NSPredicate(format: "year=%i", year)
        
        // apply the filter
        let dayForYearArray = self.dailyRainArrayCD.filter( {
            day in
            yearPredicate.evaluate(with: day)
        })
        
        // count the days
        let numberOfDaysWithRecord = dayForYearArray.count
        
        if numberOfDays == numberOfDaysWithRecord {
            return true
        } else {
            return false
        }
        
    }
    
    /// Returns all the years for which we have  daily rainfall records
    /// - Returns: An array of years
    func ArrayOfYearsWithDailyRainfall() -> [Int] {
        
        let  initialYear = self.EarliestYearForWhichRainRecordsExsist()
        let finalYear = self.LatestYearForWhichRainRecordExsist()
        
        var yearArray:[Int] = []
        
        for year in initialYear...finalYear {
            // check if all the recrds exist for the year
            if DoWeHaveAlltheRecordsForTheYear(year: year) {
                yearArray.append(year)
            }
           
        }
        
        return yearArray
    }
    
    
    /// A function that returns the last five years for which daily rainfall records exist.
    /// If the number of years for which the daily rainfall record exist is less than five
    /// then it returns all the years for wich the daily rainfall record exist.
    /// - Returns: An integer array of years
    func ArrayOfLastFiveYearsWithDailyRainfall() -> [Int] {
        
        // Get array of all the years for which there is daily rainfall records
        let yearArray = ArrayOfYearsWithDailyRainfall()
        
        if yearArray.count > 5 {
                let startIndex = yearArray.count - 5
                return Array(yearArray[startIndex..<yearArray.count])
            } else {
                return yearArray
            }
        
    }
    
    enum DownloadError: Error {
        
        case invalidServerResponse
        case noResult
        
    }
    
}

extension DownloadRainfallFromVC {
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        guard let fetchedRainfall = controller.fetchedObjects as? [DailyRainVC] else {
            return
        }
        dailyRainArrayCD = fetchedRainfall
    }
    
}


// model for storing decoded JSON data from Visual Crossing
struct VCdailyRain: Decodable {
    let datetime : String
    let precip : Double?
    
    // computed properties to extract year, month and day from datetime
    // datetime e.g:2021-12-01
    
    var year: Int32 {
        let yearString = datetime.dropLast(6)
        return Int32(yearString)!
    }
    
    var month: Int32 {
        let start = datetime.index(datetime.startIndex, offsetBy: 5)
        let end = datetime.index(datetime.endIndex, offsetBy: -3)
        let range = start..<end
        let subString = datetime[range]
        return Int32(subString)!
    }
    
    var day: Int32 {
        let dayString = datetime.dropFirst(8)
        return Int32(dayString)!
    }
}

struct VCrainData: Decodable {
    let days : [VCdailyRain]
}

struct DisplayDailyRain: Identifiable {
    let id = UUID()
    let day : Int32
    let month : Int32
    let year : Int32
    let rainMM : Double
}

struct DisplayMonthRain: Identifiable {
    let id = UUID()
    let month : Int
    let year : Int
    let monthRainMM : Double
    
}

struct DisplayAnnualRain: Identifiable {
    let id = UUID()
    let year : Int
    let annualRainMM : Double
}

