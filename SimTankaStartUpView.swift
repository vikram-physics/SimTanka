//
//  SimTankaStartUpView.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 31/07/23.
//
/// Released under
/// GNU General Public License v3.0 or later
/// https://www.gnu.org/licenses/gpl-3.0-standalone.html
/// 
import SwiftUI
import MapKit

struct SimTankaStartUpView: View {
    
    // for show about SimTanka view with GNU licence etc
    @AppStorage("hasSeenTheLicense") var hasSeenTheLicense = false
   // @State private var showLicencse = false
    
    // for all AppStorage Variables
    // check this if it is working
    @EnvironmentObject private var appSettings: AppSettings
    
    // for updating rainfall records
    @EnvironmentObject var downloadRain: DownloadRainfallFromVC
    
   // @EnvironmentObject var waterDiaryModel:WaterDiaryModel
    @AppStorage("boardingCompleted") var boardingCompleted: Bool = false // for setting up
    @AppStorage("rwhsLat") private var rwhsLat = 0.0
    @AppStorage("rwhsLong") private var rwhsLong = 0.0
    @AppStorage("rwhsSet") static var rwhsSet = false
   // @AppStorage("rwhsSet") var rwhsSet = false
    @AppStorage("setLocation") var setLocation = false
    
    // rainfall
    @AppStorage("rainRecordsAvailable") var rainRecordsAvailable = false
    
    // waterbudget
    @AppStorage("waterBudgetIsSet") var waterBudgetIsSet = false
    
    // catchment area
    @AppStorage("catchAreaIsSet") var catchAreaIsSet = false
    
    // storage tank
    @AppStorage("tankSizeIsSet") private var tankSizeIsSet = false
    
    // build or planning to build
    @AppStorage("isRWHSBuilt") private var isRWHSBuilt = true
    
    // status of the RWHS
    @AppStorage("savedStatus") private var savedStatusRawValue: Int = Status.Working.rawValue
    
    // for annual update of daily rainfall records
  //  @AppStorage("rainRecordsUpdated") private var rainRecordsUpdated = false
   
    
    var body: some View {
        
        NavigationStack {
            
            ZStack {
                
                
                
                
                if hasSeenTheLicense {
                    
                   
                    
                    List {
                       
                        // show the location of the RWHS on the map
                        
                        
                        
                            if setLocation {
                            // show the location on the map
                            SimTankaMapView(rwhsLatitude: rwhsLat, rwhsLongitude: rwhsLong)
                                .frame(height: 135)//.padding(.bottom)
                                .listRowBackground(AppColors.myColor4)
                                .listRowInsets(EdgeInsets())
                        }
                        
                        
                        
                        // section for setting up SimTank for the first time - boarding
                        
                        if !boardingCompleted {
                            Section {
                                // set up the location
                                if !setLocation {
                                    NavigationLink(destination: ObtainLocationView(), label: {
                                       
                                        VStack{
                                            Text("\(Image(systemName: "1.circle")) Set the location of your RWHS")
                                                .font(.title3).foregroundColor(.white)
                                                .lineLimit(nil) // This will allow the text to expand to fit its content
                                                .padding()
                                            Text("SimTanka uses the location of your RWHS to retrieve historical daily rainfall records.")
                                                .font(.headline)
                                        }
                                        
                                    }).listRowBackground(AppColors.myColorOne).frame(height: 200)
                                    
                                } else {
                                    HStack {
                                        Text("\(Image(systemName: "1.circle")) Your location is set")
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green) // Set color to green
                                    }.listRowBackground(AppColors.lightGray)
                                }
                                
                                // set up downloading the rainfall data
                                
                                
                                if !rainRecordsAvailable {
                                    NavigationLink(destination: DownloadRainfallVCView(), label: {
                                        VStack{
                                            Text("\(Image(systemName: "2.circle")) Download the daily rainfall records")
                                                .font(.title3).foregroundColor(.white)
                                                .lineLimit(nil) // This will allow the text to expand to fit its content
                                                .padding()
                                            Text("SimTanka uses past rainfall records to estimate the reliability of your RWHS.")
                                                .font(.headline)
                                        }
                                    })
                                    .listRowBackground(AppColors.myColorTwo).frame(height: 200)
                                    .disabled(!(setLocation && !rainRecordsAvailable)) // Disable the button based on the condition
                                    .opacity(setLocation && !rainRecordsAvailable ? 1.0 : 0.3) // Change opacity when disabled

                                }
                               
                                
                                if rainRecordsAvailable {
                                    HStack {
                                        Text("\(Image(systemName: "2.circle")) You have downloaded past five years of rainfall")
                                            .font(.headline)
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green) // Set color to green
                                    }.listRowBackground(AppColors.lightGray)
                                   // .frame(height: 50)
                                           
                                }
                                
                                // set up water budget
                                if setLocation && rainRecordsAvailable {
                                    
                                    if !waterBudgetIsSet {
                                        NavigationLink(destination:  NewDailyBudgetView()) {
                                            Text("\(Image(systemName: "3.circle")) Set up your water budget")
                                                .font(.headline).foregroundColor(.white)
                                                .lineLimit(nil) // This will allow the text to expand to fit its content
                                                .padding()
                                        }
                                        .listRowBackground(AppColors.myColorTwo).foregroundColor(.white).frame(height: 100)
                                    } else {
                                        HStack {
                                            Text("\(Image(systemName: "3.circle")) Your water budget is set")
                                                .font(.headline)
                                            Spacer()
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green) // Set color to green
                                        }.listRowBackground(AppColors.lightGray)
                                       // .frame(height: 50)
                                    }
                                   
                                }
                                
                                // set up  catchment area
                                if waterBudgetIsSet  {
                                    if !catchAreaIsSet {
                                        NavigationLink(destination: SetupCatchmentArea(), label: {
                                            VStack{
                                                Text("\(Image(systemName: "4.circle")) Catchment Area")
                                                    .font(.title3).foregroundColor(.white)
                                                    .lineLimit(nil) // This will allow the text to expand to fit its content
                                                    .padding()
                                                Text("Please provide details about the surface from which you will be collecting rainwater.")
                                                    .font(.headline)
                                            }
                                        }) .listRowBackground(AppColors.myColorTwo).frame(height: 130)
                                    } else {
                                        HStack {
                                            Text("\(Image(systemName: "4.circle")) Your catchment area information has been successfully recorded.")
                                                .font(.headline)
                                            Spacer()
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green) // Set color to green
                                        }.listRowBackground(AppColors.lightGray)
                                    }
                                    
                                }
                                
                                // set up tank size
                                
                                if catchAreaIsSet {
                                    if !tankSizeIsSet {
                                        NavigationLink(destination: SetTankSizeView(), label: {
                                            VStack{
                                                Text("\(Image(systemName: "5.circle")) Tank Size")
                                                    .font(.title3).foregroundColor(.white)
                                                    .lineLimit(nil) // This will allow the text to expand to fit its content
                                                    .padding()
                                                Text("Please provide the size of your storage tank.")
                                                    .font(.headline)
                                            }
                                        }) .listRowBackground(AppColors.myColorTwo).frame(height: 130)
                                    } else {
                                        HStack {
                                            Text("\(Image(systemName: "5.circle")) You are ready to use SimTanka.")
                                                .font(.headline)
                                            Spacer()
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green) // Set color to green
                                        }.listRowBackground(AppColors.lightGray)
                                    }
                                }
                                
                                // ready to use
                                if tankSizeIsSet {
                                    HStack{
                                        Button {
                                            self.boardingCompleted = true
                                        } label: {
                                            Text("Tap to start using SimTanka")
                                                .fontWeight(.semibold)
                                                       .font(.system(size: 18))
                                                       .padding(.vertical, 12)
                                                       .padding(.horizontal, 24)
                                                       .foregroundColor(.white)
                                                       .background(Color.blue)
                                                       .cornerRadius(8)
                                        }

                                    }
                                    //.frame(height: 50)
                                }
                            
                                
                            } header: {
                                VStack{
                                    Text("Setting up SimTanka").font(.headline)
                                    
                                }
                                
                            }
                        }
                        
                       
                    
                        
                        if boardingCompleted {
                            
                            // summary of the RWHS
                            Section {
                                if checkIfRainfallRecordsNeedUpdate() {
                                    NavigationLink(destination: upDateDailyRainfallRecordsView()) {
                                        Text("**Please update your rainfall records**").font(.subheadline)
                                    }.listRowBackground(AppColors.lightGray).foregroundColor(.black)
                                }
                                
                                NavigationLink(destination: SummaryRWHSView()) {
                                    Text("RWHS").font(.subheadline)
                                }.listRowBackground(AppColors.lightBlue).foregroundColor(.black)
                               
                             
                                
                                
                                NavigationLink(destination: SummaryOfRainfallView()) {
                                    Text("Rainfall").font(.subheadline)
                                }.listRowBackground(AppColors.lightGray).foregroundColor(.black)
                                
                              // To be added in iOS17 version by making it clickable
                                NavigationLink(destination: DisplayWaterBudgetChart()) {
                                    Text("Water Budget").font(.subheadline)
                                }.listRowBackground(AppColors.lightBlue).foregroundColor(.black)
                              
                            } header: {
                                Text("Info").font(.headline)
                            }

                            
                            

                           
                            
                            // RWHS exist
                            if isRWHSBuilt {
                                
                               
                                
                                // performance for next thirty days
                                Section(header: Text(!isRWHSBuilt ? "Planning Tools" : "Tools").font(.headline)) {
                                    
                                    // water diary
                                        NavigationLink(destination: WaterDiaryListView()) {
                                            Text("Water Diary ").font(.subheadline)
                                        }
                                        .listRowBackground(AppColors.lightBlue).foregroundColor(.black)
                                    
                                    NavigationLink(destination:  NewPerformanceView() ) {
                                        VStack{
                                            HStack{
                                                Text("Estimate performance:")
                                                Spacer()
                                            }
                                            HStack{
                                                Text("\(Helper.ThirtyDaysPeriodString())")
                                                Spacer()
                                            }
                                           
                                                
                                        }.font(.subheadline)
                                        
                                    }.listRowBackground(AppColors.lightGray).foregroundColor(.black)
                                    
                                // edit water budget
                                    NavigationLink(destination:  NewDailyBudgetView()) {
                                        Text("Edit Water Budget").font(.subheadline)
                                    }
                                    .listRowBackground(AppColors.lightBlue).foregroundColor(.black)
                                    
                                
                                    
                             // adding new tanks
                                    // optimse tank size
                                    NavigationLink(destination: EditModifyTankSize()) {
                                        Text("Modify Tank Size").font(.subheadline)
                                    }
                                    .listRowBackground(AppColors.lightGray).foregroundColor(.black)
                                    
                                    
                                   
                                }
                            } else {
                                
                                // planning outline
                                NavigationLink(destination: RWHSplanningView()) {
                                    Text("**Planning new RWHS**").font(.subheadline)
                                }
                                .listRowBackground(AppColors.lightBlue).foregroundColor(.black)
                                
                                // optimse tank size
                                NavigationLink(destination: OptimizeTankSizeView()) {
                                    Text("**RWHS**: Update & Optimize System").font(.subheadline)
                                }
                                .listRowBackground(AppColors.lightBlue).foregroundColor(.black)
                                
                                // modify water budget
                                NavigationLink(destination:  NewDailyBudgetView()) {
                                    Text("**Water Budget**: Modify your water budget").font(.subheadline)
                                }
                                .listRowBackground(AppColors.lightBlue).foregroundColor(.black)
                            }
                            
                           
                            
                        }
                      
                    }
                    .navigationBarTitle(Text("SimTanka"), displayMode: .inline)
                    .preferredColorScheme(.light)
                    .toolbar {
                        
                        // top bar
                       /* ToolbarItem(placement: .automatic) {
                           
                            NavigationLink(destination: PrefernceView()) {
                                Image(systemName: "gearshape")
                            }
                        } */
                        
                        //bottombar group
                        
                        ToolbarItemGroup(placement: .bottomBar) {
                            // first vol contribution
                            NavigationLink(destination: VolContAppStoreView(), label: {
                                Label("Contribute", systemImage: "water.waves")
                            })
                            Spacer()
                            // about simtanka
                            NavigationLink(destination: AboutSimTankaView(), label: {
                                Label("About", systemImage: "info.circle")
                            })
                        }
                        
                        
                    }
                    .onAppear{
                       
                        
                    }
                    
                    
                } else {
                    VStack {
                        LicenseView(showLicence: $hasSeenTheLicense)
                    }
                }
                
                
                
                
            }
           
           
           
            
            }
        }
        
    }

extension SimTankaStartUpView {
    
    private func timeToUpdateRainRecords() -> Bool {
        /// Hard coded for updating after 01June 
        let day = 1
        let month = 6
        let currentYear = Calendar.current.component(.year, from: Date())

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ddMMyyyy"
        
        let customDate = dateFormatter.date(from: String(format: "%02d%02d%04d", day, month, currentYear))
        let currentDate = Date()
        
       
        if currentDate > customDate! {
            
            return true
        } else {
           
            return false
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
    private func checkIfRainfallRecordsNeedUpdate() -> Bool {
        
        // 1. check is it time to update - hard wired for updating after 31 may -> false
        // 2. check if we have already updated -> return false
        // 3. return -> true 
        
        if timeToUpdateRainRecords() && !rainRecordsHasBeenUpdate() {
            return true
        } else {
            return false
        }
        
       
    }
}


struct SimTankaStartUpView_Previews: PreviewProvider {
    
    let persistenceController = PersistenceController.shared
    
    @AppStorage("rwhsSet") static var rwhsSet = true
    
    static var previews: some View {
        SimTankaStartUpView()
            .environmentObject(AppSettings())
           
        
    }
}


class AppSettings: ObservableObject {
    @AppStorage("boardingCompleted") var boardingCompleted: Bool = false // for setting up
    @AppStorage("costPerUnit") private var costPerUnit: String = "" // Tank cost
    @AppStorage("rwhsLat") private var rwhsLat = 0.0
    @AppStorage("rwhsLong") private var rwhsLong = 0.0
    @AppStorage("setLocation") var setLocation = false
    
    @AppStorage("setMetStation") var setMetStation = false
    @AppStorage("waterBudgetIsSet") var waterBudgetIsSet = false
  //  @AppStorage("rwhsSet") var rwhsSet = false
    
    @AppStorage("setUpRWHSMsg") var setUpRWHSMsg = "Please describe your rainwater harvesting system"
    @AppStorage("setUpBudgetMsg") var setUpBudgetMsg =  "Please set up your water budget."
    @AppStorage("msgLocationMetStation") var msgLocationMetStation = "Please download daily rainfall records for your location"
    @AppStorage("nameOfLocation") private var nameOfLocation = String()
    
    // You can also have custom methods to update settings or perform additional logic if needed
}

struct CollapsedView<Content: View>: View {
    let title: String
    let content: () -> Content
    @State private var isCollapsed = false
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isCollapsed,
            content: {
                content()
            },
            label: {
                HStack {
                    Text(title).font(.caption2)
                        
                    Spacer()
                   // Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                }
            }
        )
        //.padding()
    }
}
