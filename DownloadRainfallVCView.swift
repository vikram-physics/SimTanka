//
//  DownloadRainfallVCView.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 15/09/23.
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html


import SwiftUI
import Charts

struct DownloadRainfallVCView: View {
    
  // @EnvironmentObject var myTankaUnits: TankaUnits
    @EnvironmentObject var downloadRain: DownloadRainfallFromVC
    
    //// for units
    @AppStorage("userRainSymbol") private var userRainSymbol: String = Region.preferredRainUnit().symbol
    @State private var selectedRainUnit = Region.preferredRainUnit()
    
    // for checking internet connection
    @StateObject var network = Network()
    
    // alert panner
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // base year is the year from which user starts using SimTanka
    @AppStorage("setBaseYear") private var setBaseYear = false
    @AppStorage("baseYear") private var baseYear = 0
    
    
    // to check if we have downloaded past five years record - from the base year
    @AppStorage("rainRecordsAvailable") private var rainRecordsAvailable = false
    // is true if past five years rainfall records were downloaded
    
    // For storing the location of the RWHS
    @AppStorage("rwhsLat") private var rwhsLat = 0.0
    @AppStorage("rwhsLong") private var rwhsLong = 0.0
    @AppStorage("nameOfLocation") private var nameOfLocation = String()
    @AppStorage("cityOfRWHS") private var cityOfRWHS = String()
    
    // Add this environment property to access the presentation mode
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
       
        VStack(alignment: .center, spacing: 2) {
                  
            
                HStack{
              
                    Text(downloadRain.downloadMsg  + " \(cityOfRWHS) in \(selectedRainUnit.symbol)")
                        .font(.system(size: 12))
                        .padding(10) // Add some padding around the text
                        .background(Color.gray.opacity(0.2)) // Set an elegant background color
                        .cornerRadius(8) // Apply rounded corners to the background
              
                 
                }
               
                Chart(downloadRain.arrayOfAnnualRain) { year in
            
                        BarMark(
                            x: .value("year", String(year.year)),
                           // y: .value("rain", Helper.RainInUserUnitFromMM(rainMM: year.annualRainMM, userRainUnits: myTankaUnits.rainfallUnit) )
                            y: .value("rain", convertMMtoUserUnit(rainInMM: year.annualRainMM))
                            )
                    
                        .annotation (position: .automatic, alignment: .center) {
                              //  Text(String(format: "%.0f", Helper.RainInUserUnitFromMM(rainMM: year.annualRainMM, userRainUnits: myTankaUnits.rainfallUnit)))
                            Text(String(format: "%.0f", convertMMtoUserUnit(rainInMM: year.annualRainMM)))
                               .font(.caption)
                                }
                            .foregroundStyle(.green)
                            
                }.frame(height: 375).background(AppColors.lightBlue)
                
            HStack{
                if rainRecordsAvailable {
                                Button(action: {
                                    
                                    // Dismiss the current view when the button is tapped
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    HStack{
                                        Text("Tap to set your water budget")
                                            .frame(height: 30)
                                            .multilineTextAlignment(.center)
                                            .font(.caption)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 4)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(8)
                                    }
                                    
                                }
                                .padding(.top, 20)
                            }
                Spacer()
                Link(destination: URL(string: "https://www.visualcrossing.com/")!) {
                    VStack {
                        Image("PoweredByVC").resizable().scaledToFit()
                            .padding(.top, 20)
                    }
                }
            }.frame(height: 50).padding()
            

            
        }
        .alert(isPresented: $showAlert) {
            
            
                Alert(
                    title: Text("Download Rainfall Data"),
                    message: Text(alertMessage).font(.headline),
                    primaryButton: .default(Text("OK")) {
                    // Start the download task here
                        if checkForNetwork() {
                            Task {
                                self.checkForBaseYear()
                                await downloadRainfall()
                            }
                        }
                       
                    },
                    secondaryButton: .cancel()
                )
            }
        .task {
            if checkForNetwork() {
                alertMessage = """
SimTanka will download 5 years of daily rainfall data. This may take a few minutes. Please wait until the download is completed.
"""
                showAlert = true
            } else {
                alertMessage = "SimTanka needs internet connection to download rainfall data."
                showAlert = true
            }
          // await downloadRainfall()
        }
        .onAppear{
            loadUserPreferedUnit()
        }
        .navigationTitle("Download Rainfall")
        
        
    }
}

extension DownloadRainfallVCView {
    func checkForBaseYear() {
    
        if !setBaseYear {
            // find current year
            let year = Helper.CurrentYear()
            self.baseYear = year
            self.setBaseYear = true
        }
       
    }
    
    func checkForNetwork() -> Bool {
        if self.network.connected {
            print("connected")
            return true
        } else {
            print("not connected or so it seems")
            return false
        }
    }
    
    func fetchPastFiveYearRainfall() async {
        do {
            try  await downloadRain.FetchAndSavePastFiveYearsDailyRainfall(latitude: rwhsLat, longitude: rwhsLong)
        } catch {
          print("Could not finish downloading")
           
        }
    }
    
    func downloadRainfall() async {
        if rainRecordsAvailable == false {
            await fetchPastFiveYearRainfall()
        } else {
            // update annual rainfall view array for chart
            downloadRain.LastFiveYearsAnnualRain()
            
        }
        
    }
    
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

struct DownloadRainfallVCView_Previews: PreviewProvider {
    static var persistenceController = PersistenceController.shared
    static var previews: some View {
        DownloadRainfallVCView()
            .environmentObject(DownloadRainfallFromVC(managedObjectContext: persistenceController.container.viewContext))
    }
}
