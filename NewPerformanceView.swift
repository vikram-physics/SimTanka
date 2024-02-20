//
//  NewPerformanceView.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 07/08/23.
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI

struct NewPerformanceView: View {
    
  //  @EnvironmentObject var myTankaUnits: TankaUnits
    @EnvironmentObject var demandModel:DemandModel
    @EnvironmentObject var performancdModel:PerformanceModel
    
    @AppStorage("tankSizeM3") private var tankSizeM3 = 1000.0
    
    @State private var today = Date()
    @State private var waterInTankAtStart:Double = 0.000
    let futureDate = Helper.DateInFuture(daysToAdd: 30)
    var todayPlusOne = Helper.AddOrSubtractMonth(month: 1)
    
    // for displaying users chosen  volume units
    @AppStorage("userVolumeUnitSymbol") private var userVolumeUnitSymbol: String = Region.preferredVolumeUnit().symbol
    @State private var selectedVolumeUnit = Region.preferredVolumeUnit()
    
    // for displaying users chosen demand unit
    
    @AppStorage("userDemandUnitSymbol") private var userDemandUnitSymbol: String = Region.preferredVolumeUnit().symbol
    @State private var selectedUnit = Region.preferredDemandUnit()
    
    // results
    @State private var displayCurrentReliability = "?" // displays reliability in meeting daily demand
    @State private var simReliabilityDone = false // simulation has ended or not
    
    @State private var simOn = false // is simulating
    
    @State private var sliderActive: Bool = false
    
    // button
    @State private var isButtonPressed = false
    @State private var scale = 1.0
    
    @State private var reliability = Int()

    var body: some View {
        
        List {
            
            Section {
                
                HStack {
                    Text("Performance for : ").bold()
                    Text(Helper.ThirtyDaysPeriodString()).bold()
                }.font(.caption).listRowBackground(AppColors.lightGray)
                
                VStack {
                    Text("Select the amount of water in the storage tank on \(Helper.DateInDayMonthStrYearFormat(date: today)) ")
                        .foregroundColor(.black)
                    
                }.font(.caption2)
               
                
                Slider(value: $waterInTankAtStart, in: 0...tankSizeM3, onEditingChanged: {self.sliderActive = $0
                    self.resetDisplayStrings()
                })
                
                // for markings
                HStack {
                   // Spacer()
                    Text("0") // Zero mark
                        .font(.system(size: 10)) // Adjust font size
                    Spacer()
                    Text("1/4") // Quarter mark
                        .font(.system(size: 10)) // Adjust font size
                    Spacer()
                    Text("1/2") // Half mark
                        .font(.system(size: 10)) // Adjust font size
                    Spacer()
                    Text("3/4") // Three quarter mark
                        .font(.system(size: 10)) // Adjust font size
                    Spacer()
                    Text("Full") // Full mark
                        .font(.system(size: 10)) // Adjust font size
                   // Spacer()
                }
                .foregroundColor(.gray) // Adjust mark color
                
                // selected amount
                HStack {
                       
                    Text("Water in the tank:" )
                    Spacer()
                    Text(volumeInTankString(volumeInM3:waterInTankAtStart)).foregroundStyle(Color.blue)

                }.font(.caption2).padding(.horizontal)
                
            } header: {
                HStack{
                    Text("Water in the tank")
                }.font(.caption)
            }.listRowBackground(AppColors.lightBlue)
            
            Section {
                HStack{
                    Text("Daily Water Demand").bold()
                        .font(.caption)
                        .padding(2)
                        .foregroundColor(.primary)
                    Spacer()
                }.listRowBackground(AppColors.lightGray)
                
                HStack{
                  
                    // display water demand of the current month
                   Text("\(Helper.monthOfTheRecord(date: today))")
                       .padding(2)
                    Spacer()
                    Text("\(displayDemand()) ")
                }.font(.caption)
                
                HStack {
                    // if next month is different from the current month
                    if Helper.monthOfTheRecord(date: today) != Helper.monthOfTheRecord(date: futureDate) {
                        
                        //Spacer()
                        Text("\(Helper.monthOfTheRecord(date: futureDate))").padding(2)
                    Spacer()
                        Text("\(displayDemandPlusOne())")
                            
                    }
                }.font(.caption)
                
            } header: {
                HStack{
                    Text("Water Demand")
                }.font(.caption)
            }.listRowBackground(AppColors.lightBlue)
            
            Section {
                
                if rwhsNotUsedInNextThirtyDays() {
                    
                    Text("You are not planning to use the RWHS for the next thirty days.")
                        .font(.caption)
                } else {
                    if !sliderActive {
                        HStack{
                            Button(action: {
                                simOn = true
                                Task {
                                    simReliabilityDone = false
                                    simReliabilityDone = await self.performance30DaysInFuture()
                                   
                                }
                            }, label: {
                                HStack{
                                    Spacer()
                                    Text( !simOn ? "Estimate" : "Estimating ...")
                                        .font(.caption).bold()
                                       // .frame(height:8)
                                        .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                                        .background(AppColors.myColor4)
                                        .foregroundColor(Color.white)
                                        .clipShape(Capsule())
                                    Spacer()
                                }
                               
                            })
                        }
                        
                    }
                    
                    HStack{
                        if simReliabilityDone {
                           
                         //   Text("Chances of meeting the daily demand")
                                //.foregroundColor(.black).font(.subheadline)
                            Spacer()
                            NewReliabilityImage(reliability: reliability)
                            Spacer()
                          //  Text("\(displayCurrentReliability)")
                          //      .font(.headline).foregroundStyle(.white)
                            
                        }

                    }.font(.caption)
                }
                
            } header: {
                HStack{
                    Text("Performance")
                }.font(.caption)
            }.listRowBackground(AppColors.lightGray)



        }.onAppear{
            loadUserPrefVolUnit()
            loadUserPreferedUnit() // for daily demand
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding()
        .colorScheme(.light)
        .navigationTitle(Text("Performance"))
        
        
    }
}

extension NewPerformanceView {
    
   func resetDisplayStrings() {
        self.simReliabilityDone = false
        self.displayCurrentReliability = "?"
       
    }
    
    func demandForCurrentMonth() -> Double {
        
        let monthIndex = Helper.MonthFromDate(date: today) - 1
        return self.performancdModel.dailyDemandArray[monthIndex].dailyDemandM3
        
    }
    
    func rwhsNotUsedInNextThirtyDays () -> Bool {
        
        if (self.demandForCurrentMonth() != 0.0 ) || (self.demandForMonthPlusOne() != 0.0) {
            return false
        } else {
            return true
        }
    }
    
    func displayDemand() -> String {
        
        let monthIndex = Helper.MonthFromDate(date: today) - 1
        let dailyDemandM3 = self.performancdModel.dailyDemandArray[monthIndex].dailyDemandM3
      //  return Helper.DemandStringFrom(dailyDemandM3: dailyDemandM3, demandUnit: myTankaUnits.demandUnit)
        return dailyDemandInUserUnits(demandInM3: dailyDemandM3)
        
    }
    
    func demandForMonthPlusOne() -> Double {
        let monthIndex = Helper.MonthFromDate(date: todayPlusOne) - 1
        return self.performancdModel.dailyDemandArray[monthIndex].dailyDemandM3
    }
    
    func displayDemandPlusOne() -> String {
        let monthIndex = Helper.MonthFromDate(date: todayPlusOne) - 1
        let dailyDemandM3 = self.performancdModel.dailyDemandArray[monthIndex].dailyDemandM3
       // return Helper.DemandStringFrom(dailyDemandM3: dailyDemandM3, demandUnit: myTankaUnits.demandUnit)
        return dailyDemandInUserUnits(demandInM3: dailyDemandM3)
    }
    
    func performance30DaysInFuture() async -> Bool {
        
       
        self.simOn = true
        let result = await self.performancdModel.FuturePerformance30Days(initialAmountM3: waterInTankAtStart)
        
        // demand reliability
        if let demandReliability = result.demandReliability {
            self.reliability = demandReliability
            self.displayCurrentReliability = Helper.LikelyHoodProbFrom(reliability: demandReliability)
           
        }
        
     
        self.simOn = false
        return true
    }
    
    private func loadUserPrefVolUnit() {
        
        let userSymbol = userVolumeUnitSymbol
        
        switch userSymbol {
            
        case UnitVolume.gallons.symbol :
            selectedVolumeUnit = .gallons
            
        case UnitVolume.cubicMeters.symbol :
            selectedVolumeUnit = .cubicMeters
            
        case UnitVolume.liters.symbol :
            selectedVolumeUnit = .liters
            
        default:
            selectedVolumeUnit = Region.preferredVolumeUnit()
        }
        
       
        
    }
    
    private func volumeInTankString(volumeInM3: Double) -> String {
        
        
        // volume in cubic meter
        let volumeInM3Units = Measurement(value: volumeInM3, unit: UnitVolume.cubicMeters)
        
        // convert to users units
        let volumeInUserUnit = volumeInM3Units.converted(to: selectedVolumeUnit)
        
        // set the volume string
        let roundedValue = round(volumeInUserUnit.value)
        return String(format: "%.0f", roundedValue) + String(" ") + String(selectedVolumeUnit.symbol)
        
        
    }
    
    private func loadUserPreferedUnit() {
        let userSymbol = userDemandUnitSymbol
        
        switch userSymbol {
        case "L" :
            selectedUnit = .liters
        case "gal" :
            selectedUnit = .gallons
        default :
            selectedUnit = Region.preferredVolumeUnit()
        }
    }
    private func dailyDemandInUserUnits(demandInM3: Double) -> String {
        
        let  simTankaDailyDemand = Measurement(value: demandInM3, unit: UnitVolume.cubicMeters)
       
        let dailyDemandInUserUnits = simTankaDailyDemand.converted(to: self.selectedUnit)
        
        let formattedString = String(format: "%.0f %@", dailyDemandInUserUnits.value, self.selectedUnit.symbol)
       
        return formattedString + "/day"
        
      
        
    }
}

struct NewPerformanceView_Previews: PreviewProvider {
    
    static var persistenceController = PersistenceController.shared
    
    
    static var previews: some View {
        NewPerformanceView()
            .environmentObject(TankaUnits())
            .environmentObject(DemandModel(managedObjectContext: persistenceController.container.viewContext))
            .environmentObject(PerformanceModel(managedObjectContext: persistenceController.container.viewContext))
    }
}

struct NewReliabilityImage: View {

  let reliability: Int

  var body: some View {

    HStack {
      
        Text("Reliability: \(Helper.LikelyHoodProbFrom(reliability: reliability))")
            .foregroundStyle(color).bold()

      Image(systemName: systemImage)
            .foregroundColor(color).bold()

    }.font(.subheadline)

  }

  var systemImage: String {
    switch reliability {
      case 0..<20:
        return "xmark.circle"
      case 20..<40:
        return "exclamationmark.triangle"
      case 40..<60:
        return "exclamationmark.circle"
      case 60..<80:
        return "exclamationmark.bubble"
      default:
        return "checkmark.circle"
    }
  }

  var color: Color {
    switch reliability {
      case 0..<30:
        return .red
      case 30..<70:
        return .orange
      default:
        return .green
    }
  }

}
