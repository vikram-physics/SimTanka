//
//  upDateDailyRainfallRecordsView.swift
//  SimTanka-iOS
//
//  Created by Vikram  on 29/11/23.
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI

struct upDateDailyRainfallRecordsView: View {
    
    @EnvironmentObject var downloadRain: DownloadRainfallFromVC
    
    // Add this environment property to access the presentation mode
    @Environment(\.presentationMode) var presentationMode
    
    // for downloading daily rainfall records
    @AppStorage("rwhsLat") private var rwhsLat = 0.0
    @AppStorage("rwhsLong") private var rwhsLong = 0.0
    @AppStorage("cityOfRWHS") private var cityOfRWHS = String()
    
    // for annual update of daily rainfall records
    @AppStorage("rainRecordsUpdated") private var rainRecordsUpdated = false
    
    // for checking internet connection
    @StateObject var network = Network()
    
    // for alert sheet
    @State private var showAlert = false
    @State private var alertMessage = "Updating rainfall record can take some time "
    
    @State private var isDownloadButtonDisabled = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue, Color.gray]), startPoint: .top, endPoint: .bottom)
                      // .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                VStack {
                    // Show the latest year for which the rainfall records are available
                    Text("Downloaded rainfall records till \(String(downloadRain.LatestYearForWhichRainRecordExsist())).")
                    Text("Records for \(String(Helper.CurrentYear() - 1)) are available for downloading.")
                        
                }.padding(10).cornerRadius(8).foregroundColor(.white)
                
                if downloadRain.downloading {
                    HStack {
                        
                        Button(action: {
                                  
                                Task {
                                    await self.updateDailyRainRecords()
                                    // Disable the button after clicking
                                    isDownloadButtonDisabled = true
                                    }
                            
                            }) {
                                Text(checkForNetwork() ? "Download" : "Cannot download: Need internet connection ...")
                                        .padding(10)
                                        .foregroundColor(.white)
                                        .background(AppColors.lightBlue)
                                        .cornerRadius(10)
                                }.disabled(!checkForNetwork() || isDownloadButtonDisabled)
                        
                    }
                }
                
                Text(downloadRain.downloadMsg  + " \(cityOfRWHS)")
                //
                
                if !downloadRain.downloading {
                    Button(action: {
                        // Dismiss the current view when the button is tapped
                        presentationMode.wrappedValue.dismiss()
                            
                        }) {
                            Text("Records updated: Back to SimTanka")
                                    .padding(10)
                                    .foregroundColor(.white)
                                    .background(AppColors.lightBlue)
                                    .cornerRadius(10)
                            }
                }
                Spacer()
                Link(destination: URL(string: "https://www.visualcrossing.com/")!) {
                    VStack {
                        Image("PoweredByVC").resizable().scaledToFit()
                            .padding(.top, 20)
                            .frame(height: 75).padding()
                    }
                }
                
               
            }.onAppear{
                downloadRain.downloadMsg = "" // clear the msg
                downloadRain.downloading = true
            }
           
        }
        
       
    }
}

extension upDateDailyRainfallRecordsView {
    
    func checkForNetwork() -> Bool {
        if self.network.connected {
           // print("connected")
            return true
        } else {
           // print("not connected or so it seems")
            return false
        }
    }
    
    func updateDailyRainRecords() async {
        
        // download and display suitable message or plot 
        do {
            // alert user that this can take some time
            try  await downloadRain.UpdateDailyRainfallRecords(latitude: rwhsLat, longitude: rwhsLong)
            // updated so change the flag
            rainRecordsUpdated = true
            // inform user that updated
            // show button to return to main view
            
        } catch {
          print("Could not upate rainfall records")
           
        }
    }
    
    private func rainRecordsHasBeenUpdate() -> Bool {
        
        let latestYear = downloadRain.LatestYearForWhichRainRecordExsist()
        
        let currentYear = Helper.CurrentYear()
       
        if latestYear  == currentYear - 1 {
            return true
        } else {
            return false
        }
        
        
    }
}

#Preview {
    let persistenceController = PersistenceController.shared
    
    return upDateDailyRainfallRecordsView()
        .environmentObject(DownloadRainfallFromVC(managedObjectContext: persistenceController.container.viewContext))
}
