//
//  SimTankaVC.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 05/12/22.
//
/// Main model for simulations using rainfall data
/// obtained via Visual Crossing API
/// Released under
/// GNU General Public License v3.0 or later
/// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import Foundation
import SwiftUI
import CoreData

/// Main model for simulating rainwater harvesting systems with covered storage tank
class SimTankaVC: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    @AppStorage("baseYear") private var baseYear = 0
    
    // rainfall data from Coredata
    private let dailyRainController: NSFetchedResultsController<DailyRainVC>
    private let dbContext: NSManagedObjectContext
    
    // daily rainfall records stored in CoreData
    var dailyRainArrayCD : [DailyRainVC] = []
    
    // for displaying results in RWHS view
    @Published var displayResults:[EstimateResult] = []
    
    // for performance of the RWHS
    @Published var performanceMsg = String()
    @Published var performanceSim = false
    @Published var simIsFinished = false
    @Published var performanceProgress = Double()
    @Published var reliabilityOfCurrentSystem = String()
    
    // for suggestion to the user
    @Published var suggestionMsg = String()
    @Published var optimumTankFound = false
    @Published var optimumTank = EstimateResult(tanksizeM3: 100.0, annualSuccess: 0) // initialising
    
    var counter = 0
    
    // Cancellation token for the simulation task
    @Published var simulationCancellationToken: Task<Void, Never>?
    private var didEnterBackgroundNotificationTask: Task<Void, Never>?
    @Published var cancelSim = false
    
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
        
        
    }
    
    func PerformanceForTankSizes(myTanka: SimInput) async {
        
        let userTankSizeM3 = myTanka.tankSizeM3
        let deltaTank = userTankSizeM3 * 0.25
        var trialTanka = myTanka
        // trying out two different sizes of tank
        let numberOfNewTankSize = 1 // will simulate three sizes starting with the users size
        
        DispatchQueue.main.async {
            self.counter = 0
            self.performanceProgress = 10.0 // initial
            self.displayResults = []
            self.performanceMsg = "Please wait, working hard!"
            self.performanceSim = true
        }
        
       
        
        for tankStep in -1...numberOfNewTankSize {
            
            let tankSizeM3 = userTankSizeM3 + Double(tankStep) * deltaTank
            trialTanka.tankSizeM3 = tankSizeM3
            
            let success = ProbabilityOfSuccess(myTanka: trialTanka)
           
            // for research
           // let avgSuccess = ProbabilityOfSuccessUsingDailyAverageRainfall(myTanka: trialTanka)
           // print("Tank size in cubic meter = ", tankSizeM3, "Succ based on avg daily rainfall = ", Int(avgSuccess * 100 ))
            // end research
            
            
            
           let estimateSucc = EstimateResult(tanksizeM3: tankSizeM3, annualSuccess: Int(success * 100))
            DispatchQueue.main.async {
                self.counter += 1
                self.performanceProgress = (Double(self.counter) / Double((numberOfNewTankSize + 2))) * 100
                self.displayResults.append(estimateSucc)
            }
        }
        
        DispatchQueue.main.async {
            self.performanceSim = false
        }
        
    }
    
    func ProbabilityOfSuccess(myTanka: SimInput) -> Double {
        
        /// Main function for estimating reliability of the RWHS
        
        let runOff = myTanka.runOff
        let catchAreaM2  = myTanka.catchAreaM2
        let userTankSizeM3 = myTanka.tankSizeM3
        let dailyDemandArrayM3 = myTanka.dailyDemands
        
        var waterInTankToday = 0.0
        var waterInTankYesterday = 0.0
        
        var daysUsed = 0 // number of days tanka is used
        var succDays = 0 // number of successful days
        
        
       // let yearsToSim = Helper.PastFiveYearsFromBaseYear(baseYear: baseYear)
        let yearsToSim = self.ArrayOfYearsWithDailyRainfall()
        
        for year in yearsToSim {
            
            for month in 1...12 {
                
                for day in 1...Helper.DaysIn(month: month, year: year) {
                    
                    // water harvested on the day
                    waterInTankToday = DailyWaterHarvestedM3(day: day, month: month, year: year, runOff: runOff, catchAreaM2: catchAreaM2) + waterInTankYesterday
                   
                    // water harvested cannot be larger than the tank size
                    waterInTankToday = min(waterInTankToday, userTankSizeM3)
                    
                    let dailyDemand = dailyDemandArrayM3[month - 1]
                    
                    if dailyDemand != 0.0 {
                        daysUsed = daysUsed + 1
                        waterInTankToday = waterInTankToday - dailyDemand
                        if waterInTankToday >= 0 {
                            succDays = succDays + 1
                        } else {
                            waterInTankToday = 0 // tank is empty
                        }
                    }
                    
                    // prepare for tomorrow
                    waterInTankYesterday = waterInTankToday
                    
                    
                }
                
            } // month loop
            
        }
        
        // probability of success
        
        let probSucc = Double(succDays) / Double(daysUsed)
        
        return probSucc
    }
    
    func DailyWaterHarvestedM3(day:Int, month:Int, year:Int, runOff: Double, catchAreaM2: Double) -> Double {
        // month 1 = Jan
        // month 12 = Dec
        
        var waterHarvested = 0.0
        
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
           
            waterHarvested = filterDailyRecord[0].dailyRainMM * 0.001 * catchAreaM2 * runOff
        } else {
            
            waterHarvested = 0 // assume no rainfall for the day for which record is not there
        }
        
       // print( day, month, year, waterHarvested)
        return waterHarvested
    }
    
    func
    ProbabilityOfSuccessUsingDailyAverageRainfall (myTanka: SimInput) -> Double {
        
        let runOff = myTanka.runOff
        let catchAreaM2  = myTanka.catchAreaM2
        let userTankSizeM3 = myTanka.tankSizeM3
        let dailyDemandArrayM3 = myTanka.dailyDemands
        
        var waterInTankToday = 0.0
        var waterInTankYesterday = 0.0
        
        var daysUsed = 0 // number of days tanka is used
        var succDays = 0 // number of successful days
        
        let year = Helper.CurrentYear()
        
        for month in 1...12 {
            
            for day in 1...Helper.DaysIn(month: month, year: year) {
                
                // water harvested on the day
                waterInTankToday = AverageDailyWaterHarvestedM3(day: day, month: month,  runOff: runOff, catchAreaM2: catchAreaM2) + waterInTankYesterday
                
                // water harvested cannot be larger than the tank size
                waterInTankToday = min(waterInTankToday, userTankSizeM3)
                
                let dailyDemand = dailyDemandArrayM3[month - 1]
                
                if dailyDemand != 0.0 {
                    daysUsed = daysUsed + 1
                    waterInTankToday = waterInTankToday - dailyDemand
                    if waterInTankToday >= 0 {
                        succDays = succDays + 1
                    } else {
                        waterInTankToday = 0 // tank is empty
                    }
                }
                
                // prepare for tomorrow
                waterInTankYesterday = waterInTankToday
                
            }
        }
        
        // probability of success
        
        let probSucc = Double(succDays) / Double(daysUsed)
        
        return probSucc
    }
    
    func OptimumTankSizeUsingAverageDailyRainfall(myTanka:SimInput) async -> Double {
        
        // start with a tank size of 1 cubic meter
        var trialTanka = SimInput(runOff: myTanka.runOff, catchAreaM2: myTanka.catchAreaM2, tankSizeM3: myTanka.tankSizeM3, dailyDemands: myTanka.dailyDemands)
        
        // initial success
        var initialSuccess = ProbabilityOfSuccessUsingDailyAverageRainfall(myTanka: trialTanka)
        
        // increase tanks size by 1 meter cube till probability of success
        // does not change.
        
        let deltaTanka = 1.0
        
        var finalSuccess = 0.0
        
        // start displaying simulation in the UI
        DispatchQueue.main.async {
            self.performanceSim = true
        }
        
        while (true) {
           
            
            trialTanka.tankSizeM3 = trialTanka.tankSizeM3 + deltaTanka
            finalSuccess = ProbabilityOfSuccessUsingDailyAverageRainfall(myTanka: trialTanka)
            if ((finalSuccess - initialSuccess) < 0.000001) {
                print(trialTanka.tankSizeM3, finalSuccess) // testing
                break
            }
            initialSuccess = finalSuccess
            print(trialTanka.tankSizeM3, finalSuccess) // testing
        }
        
        DispatchQueue.main.async {
            self.performanceSim = false
        }
        
        return trialTanka.tankSizeM3
    }
    
   
    func TankSizesForBudget(myTanka: SimInput) async {
        
       
        // starts with the maximum tank size the user can afford
        
        let maxTankM3 = myTanka.tankSizeM3 // provided by the user
        
        // reduce tank size by a factor of 10 each time
        // till we reach half of the maxTank
        
        let deltaTankM3 = maxTankM3/10.0
        
        var trialTanka = myTanka // for different tank sizes
        
        // for updating the display
        
        DispatchQueue.main.async {
            self.counter = 0
            self.performanceProgress = 10.0 // initial
            self.displayResults = []
            self.performanceMsg = "Please wait, working hard!"
            self.performanceSim = true
            self.simIsFinished = false
        }
        
        let numberOfTankSizesSimulated = 6
        
        for tankStep in 0...5 {
            
            if cancelSim {
               // print("Some one cancelled the task")
                break
            }
            
            let tankSizeM3 = maxTankM3 - Double(tankStep) * deltaTankM3
            trialTanka.tankSizeM3 = tankSizeM3
            let success = ProbabilityOfSuccess(myTanka: trialTanka)
            
            // update UI
            let estimateSucc = EstimateResult(tanksizeM3: tankSizeM3, annualSuccess: Int(success * 100))
            
             DispatchQueue.main.async {
                 self.counter += 1
                 self.performanceProgress = (Double(self.counter)) / Double(numberOfTankSizesSimulated) * 100
                 self.displayResults.append(estimateSucc)
             }
        }
        
        // analyse the result
        
        DispatchQueue.main.async { [self] in
            self.suggestTankSize(results: displayResults)
            self.performanceSim = false
            self.simIsFinished = true
        }
    }
    
    func suggestTankSize (results: [EstimateResult])  {
        
        // a simple expert system to guide the user towards
        // minimum tank size with max reliability
        
        // initialise the msg
        self.suggestionMsg = ""
        self.optimumTankFound = false
        
        // check if we are in asymptotic region
        if self.allElementsHaveSameAnnualSuccess(in: results) {
            // we are in the asymptotic region
            
            // check if the max success rate is >= 90 %
            if self.maximumReliability(displayResults: results)! > 89 {
                
                self.suggestionMsg = "You can meet your waterdemands with smaller tank sizes. Explore smaller tank sizes by reducing your tank budget."
               // print("There is no need for such large tank size for your water budget. Explore smaller tank size by assigining smaller budget.")
               // print(" Smallest tank size = ", filterAndFindSmallest(results: results)!)
            } else {
                
                // increasing tank size is not helping
                self.suggestionMsg = "Your water budget is too large."
               // print("Your water budget is too large, consider reducing your water dependency of your RWHS")
            }
            

        }
      
        
        // we are in the transition region
        
        if inTransientRegion(estimates: results) {
            
            
          
            // check if success rate greater than 89%
            if self.maximumReliability(displayResults: results)! > 89 {
                self.suggestionMsg = "SimTanka has found an optimum tank size! Tap to save it. "
                self.optimumTankFound = true
                self.optimumTank = findElementWithSmallestTanksizeM3(in: results)!
            } else {
                self.suggestionMsg = "Consider reducing your water demand."
            }
            
        }
        
        // we are in the increasing region
        
        if isAnnualSuccessIncreasingWithTankSize(estimates: results) {
            
            // find the element of the array with max success and smallest tank size
            
            
            
            if self.maximumReliability(displayResults: results)! > 89 {
                // find the tank size with success rate greater than 89 but with smallest tank size
                self.suggestionMsg = "SimTanka has found an optimum tank size! Tap to save it."
                self.optimumTankFound = true
                self.optimumTank = findElementWithSmallestTanksizeM3(in: results)!
                
            } else {
               
                self.suggestionMsg = "You can improve the reliability of your system by considering larger tank size."
            }
            
        }
        
       
        
    }
    
    func inTransientRegion(estimates: [EstimateResult]) -> Bool {
        // Create a set of the annualSuccess values in the array.
        let annualSuccessSet = Set(estimates.map { $0.annualSuccess })

        // Return true if the set has more than one element, false otherwise.
        return annualSuccessSet.count > 1
    }

    func findElementWithSmallestTanksizeM3(in estimateResults: [EstimateResult]) -> EstimateResult? {
      // Create a new array with elements that have the maximum value of annualSuccess.
      let maxAnnualSuccess = estimateResults.max(by: { $0.annualSuccess < $1.annualSuccess })?.annualSuccess
      guard let maxAnnualSuccess = maxAnnualSuccess else { return nil }

      let filteredEstimateResults = estimateResults.filter { $0.annualSuccess == maxAnnualSuccess }

      // Find the element with the smallest value of tanksizeM3.
      let smallestTanksizeM3Element = filteredEstimateResults.min(by: { $0.tanksizeM3 < $1.tanksizeM3 })

      return smallestTanksizeM3Element
    }

    func isAnnualSuccessIncreasingWithTankSize(estimates: [EstimateResult]) -> Bool {
        // Sort the estimates by tank size.
        let sortedEstimates = estimates.sorted { $0.tanksizeM3 < $1.tanksizeM3 }

        // Iterate over the sorted estimates and check if the annualSuccess value is increasing.
        for i in 1..<sortedEstimates.count {
            if sortedEstimates[i].annualSuccess <= sortedEstimates[i - 1].annualSuccess {
                return false
            }
        }

        // If we reach this point, then the annualSuccess value is increasing with tank size.
        return true
    }

    
    func allElementsHaveSameAnnualSuccess(in array: [EstimateResult]) -> Bool {
      // Get the annual success of the first element in the array.
      let firstElementAnnualSuccess = array[0].annualSuccess

      // Iterate over the rest of the array and check if each element has the same annual success as the first element.
      for element in array {
        if element.annualSuccess != firstElementAnnualSuccess {
          return false
        }
      }

      // If we reach this point, then all elements in the array have the same annual success.
      return true
    }

    func maximumReliability(displayResults: [EstimateResult]) -> Int? {
        guard let maxReliability = displayResults.map({ $0.annualSuccess }).max() else {
            return nil // Return nil if the array is empty
        }

        return maxReliability
    }

    func filterAndFindSmallest(results: [EstimateResult]) -> Double? {
        // Filter elements with success rate > 89%
        
        // Filter the results to only include objects with a success rate greater than 89%.
        let filteredResults = results.filter { (estimateResult: EstimateResult) -> Bool in
            return estimateResult.annualSuccess > 89
        }


        // Find the element with the smallest tank size
        let smallestTankSizeResult = filteredResults.min { $0.tanksizeM3 < $1.tanksizeM3 }

        return smallestTankSizeResult?.tanksizeM3
    }

    func isReliabilityIncreasing(displayResults: [EstimateResult]) -> Bool {
        guard displayResults.count > 1 else {
            // Not enough data to determine the trend
            return false
        }

        for i in 1..<displayResults.count {
            let previousReliability = displayResults[i - 1].annualSuccess
            let currentReliability = displayResults[i].annualSuccess

            if currentReliability <= previousReliability {
                // Reliability is not increasing, so return false
                return false
            }
        }

        // If the loop completes without returning, reliability is increasing
        return true
    }

  
    func TaskForTankForBudget(myTanka: SimInput) async {
        
        let simulationTask = Task {
            await TankSizesForBudget(myTanka:myTanka)
        }
        
        // Assign the task to the simulationCancellationToken property.
        DispatchQueue.main.async {
            self.simulationCancellationToken = simulationTask
        }
              
    }
    
    func cancelSimulation() {
            // Check if there's a task to cancel.
            if let cancellationToken = simulationCancellationToken {
               
                // Call the cancel method on the task.
                cancellationToken.cancel()
                
                print("SimTankaVC task cancelled")
                // Optionally set the property to nil if you don't need it anymore.
                simulationCancellationToken = nil
            }
        }
    
    @MainActor
    func cleanUp() {
          //  print("Should clean up before simulation starts")
        self.counter = 0
        self.performanceProgress = 10.0 // initial
        self.displayResults = []
       // self.performanceMsg = "Please wait, working hard!"
       // self.performanceSim = true
       // self.simIsFinished = false
          // didEnterBackgroundNotificationTask?.cancel()
       }

    func startMonitoringNotificationCenter() {
        didEnterBackgroundNotificationTask = Task {
            for await _ in await NotificationCenter.default.notifications(named: UIApplication.didEnterBackgroundNotification) {
                print("we disappearedd")
                didEnterBackground()
                cancelSimulation()
            }
        }
    }

    func EstimateReliabilityOfUsersRWHS(myTanka: SimInput) async {
        
        // for updating the display
        
        DispatchQueue.main.async {
            self.counter = 0
            self.performanceProgress = 10.0 // initial
            self.displayResults = []
            self.performanceMsg = "Please wait, working hard!"
            self.performanceSim = true
            self.simIsFinished = false
        }
        
        let success = ProbabilityOfSuccess(myTanka: myTanka)
        
        // update UI
        let estimateSucc = EstimateResult(tanksizeM3: myTanka.tankSizeM3, annualSuccess: Int(success * 100))
        
         DispatchQueue.main.async {
             
             self.displayResults.append(estimateSucc)
             self.reliabilityOfCurrentSystem = Helper.LikelyHoodProbFrom(reliability: self.displayResults[0].annualSuccess)
             self.performanceSim = false
             self.simIsFinished = true
         }
        
    }
    private func didEnterBackground() {
        
    }

}

extension SimTankaVC {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        guard let fetchedRainfall = controller.fetchedObjects as? [DailyRainVC] else {
            return
        }
        dailyRainArrayCD = fetchedRainfall
    }
    
    func EarliestYearForWhichRainRecordsExsist() -> Int {
        
        // sort the records in ascending order
        let ascendRainRecords = self.dailyRainArrayCD.sorted(by: {$0.year < $1.year})
        
        return Int(ascendRainRecords[0].year)
    }
    
    func LatestYearForWhichRainRecordExist() -> Int {
        
        // sort the records in descending order
        let descRainRecords = self.dailyRainArrayCD.sorted(by: {$0.year > $1.year})
        
        return Int(descRainRecords[0].year) // latest year for which daily rain records exsist
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
        let finalYear = self.LatestYearForWhichRainRecordExist()
        
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
    
    /// Returns the average daily rainfall of a given day in a given month, averaged over the yers of downloaded daily rainfall records
    /// - Parameters:
    ///   - day: The day for which the average  daily rainfall is returned
    ///   - month: Month for  which the average  daily rainfall is returned
    /// - Returns: Average daily rainfall for day-month
    func AverageDailyRainfallInMeter (day: Int, month: Int) -> Double {
        
        let yearArray = self.ArrayOfYearsWithDailyRainfall()
        
        guard !yearArray.isEmpty else { return 0.0 }
        
       // let currentYear = Helper.CurrentYear()
        
        // calculate average daily rainfall for the current year
        
        var dailyRainM = 0.0
        
        for year in yearArray {
            
            dailyRainM = dailyRainM + self.DailyRainfallInMFor(day: day, month: month, year: year)
            
        }
        
        return dailyRainM / Double(yearArray.count)
    }
    
    func DailyRainfallInMFor(day:Int, month: Int, year: Int) -> Double {
        
        // get the desired daily record from core data
        let dayPredicate = NSPredicate(format: "day=%i", day)
        let monthPredicate = NSPredicate(format: "month=%i", month)
        let yearPredicate = NSPredicate(format: "year=%i", year)
        
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [dayPredicate, monthPredicate, yearPredicate])
        
        let filterDailyRecord = self.dailyRainArrayCD.filter ({ record in
            
            compoundPredicate.evaluate(with: record)
            
        })
        
        var dailyRainInM = 0.0
        
        // check if we have a record
        if filterDailyRecord.count != 0 {
           
            dailyRainInM = filterDailyRecord[0].dailyRainMM * 0.001
        } else {
            
            dailyRainInM = 0 // assume no rainfall for the day for which record is not there
        }
        
        
        return dailyRainInM
        
    }
    
    func AverageDailyWaterHarvestedM3(day: Int, month:Int, runOff: Double, catchAreaM2: Double) -> Double {
        
        
        return AverageDailyRainfallInMeter(day: day, month: month) * runOff * catchAreaM2
    }
}

struct EstimateResult: Hashable, Identifiable {
    let tanksizeM3: Double
    let annualSuccess: Int
    let id = UUID()
}
