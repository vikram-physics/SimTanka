//
//  PerformanceModel.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 03/05/22.
//  Modified for rainfall data from Visual Crossing
/// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import Foundation
import SwiftUI
import CoreData

class PerformanceModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    
    @AppStorage("baseYear") private var baseYear = 0
    
    // base year is year from which the records are kept
    // it is setup in setupLocationView - five years in past
    
    @AppStorage("runOff") var runOff = 0.0
    @AppStorage("catchAreaM2") private var catchAreaM2 = 0.0
    @AppStorage("tankSizeM3") private var tankSizeM3 = 0.0
    
    
    @Published var waterInTankAtStart = 0.0 // water in the tank at the beginning - to be obtained from performance view
    
    @Published var numberOfMonthsInFuture = 3 // estimating future performance for next numberOfMontsInFuture
    
    @Published var arrayPast30daysRainfall:[DisplayAnnualRain] = []
    var totalRainfallmm = 0.0
    
    // rainfall data from Coredata
    private let dailyRainController: NSFetchedResultsController<DailyRainVC>
   
     private let demandController: NSFetchedResultsController<WaterDemand>
     private let dbContext: NSManagedObjectContext
     
    // daily rainfall records stored in CoreData
    var dailyRainArrayCD : [DailyRainVC] = []
    
    // water budget from core data
    var dailyDemandArray: [WaterDemand] = []
    
    
    
     init(managedObjectContext: NSManagedObjectContext) {
         
         let fetchDailyRainfall:NSFetchRequest<DailyRainVC> = DailyRainVC.fetchRequest()
         fetchDailyRainfall.sortDescriptors = [NSSortDescriptor(key: "year", ascending: true)]
         
         dailyRainController = NSFetchedResultsController(fetchRequest: fetchDailyRainfall, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
         
         let fetchDailyDemand:NSFetchRequest<WaterDemand> = WaterDemand.fetchRequest()
         fetchDailyDemand.sortDescriptors = [NSSortDescriptor(key: "month", ascending: true)]
         demandController = NSFetchedResultsController(fetchRequest: fetchDailyDemand, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
         
         self.dbContext = managedObjectContext
         super.init()
         
         dailyRainController.delegate = self
         demandController.delegate = self
         
         // fetch the stored data
         
         do {
             try dailyRainController.performFetch()
             dailyRainArrayCD = dailyRainController.fetchedObjects ?? []
            
         } catch {
             print("Could not fetch daily rainfall records")
         }
         
         do {
             try demandController.performFetch()
             dailyDemandArray = demandController.fetchedObjects ?? []
         } catch {
             print("Could ot fetch daily water demand")
         }
     }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        guard let fetchedRainfall = controller.fetchedObjects as? [DailyRainVC] else {
            return
        }
        dailyRainArrayCD = fetchedRainfall
        //print(dailyRainInMMarray.count)
    }
   
    func waterHarvestedForCurrentMonth()  async -> ProbableAmount {
        
        let today = Date()
        let startDay = Helper.DayFromDate(date: today)
        let endDay = Helper.DayFromDate(date: today.endOfMonth())
       
        let month = Helper.MonthFromDate(date: today)
        
        
        var waterHarvestedInM3 = 0.0
        var results:[Double] = []
        let yearsToSim = Helper.PastFiveYearsFromBaseYear(baseYear: baseYear)
        for simYear in yearsToSim {
            
            waterHarvestedInM3 = 0.0
            
            for day in startDay...endDay {
                
                let waterHarvestedOnDay = DailyWaterHarvestedM3(day: day, month: month, year: simYear, runOff: runOff, catchAreaM2: catchAreaM2)
                
                waterHarvestedInM3 = waterHarvestedInM3 + waterHarvestedOnDay
                
                if waterHarvestedInM3 > tankSizeM3 {
                    waterHarvestedInM3 = tankSizeM3
                }
                
                
            }
            results.append(waterHarvestedInM3)
        
        }
        
        // find the minimum water harvested
        let minHarvest = results.min()
        
        // find the probability
        let probability = Int(Float(yearsToSim.count - 1) / Float(yearsToSim.count) * 100)
        
        var probableAmount = ProbableAmount()
        probableAmount.probability = probability
        probableAmount.waterInTankM3 = minHarvest!
        
        return probableAmount
        
    }
    
    func waterInTankForCurrentMonth(initialAmount:Double) async -> ProbableAmount {
        
        let today = Date()
        let startDay = Helper.DayFromDate(date: today)
        let endDay = Helper.DayFromDate(date: today.endOfMonth())
        let pastYears = Helper.PastFiveYearsFromBaseYear(baseYear: baseYear)
        let month = Helper.MonthFromDate(date: today)
        
        
        var waterInTankM3 = 0.0
        var results:[Double] = []
        
        for simYear in pastYears {
            
            waterInTankM3 = initialAmount
           
            
            for day in startDay...endDay {
                
                
                let waterHarvestedOnDay = DailyWaterHarvestedM3(day: day, month: month, year: simYear, runOff: runOff, catchAreaM2: catchAreaM2)
                                
                waterInTankM3 = waterInTankM3 + waterHarvestedOnDay - dailyDemandArray[month-1].dailyDemandM3
                
                if waterInTankM3 < 0 {
                    waterInTankM3 = 0.0 // tank is empty
                }
                
                if waterInTankM3 > tankSizeM3 {
                    waterInTankM3 = tankSizeM3
                }
                
                
            }
            results.append(waterInTankM3)
        }
        // find the minimum water harvested
        let minHarvest = results.min()
        
        // find the probability
        let probability = Int((Double(pastYears.count - 1 ) / Double(pastYears.count)) * 100)
        
        var probableAmount = ProbableAmount()
        probableAmount.probability = probability
        probableAmount.waterInTankM3 = minHarvest!

        return probableAmount
    }
    
    func waterHarvestedForMonth(month:Int, year:Int, initialAmount: Double) -> ProbableAmount {
        
        
        let pastYears = Helper.PastFiveYearsFromBaseYear(baseYear: baseYear)
        
        var waterHarvestedInM3 = 0.0
        var dailyWaterHarvestedInM3 = 0.0
        var results:[Double] = []
        
        for simYear in pastYears {
            
            waterHarvestedInM3 = initialAmount
            let daysInMonth = Helper.DaysIn(month: month, year: simYear)
            
            for day in 1...daysInMonth {
                
                dailyWaterHarvestedInM3 = DailyWaterHarvestedM3(day: day, month: month, year: simYear, runOff: runOff, catchAreaM2: catchAreaM2)
                
                waterHarvestedInM3 = waterHarvestedInM3 + dailyWaterHarvestedInM3
                
                if waterHarvestedInM3 > tankSizeM3 {
                    waterHarvestedInM3 = tankSizeM3
                }
                
                
            }
            results.append(waterHarvestedInM3)
        
        }
        
        // find the minimum water harvested
        let minHarvest = results.min()
        
        // find the probability
        let probability = Int((pastYears.count - 1 / pastYears.count) * 100)
        
        var probableAmount = ProbableAmount()
        probableAmount.probability = probability
        probableAmount.waterInTankM3 = minHarvest!
        
        return probableAmount
        
    }
    
    func waterInTankForMonth(month:Int, year:Int, initialAmount: Double, dailyDemand: Double) -> ProbableAmount {
        
        
        let pastYears = Helper.PastFiveYearsFromBaseYear(baseYear: baseYear)
        
        var waterInTankM3 = 0.0
        var dailyWaterHarvestedInM3 = 0.0
        var results:[Double] = []
        
        for simYear in pastYears {
            
            waterInTankM3 = initialAmount
            let daysInMonth = Helper.DaysIn(month: month, year: simYear)
            for day in 1...daysInMonth {
                
                dailyWaterHarvestedInM3 = DailyWaterHarvestedM3(day: day, month: month, year: simYear, runOff: runOff, catchAreaM2: catchAreaM2)
                
                waterInTankM3 = waterInTankM3 + dailyWaterHarvestedInM3 - dailyDemand
                
                if waterInTankM3 > tankSizeM3 {
                    waterInTankM3 = tankSizeM3
                }
                
                
            }
            results.append(waterInTankM3)
        }
        // find the minimum water harvested
        let minHarvest = results.min()
        
        // find the probability
        let probability = Int((pastYears.count - 1 / pastYears.count) * 100)
        
        var probableAmount = ProbableAmount()
        probableAmount.probability = probability
        probableAmount.waterInTankM3 = minHarvest!
        
        return probableAmount
    }
    
   
}

extension PerformanceModel {
    
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
    
   
    func WaterInTankMonthPlus(todaysAmount: Double) async -> ProbableAmount {
        
        let todayPlusOneMonth = Helper.AddOrSubtractMonth(month: 1)
        let startDay = Helper.DayFromDate(date: todayPlusOneMonth.startOfMonth())
        let endDay = Helper.DayFromDate(date: todayPlusOneMonth.endOfMonth())
        let month = Helper.MonthFromDate(date: todayPlusOneMonth)
        let pastYears = Helper.PastFiveYearsFromBaseYear(baseYear: baseYear)
        
        // estimate the water in tank at the begining of the month
        let initialAmountEstimate = await self.waterInTankForCurrentMonth(initialAmount: todaysAmount).waterInTankM3
        
        var waterInTankM3 = 0.0
        var results:[Double] = []
        
        for simYear in pastYears {
            
            waterInTankM3 = initialAmountEstimate
           
            
            for day in startDay...endDay {
                
                
                let waterHarvestedOnDay = DailyWaterHarvestedM3(day: day, month: month, year: simYear, runOff: runOff, catchAreaM2: catchAreaM2)
                                
                waterInTankM3 = waterInTankM3 + waterHarvestedOnDay - dailyDemandArray[month-1].dailyDemandM3
                
                if waterInTankM3 < 0 {
                    waterInTankM3 = 0.0 // tank is empty
                }
                
                if waterInTankM3 > tankSizeM3 {
                    waterInTankM3 = tankSizeM3
                }
                
                
            }
            results.append(waterInTankM3)
        }
        // find the minimum water harvested
        let minHarvest = results.min()
        
        // find the probability
        let probabilityOfInitialAmount = await Double(self.waterInTankForCurrentMonth(initialAmount: todaysAmount).probability) / 100.0 // converting from percentage
        let probabilityOfSuccess =  (Double(pastYears.count - 1 ) / Double(pastYears.count))// find the probability
        
        let combinedProbability = probabilityOfInitialAmount * probabilityOfSuccess
        
        let probability = Int(combinedProbability * 100 )
        var probableAmount = ProbableAmount()
        probableAmount.probability = probability
        probableAmount.waterInTankM3 = minHarvest!

        return probableAmount
    }
    

    func ReliabilityForFuture30Days(intialAmountM3: Double)async -> Int {
        
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
        
        //
        
        var numberOfSimDays = 0
        var sucsessSimDays = 0
        
        var waterInTankToday = 0.0
        var waterInTankYesterday = 0.0
        
        let yearsToSim = Helper.PastFiveYearsFromBaseYear(baseYear: baseYear)
        
        for simYear in yearsToSim {
            
            // start with the amount of water measured by the user
            waterInTankYesterday = intialAmountM3
            
            // first simulate over the current month
           
            for day in startDay...endDayCurrentMonth {
                
                waterInTankToday = DailyWaterHarvestedM3(day: day, month: currentMonth, year: simYear, runOff: runOff, catchAreaM2: catchAreaM2) + waterInTankYesterday
                
                // water harvested cannot be greater than the tank size
                waterInTankToday = min(waterInTankToday, tankSizeM3)
                
                let dailyDemand = dailyDemandArray[currentMonth-1].dailyDemandM3
                
                if dailyDemand != 0.0 {
                    // update the counter
                    numberOfSimDays = numberOfSimDays + 1
                    waterInTankToday = waterInTankToday - dailyDemand
                    if waterInTankToday >= 0.0 {
                        sucsessSimDays = sucsessSimDays + 1
                    } else {
                        waterInTankToday = 0.0 // tank is empty
                    }
                }
            
                // prepare for tomorrow
                waterInTankYesterday = waterInTankToday
                
            }
            
            // if the final date falls in the next month then only
            if nextMonth != currentMonth {
                for day in startDayNextMonth...endDayNextMonth {
                    waterInTankToday = DailyWaterHarvestedM3(day: day, month: nextMonth, year: simYear, runOff: runOff, catchAreaM2: catchAreaM2) + waterInTankYesterday
                   
                    // water harvested cannot be greater than the tank size
                    waterInTankToday = min(waterInTankToday, tankSizeM3)
                    
                    let dailyDemand = dailyDemandArray[nextMonth-1].dailyDemandM3
                    
                    if dailyDemand != 0.0 {
                        // update the counter
                        numberOfSimDays = numberOfSimDays + 1
                        waterInTankToday = waterInTankToday - dailyDemand
                        if waterInTankToday >= 0.0 {
                            sucsessSimDays = sucsessSimDays + 1
                        } else {
                            waterInTankToday = 0.0 // tank is empty
                        }
                    }
                   
                    // prepare for tomorrow
                    waterInTankYesterday = waterInTankToday
                    
                }
            }
        }
        
        // calculate reliability
        return Int(Float(sucsessSimDays) / Float(numberOfSimDays) * 100)
    }
    
    func FuturePerformance30Days(initialAmountM3: Double) async -> DisplayPerformance {
        
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
        
        // check if the current month is december and the next month is January of the next year
        var yearsToSim = ArrayOfYearsWithDailyRainfall() //Helper.PastFiveYearsFromBaseYear(baseYear: baseYear)
      

        if currentMonth == 12 && nextMonth == 1 {
            _ = yearsToSim.removeLast() // we remove the most recent year for which there is no Jan rainfall
           
        }
        
        var numberOfSimDays = 0
        var sucsessSimDays = 0
        
        var waterInTankToday = 0.0
        var waterInTankYesterday = 0.0
        
        var waterAtTheEndOfSimArray:[Double] = []
        
        for simYear in yearsToSim {
            
            // start with the amount of water measured by the user
            waterInTankYesterday = initialAmountM3
            
            // first simulate over the current month
           
            for day in startDay...endDayCurrentMonth {
                
                waterInTankToday = DailyWaterHarvestedM3(day: day, month: currentMonth, year: simYear, runOff: runOff, catchAreaM2: catchAreaM2) + waterInTankYesterday
                
                // water harvested cannot be greater than the tank size
                waterInTankToday = min(waterInTankToday, tankSizeM3)
                
                let dailyDemand = dailyDemandArray[currentMonth-1].dailyDemandM3
                
                if dailyDemand != 0.0 {
                    // update the counter
                    numberOfSimDays = numberOfSimDays + 1
                    waterInTankToday = waterInTankToday - dailyDemand
                    if waterInTankToday >= 0.0 {
                        sucsessSimDays = sucsessSimDays + 1
                    } else {
                        waterInTankToday = 0.0 // tank is empty
                    }
                }
            
                // prepare for tomorrow
                waterInTankYesterday = waterInTankToday
                
            }
            
            // if the final date falls in the next month then only
            if nextMonth != currentMonth {
                for day in startDayNextMonth...endDayNextMonth {
                    
                    // we have to check if the next month is Jan then we have to use rainfall for simYear+1
                    if currentMonth == 12 && nextMonth == 1 {
                        waterInTankToday = DailyWaterHarvestedM3(day: day, month: nextMonth, year: simYear + 1, runOff: runOff, catchAreaM2: catchAreaM2) + waterInTankYesterday
                    } else {
                        waterInTankToday = DailyWaterHarvestedM3(day: day, month: nextMonth, year: simYear, runOff: runOff, catchAreaM2: catchAreaM2) + waterInTankYesterday
                    }
                    
                    
                   
                    // water harvested cannot be greater than the tank size
                    waterInTankToday = min(waterInTankToday, tankSizeM3)
                    
                    let dailyDemand = dailyDemandArray[nextMonth-1].dailyDemandM3
                    
                    if dailyDemand != 0.0 {
                        // update the counter
                        numberOfSimDays = numberOfSimDays + 1
                        waterInTankToday = waterInTankToday - dailyDemand
                        if waterInTankToday >= 0.0 {
                            sucsessSimDays = sucsessSimDays + 1
                        } else {
                            waterInTankToday = 0.0 // tank is empty
                        }
                    }
                   
                    // prepare for tomorrow
                    waterInTankYesterday = waterInTankToday
                    
                }
            }
            
            // append the water in the tank on the last day
            
            waterAtTheEndOfSimArray.append(waterInTankToday)
        }
        
        // calculate demand reliability
        var demandReliability: Int?
       /* if sucsessSimDays >= 0 {
            
            demandReliability = Int(Float(sucsessSimDays) / Float(numberOfSimDays) * 100)
            
        } */
        
        if numberOfSimDays > 0 {
            
            demandReliability = Int(Float(sucsessSimDays) / Float(numberOfSimDays) * 100)
        }
        
        // calculate water in the tank at the end of the month
        
        let waterInTank = waterAtTheEndOfSimArray.min()
       
        // calculate the probability
        let count = waterAtTheEndOfSimArray.count
       // let waterReliability = Int( (Double(count - 1) / Double(count)) * 100 )
        
        return DisplayPerformance(demandReliability: demandReliability,numberOfSimYears: count, waterInTankAtTheEnd: waterInTank!)
        
        
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
    
    func HistoricalRainfallForNext30Days() async {
        
        // function that populates an array [[year, rain]] for past five years where rain is rainfall from the initial today to thirty days in future
        
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
        
       
        // var yearsToSim = Helper.PastFiveYearsFromBaseYear(baseYear: baseYear)
        var yearsToSim = ArrayOfLastFiveYearsWithDailyRainfall()
        
        // check if the current month is december and the next month is January of the next year
        if currentMonth == 12 && nextMonth == 1 {
            
            _ = yearsToSim.removeLast() // we remove the most recent year for which there is no Jan rainfall
           
        }
        
        var monthsRainfallMM = 0.0
        
        for simYear in yearsToSim {
            
            monthsRainfallMM = 0.0
            
            for day in startDay...endDayCurrentMonth {
                
                monthsRainfallMM += DailyRainfallInM(day: day, month: currentMonth, year: simYear)
               
            }
            
        // if the final date falls in the next month
            
            if nextMonth != currentMonth {
                
                for day in startDayNextMonth...endDayNextMonth {
                    
                    monthsRainfallMM += DailyRainfallInM(day: day, month: nextMonth, year: simYear)
                }
            }
            
            self.totalRainfallmm = monthsRainfallMM
           
            DispatchQueue.main.async {
                
                self.arrayPast30daysRainfall.append(DisplayAnnualRain(year: simYear, annualRainMM: self.totalRainfallmm))
               
                    }
          //  arrayPast30daysRainfall.append(DisplayAnnualRain(year: simYear, annualRainMM: totalRainfallmm))
            
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
}

struct ProbableAmount {
    var waterInTankM3 = 0.0
    var probability = 0
}
struct DisplayPerformance {
    var demandReliability: Int? // if there is no demand then there is no reliability
    var numberOfSimYears = 0 //
    var waterInTankAtTheEnd = 0.0 //min in last numberOfSimYears
    
}
