//
//  SummaryRWHSView.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 12/10/23.
//
/// Released under
/// GNU General Public License v3.0 or later
/// https://www.gnu.org/licenses/gpl-3.0-standalone.html
/// 

import SwiftUI

struct SummaryRWHSView: View {
    
    @AppStorage("runOff") var runOff = 0.0
    @State var userRunOff = RunOff.Roof
    
    @AppStorage("catchAreaM2") private var catchAreaM2 = 0.0
    @AppStorage("preferredAreaUnitSymbol") private var preferredAreaUnitSymbol: String = Region.preferredAreaUnit().symbol
    @State private var selectedAreaUnit = Region.preferredAreaUnit()
    @State private var areaString = " "
    
    @AppStorage("tankSizeM3") private var tankSizeM3 = 0.0
    @AppStorage("userVolumeUnitSymbol") private var userVolumeUnitSymbol: String = Region.preferredVolumeUnit().symbol
    @State private var selectedVolumeUnit = Region.preferredVolumeUnit()
    @State private var tankString = ""
    
    // reliability of the existing system
    @AppStorage("reliabiltyOfSystem") private var reliabiltyOfSystem = 0
    // for recalculating optimum tank size when water budget changes
    @AppStorage("userWaterBudgetHasChanged") private var userWaterBudgetHasChanged = false
    
    // build or planning to build
    @AppStorage("isRWHSBuilt") private var isRWHSBuilt = true
    // for calculating reliabilty
    @EnvironmentObject var simTankaVC: SimTankaVC
    @EnvironmentObject var demandModel:DemandModel
    
    var body: some View {
        List {
            Section {
                VStack (spacing:4) {
                    HStack{
                        Image(systemName: "drop.fill").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                            //.background(Color.blue)
                        Text("Collecting Surface: \(userRunOff.text)")
                                        .font(.subheadline)
                                       // .padding(10)
                                        .foregroundColor(.black)
                                Spacer()
                    }
                    HStack{
                        Image(systemName: "map.fill").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                        Text("Catchment Area: \(loadCatchArea()) ")
                                       .font(.subheadline)
                                       //.padding(10)
                                       .foregroundColor(.black)
                                    Spacer()
                               }
                              // .background(AppColors.lightBlue)
                    
                    if self.isRWHSBuilt {
                        HStack{
                            Image(systemName: "gauge.with.needle.fill").foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                            Text("Storage Volume: \(loadTankSize()) ")
                                           .font(.subheadline)
                                           //.padding(10)
                                           .foregroundColor(.black)
                                        Spacer()
                                   }
                    }
                    
                   
                              // .background(AppColors.lightGray)
                    
                    if self.isRWHSBuilt {
                        HStack{
                                
                            if (reliabiltyOfSystem != 0 && !userWaterBudgetHasChanged && isRWHSBuilt) {
                              //  Text("Reliability: \(Helper.LikelyHoodProbFrom(reliability: reliabiltyOfSystem))").font(.subheadline)
                              //     Spacer()
                                ReliabilityImage(reliability: reliabiltyOfSystem)
                            } else {
                                Button {
                                    Task {
                                        
                                            await self.estimateRWHSreliability()
                                        }
                                } label: {
                                    if !self.simTankaVC.performanceSim {
                                        HStack {
                                           // Spacer()
                                            Text("Estimate Reliability").font(.subheadline)
                                                .padding()
                                                .frame(height: 30)
                                                .background(tankSizeM3 != 0.0 ? Color.blue : Color.gray)
                                                .foregroundColor(.white)
                                               .cornerRadius(10)
                                            Spacer()
                                        } //.background(AppColors.newBlue)
                                    }
                                   
                                    if self.simTankaVC.performanceSim {
                                        HStack {
                                            Text(self.simTankaVC.performanceMsg)
                                            Spacer()
                                            ProgressView().padding()
                                        }.font(.subheadline).frame(height: 30).listRowBackground(AppColors.lightBlue).id(UUID())
                                    }
                                }


                            }
                            
                            
                                
                        }
                    }
                    
                }
                           
            } header: {
                Text("RWHS").font(.headline)
            }.listRowBackground(AppColors.lightGray)
            
            Section {
                CostOfRWHSView()
            } header: {
                Text("Cost of construction").font(.headline)
            }.listRowBackground(AppColors.lightGray)

            Section {
                if self.isRWHSBuilt {
                    WaterDiarySummaryView()//.frame(height:100)
                } else {
                    Text("In planning process.").font(.headline)
                }
            } header: {
                Text("Status").font(.headline)
            }.listRowBackground(AppColors.lightGray)


        }.listStyle(.insetGrouped)
        .onAppear {
            loadUserPrefAreaUnit()
            loadUserPrefVolUnit()
        }.navigationTitle(Text("Summary & Status"))
     
       
    }
}

extension SummaryRWHSView {
    
    private func loadCatchArea() -> String {
        
        
        
        // area in square meter
        let simTankaArea = Measurement(value: catchAreaM2, unit: UnitArea.squareMeters)
        
        // area in users prefered unit
        let userCatchArea = simTankaArea.converted(to: selectedAreaUnit)
       
        // set the area string
        let roundedValue = round(userCatchArea.value)
        return String(format: "%.0f", roundedValue) + String(" ") + String(selectedAreaUnit.symbol)
    }
    
    private func loadUserPrefAreaUnit() {
        
        let userSymbol = preferredAreaUnitSymbol
        
        switch userSymbol {
            
        case UnitArea.squareFeet.symbol :
            
            selectedAreaUnit = .squareFeet
        
        case UnitArea.squareMeters.symbol :
            
            selectedAreaUnit = .squareMeters
            
        default:
            
            selectedAreaUnit = Region.preferredAreaUnit()
            
        
        }
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
    
    private func loadTankSize() -> String {
        
        // volume in cubic meter
        let simTankaVolume = Measurement(value: tankSizeM3, unit: UnitVolume.cubicMeters)
        
        // volume in users unit
        let userTankSize = simTankaVolume.converted(to: selectedVolumeUnit)
        
        // set the volume string
        let roundedValue = round(userTankSize.value)
        return String(format: "%.0f", roundedValue) + String(" ") + String(selectedVolumeUnit.symbol)
    }
    
    func estimateRWHSreliability() async {
       
        let myTanka = SimInput(runOff: runOff, catchAreaM2: catchAreaM2, tankSizeM3: tankSizeM3, dailyDemands: demandModel.DailyDemandM3())
      
        simTankaVC.displayResults = []
        await self.simTankaVC.EstimateReliabilityOfUsersRWHS(myTanka: myTanka)
        self.reliabiltyOfSystem = simTankaVC.displayResults[0].annualSuccess
        
        print("Your reliability: ", self.reliabiltyOfSystem)
        self.userWaterBudgetHasChanged = false // we have new reliability
       
    }
    
    
}
#Preview {
    let persistenceController = PersistenceController.shared
    let _ = WaterDiary(context: persistenceController.container.viewContext)
    return SummaryRWHSView()
            .environmentObject(DemandModel(managedObjectContext: persistenceController.container.viewContext))
            .environmentObject(SimTankaVC(managedObjectContext: persistenceController.container.viewContext))
            .environmentObject(WaterDiaryModel(managedObjectContext: persistenceController.container.viewContext))
}

struct ReliabilityImage: View {

  let reliability: Int

  var body: some View {

    HStack {
      
        Text("Reliability: \(Helper.LikelyHoodProbFrom(reliability: reliability))").font(.subheadline)
            .foregroundStyle(color).bold()

      Image(systemName: systemImage)
            .foregroundColor(color).bold()

    }

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
