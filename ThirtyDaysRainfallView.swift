//
//  ThirtyDaysRainfallView.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 03/08/23.
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI
import Charts

struct ThirtyDaysRainfallView: View {
    @EnvironmentObject private var appSettings: AppSettings
  //  @EnvironmentObject var performancdModel:PerformanceModel
    @EnvironmentObject var downloadRain: DownloadRainfallFromVC
    
  //  @EnvironmentObject var myTankaUnits: TankaUnits
    @AppStorage("cityOfRWHS") private var cityOfRWHS = String()
    
    // for units
    @AppStorage("userRainSymbol30") private var userRainSymbol30: String = Region.preferredRainUnit().symbol // UnitLength.millimeters.symbol
    @State private var selectedRainUnit = Region.preferredRainUnit()
    
    // for plotting
    
    @State private var displayArray:[DisplayAnnualRain] = []

    var today = Date()
    let futureDate = Helper.DateInFuture(daysToAdd: 30)
    var todayPlusOne = Helper.AddOrSubtractMonth(month: 1)
    
    var body: some View {
     
        
        VStack(alignment: .leading, spacing: 0) {
            
            HStack{
                Text(Helper.ThirtyDaysPeriodString() + " \(cityOfRWHS) ")
               
                Picker("", selection: $selectedRainUnit) {
                    ForEach(Region.rainUnits(), id: \.self) { unit in
                        Text(unit.symbol).foregroundStyle(.black)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }.font(.caption2)
            
           
          
            
            Chart(displayArray) { day in
               
               BarMark(
                    x: .value("year", String(day.year)),
                   // y: .value("rain", Helper.RainInUserUnitFromMM(rainMM: day.annualRainMM, userRainUnits: myTankaUnits.rainfallUnit) )
                    y: .value("rain", convertMMtoUserUnit(rainInMM: day.annualRainMM) )
                    
               ).foregroundStyle(.blue)
                    .annotation (position: .automatic, alignment: .center) {
                     //   Text(String(format: "%.0f", Helper.RainInUserUnitFromMM(rainMM: day.annualRainMM, userRainUnits: myTankaUnits.rainfallUnit)))
                      //     .font(.caption)
                        Text(String(format: "%.0f", convertMMtoUserUnit(rainInMM: day.annualRainMM)))
                           .font(.caption)
                    }
                
            }.background(AppColors.lightGray)
            
            HStack{
                Spacer()
                Link(destination: URL(string: "https://www.visualcrossing.com/")!) {
                    VStack {
                        Image("PoweredByVC").resizable().scaledToFit()
                            .frame(width: 100, height: 50)
                        
                    }
                }
                Spacer()
            }
           
                
        }.task {
           // await downloadRain.HistoricalRainfallForNext30Days()
            
            await loadDisplayArray()
                    }//.background(AppColors.myColorOne)
        .background(AppColors.lightGray)
        .onDisappear{
            // store users choice of unit
            userRainSymbol30 = selectedRainUnit.symbol
        }
        .onAppear {
           // selectedRainUnit = UnitLength(symbol: userRainSymbol)
            loadUserPreferedUnit()
        }
    }
}

extension ThirtyDaysRainfallView {
    
    private func loadDisplayArray() async  {
        
        self.displayArray =   downloadRain.ForPlotThirtyDayRainfall()
    }
    private func convertMMtoUserUnit(rainInMM: Double) -> Double {
        
        let simTankaRainMeasurment = Measurement(value: rainInMM, unit: UnitLength.millimeters)
       
        let userRainMeasurment = simTankaRainMeasurment.converted(to: self.selectedRainUnit)
        
        return userRainMeasurment.value
        
    }
    
    private func loadUserPreferedUnit() {
        
        let userSymbol = userRainSymbol30
        
        switch userSymbol {
        case "mm" :
            selectedRainUnit = .millimeters
        case "cm" :
            selectedRainUnit = .centimeters
        case "in" :
            selectedRainUnit = .inches
        default:
             selectedRainUnit =  Region.preferredRainUnit()
        }
        
    }
}
struct ThirtyDaysRainfallView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.shared
    
    static var previews: some View {
        
        ThirtyDaysRainfallView()
            .environmentObject(PerformanceModel(managedObjectContext: persistenceController.container.viewContext))
            .environmentObject(TankaUnits())
            .environmentObject(AppSettings())
    }
}
