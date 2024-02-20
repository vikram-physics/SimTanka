//
//  AnnualRainfallViewVC.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 16/09/23.
//
// Displays past five years annual rainfall once it has been downloaded
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html


import SwiftUI
import Charts

struct AnnualRainfallViewVC: View {
    
  //  @EnvironmentObject var myTankaUnits: TankaUnits
    @EnvironmentObject var downloadRain: DownloadRainfallFromVC
    
    @AppStorage("cityOfRWHS") private var cityOfRWHS = String()
    
    // for units
    @AppStorage("userRainSymbol") private var userRainSymbol: String = Region.preferredRainUnit().symbol
    @State private var selectedRainUnit = Region.preferredRainUnit()
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0)  {
            
            HStack{
                Text("Annual rainfall in \(cityOfRWHS)")
                Picker("", selection: $selectedRainUnit) {
                    ForEach(Region.rainUnits(), id: \.self) { unit in
                        Text(unit.symbol).foregroundStyle(.black)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }.font(.caption).padding().foregroundColor(.black)
            
         /*   Text("**Annual Rainfall**  in **\(myTankaUnits.rainfallUnit.text)**  \(cityOfRWHS) ").foregroundColor(.white)
                .font(.headline).padding()
                .frame(height: 20) */
            
            Chart(downloadRain.arrayOfAnnualRain) { year in
        
                    BarMark(
                        x: .value("year", String(year.year)),
                       // y: .value("rain", Helper.RainInUserUnitFromMM(rainMM: year.annualRainMM, userRainUnits: myTankaUnits.rainfallUnit) )
                        y: .value("rain", convertMMtoUserUnit(rainInMM: year.annualRainMM))
                        )
                        .foregroundStyle(.blue)
                        .annotation (position: .automatic, alignment: .center) {
                           // Text(String(format: "%.0f", Helper.RainInUserUnitFromMM(rainMM: year.annualRainMM, userRainUnits: myTankaUnits.rainfallUnit)))
                            Text(String(format: "%.0f", convertMMtoUserUnit(rainInMM: year.annualRainMM)))
                           .font(.caption)
                            }
            }.background(AppColors.lightGray)
            
        /*    HStack{
                Spacer()
                Link(destination: URL(string: "https://www.visualcrossing.com/")!) {
                    VStack {
                        Image("PoweredByVC").resizable().scaledToFit()
                            .frame(width: 100, height: 50)
                        
                    }
                }
                Spacer()
            } */
        }.task {
            downloadRain.LastFiveYearsAnnualRain()
        }
        .background(AppColors.lightGray)
        .onDisappear{
            // store users choice of unit
            userRainSymbol = selectedRainUnit.symbol
        }
        .onAppear {
           // selectedRainUnit = UnitLength(symbol: userRainSymbol)
            loadUserPreferedUnit() 
        }
    }
}

extension AnnualRainfallViewVC {
    
    private func convertMMtoUserUnit(rainInMM: Double) -> Double {
        
        let simTankaRainMeasurment = Measurement(value: rainInMM, unit: UnitLength.millimeters)
       
        let userRainMeasurment = simTankaRainMeasurment.converted(to: self.selectedRainUnit)
        
        return userRainMeasurment.value
        
    }
    
    private func loadUserPreferedUnit() {
        
        let userSymbol = userRainSymbol
        
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

struct AnnualRainfallViewVC_Previews: PreviewProvider {
    static var persistenceController = PersistenceController.shared
    
    static var previews: some View {
        AnnualRainfallViewVC()
           // .environmentObject(TankaUnits())
            .environmentObject(DownloadRainfallFromVC(managedObjectContext: persistenceController.container.viewContext))
    }
}
