
#### PerformanceModel.swift

This file defines the PerformanceModel class, which is used to manage the performance of a rainwater harvesting system.

The PerformanceModel class has the following properties:

* `baseYear`: The year from which the records are kept.
* `runOff`: The runoff coefficient of the catchment area.
* `catchAreaM2`: The catchment area in square meters.
* `waterInTankAtStart`: The water in the tank at the beginning of the simulation.
* `numberOfMonthsInFuture`: The number of months for which the future performance is estimated.
* `arrayPast30daysRainfall`: An array of DisplayAnnualRain objects that stores the past 30 days of rainfall data.
* `dailyRainController`: A fetched results controller for DailyRainVC objects.
* `demandController`: A fetched results controller for WaterDemand objects.
* `dailyRainArrayCD`: An array of DailyRainVC objects that stores the daily rainfall data from Core Data.
* `dailyDemandArray`: An array of WaterDemand objects that stores the daily water demand data from Core Data.

The PerformanceModel class also has the following methods:

* `waterHarvestedForCurrentMonth(async)`: This method estimates the water harvested in the current month.
* `waterInTankForCurrentMonth(initialAmount:) async`: This method estimates the water in the tank at the end of the current month, given an initial amount of water.
* `waterHarvestedForMonth(month:year:initialAmount:)`: This method estimates the water harvested in a specific month, given the year and an initial amount of water.
* `waterInTankForMonth(month:year:initialAmount:dailyDemand:)`: This method estimates the water in the tank at the end of a specific month, given the year, an initial amount of water, and a daily water demand.
* `DailyWaterHarvestedM3(day:month:year:runOff:catchAreaM2:)`: This method calculates the water harvested on a specific day, given the day, month, year, runoff coefficient, and catchment area.
* `WaterInTankMonthPlus(todaysAmount:) async`: This method estimates the water in the tank at the beginning of the month after one month, given the amount of water at the end of the current month.
* `ReliabilityForFuture30Days(intialAmountM3:)async`: This method calculates the reliability of the system for the next 30 days, given an initial amount of water.
* `FuturePerformance30Days(initialAmountM3:) async`: This method estimates the future performance of the system for the next 30 days, given an initial amount of water.
* `DailyRainfallInM(day:month:year:)`: This method returns the daily rainfall in millimeters for a specific day, month, and year.
* `HistoricalRainfallForNext30Days() async`: This method populates the `arrayPast30daysRainfall` property with rainfall data for the next 30 days.
* `LatestYearForWhichRainRecordExsist()`: This method returns the latest year for which there is a daily rainfall record.
* `EarliestYearForWhichRainRecordsExsist()`: This method returns the earliest year for which there is a daily rainfall record.
* `DailyRecordExistsFor(day:month:year:)`: This method checks if there is a daily rainfall record for a specific day, month, and year.
* `DoWeHaveAlltheRecordsForTheYear(year:)`: This method checks if we have all the daily rainfall records for a specific year.
* `ArrayOfYearsWithDailyRainfall()`: This method returns an array of all the years for which we have daily rainfall records.


