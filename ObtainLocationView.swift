//
//  ObtainLocationView.swift
//  SimTanka-iOS
//
//  Created by Vikram Vyas on 22/11/22.
//
//
// View for obtaining location of the RWHS
//
// Released under
// GNU General Public License v3.0 or later
// https://www.gnu.org/licenses/gpl-3.0-standalone.html

import SwiftUI
import CoreLocation
import CoreLocationUI
import Network

struct ObtainLocationView: View {
    
    // Access the presentationMode environment variable
    @Environment(\.presentationMode) var presentationMode
    

   // var myColor5 = Color(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1))
    
    // For storing the location of the RWHS
    @AppStorage("rwhsLat") private var rwhsLat = 0.0
    @AppStorage("rwhsLong") private var rwhsLong = 0.0
    @AppStorage("setLocation") private var setLocation = false
    @AppStorage("nameOfLocation") private var nameOfLocation = String()
    @AppStorage("cityOfRWHS") private var cityOfRWHS = String()
    
    // for obtaining the location from users location
    @StateObject var locationManager = LocationManager()
    
    // for checking internet connection
    @StateObject var network = Network()
    
    @State private var choosenLocation = Locations.CurrentLocation
    @State var latitudeStrg = String()
    @State var longitudeStrg = String()
    @State private var userGivenLatitude = 0.0
    @State private var userGivenLongitude = 0.0
    
    @State private var geoLocationObtained = String()
    @State private var showSaveLocationButton = false
    @State private var alertSavingLocation = false
    
    
    var body: some View {
        
        VStack{
            HStack {
                Spacer()
                Text("Provide the location of your RWHS").font(.title3)
                Spacer()
            }.foregroundColor(.black)
           
            Picker("Location", selection: $choosenLocation) {
                
                ForEach(Locations.allCases, id:\.self) {
                    Text($0.text)
                }
            }.pickerStyle(SegmentedPickerStyle())
                .background(AppColors.myColor5)
            
            if choosenLocation.rawValue == 0 {
            
               
                HelpLocationFromPhoneView()
                    .frame(height: 250)
                    
                VStack {
                    HStack {
                        Spacer()
                        LocationButton (.currentLocation) {
                            locationManager.requestWhenInUseAuthorization()
                            locationManager.locationManager.startUpdatingLocation()
                        }.labelStyle(.titleOnly).font(.callout)
                            .cornerRadius(50).padding(1)
                            .foregroundColor(.white)
                            .symbolVariant(.fill).tint(.blue)
                        Spacer()
                        Button(action: {
                            saveCurrentLocation()
                            Task{
                                await findNameOftheLocation()
                                showSaveLocationButton = true
                            }
                        }, label: {
                            Text("Show on the map").font(.callout)
                                .foregroundColor(.white)
                                .padding(5)
                                .background(AppColors.myColor4)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            })
                            .disabled(!LocationObtained())
                            .opacity(LocationObtained() ? 1.0 : 0.5) // Change opacity when disabled
                        Spacer()
                    }
                }
            }
            
            if choosenLocation.rawValue == 1 {
                
                HelpLocationUserCoordView()
                    .frame(height: 175)
                VStack(alignment: .leading, spacing: 0){
                    Text("Enter the location of the RWHS").foregroundColor(.black)
                    HStack{
                        Text("Latitude:")
                        TextField("latitude", text: $latitudeStrg).keyboardType(.numbersAndPunctuation)
                            .autocorrectionDisabled()
                    }
                    HStack{
                        Text("Longitude:")
                        TextField("Longitude", text: $longitudeStrg).keyboardType(.numbersAndPunctuation)
                            .autocorrectionDisabled()
                    }
                    Spacer()
                    // validate and save location of the RWHS
                    if validUserGivenLocation(latString: latitudeStrg, longString: longitudeStrg) {
                   HStack(alignment:.center){
                       Spacer()
                       Button(action: {
                         
                           saveUserGivenLocation()
                           Task {
                               // Find the name of the user's location asynchronously
                                await findNameOfUserGivenLocation()

                                // Show the save button (only do this once)
                                showSaveLocationButton = true

                           }
                       }, label:{
                           Text("Show on the map")
                               .font(.callout)
                               .foregroundColor(.white)
                               .padding(1)
                               .background(AppColors.myColor4)
                               .clipShape(RoundedRectangle(cornerRadius: 10))
                       } ).buttonStyle(BorderlessButtonStyle())
                          // .disabled(validUserGivenLocation(latString: latitudeStrg, longString: longitudeStrg))
                     //  Spacer()
                   }
                        
                    }
                   
                   
                }.padding().font(.callout).background(AppColors.myColor5)
                    .cornerRadius(5)
                    .onTapGesture {
                        self.hideKeyboard()
                      }
                .frame(height:75)
            }
            
           
        }.padding().background(AppColors.myColor5)
            .navigationTitle("Location")
        
         SimTankaMapView(rwhsLatitude: userGivenLatitude, rwhsLongitude: userGivenLongitude).cornerRadius(1).frame(height:175)
        
        // Allow user to save the location
        HStack{
            Spacer()
            if !setLocation && showSaveLocationButton {
                Button(action: {
                    informSavingForDownloadingRainfall()
                   
                },
                label: {
                    HStack {
                        Text("\(network.connected ? "Save Location" : "Enable internet to download rainfall")")
                            .font(.callout)
                            .foregroundColor(.white)
                            .padding(10)
                            .background(AppColors.myColor4)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }).alert("Your location is set to \(self.geoLocationObtained). You will not be able to change it later!", isPresented: $alertSavingLocation) {
                    Button("Save") {
                       saveLocation()
                    }
                    Button("Cancel", role: .cancel) {
                        showSaveLocationButton = false
                        userGivenLatitude = 0.0
                        userGivenLongitude = 0.0
                        geoLocationObtained = String()
                        nameOfLocation = String()
                        cityOfRWHS = String()
                    }
                   
                }
                .disabled(!network.connected)
            }
            Spacer()
           
        }
        
    }
}

extension ObtainLocationView {
    
    func LocationObtained() -> Bool {
        if let location = locationManager.location {
            if location.latitude == 0.0 && location.longitude == 0.0 {
                return false
            } else {
                return true
            }
        }
        
        return false
    }
    
    func saveCurrentLocation() {
        // reset the values
        rwhsLat = 0.0
        rwhsLong = 0.0
        
        if let location = locationManager.location {
            userGivenLatitude = location.latitude
            userGivenLongitude = location.longitude
        }
    }
    
    func validUserGivenLocation(latString: String, longString: String) -> Bool {
        
        
        if Double(latString) == nil {
            
            return false
        }
        
        if Double(longString) == nil {
            return false
        }
        
        return true
    }
    
    func saveUserGivenLocation() {
        
        // reset before saving
        rwhsLat = 0.0
        rwhsLong = 0.0
        
        // validated before using
        userGivenLatitude = Double(latitudeStrg)!
        userGivenLongitude = Double(longitudeStrg)!
       
        rwhsLat = userGivenLatitude
        rwhsLong = userGivenLongitude
    }
    
    func saveRWHSLocation() {
        rwhsLat = userGivenLatitude
        rwhsLong = userGivenLongitude
        setLocation = true
    }
    
    func findNameOftheLocation() async {
        
        let geocoder = CLGeocoder()
        var city = String()
        var name = String()
        
        
       // let cllLocationOfRWHS = CLLocation(latitude: rwhsLat, longitude: rwhsLong)
        if let location = locationManager.location {
            userGivenLatitude = location.latitude
            userGivenLongitude = location.longitude
        }
        let cllLocationOfRWHS = CLLocation(latitude: userGivenLatitude, longitude: userGivenLongitude)
        if let rwhsPlacemark = try? await geocoder.reverseGeocodeLocation(cllLocationOfRWHS) {
            // find city
            city = rwhsPlacemark.first?.locality ?? ""
            // find name
            name = rwhsPlacemark.first?.name ?? ""
            
            // save them
            self.geoLocationObtained = "\(name), \(city)"
            self.nameOfLocation = self.geoLocationObtained
            self.cityOfRWHS = city
           
        } else {
            print("Could not find the name of the location")
        }
        
       
    }
    
    func findNameOfUserGivenLocation() async {
        let geocoder = CLGeocoder()
        var city = String()
        var name = String()
        
        let cllLocationOfRWHS = CLLocation(latitude: userGivenLatitude, longitude: userGivenLongitude)
        if let rwhsPlacemark = try? await geocoder.reverseGeocodeLocation(cllLocationOfRWHS) {
            // find city
            city = rwhsPlacemark.first?.locality ?? ""
            // find name
            name = rwhsPlacemark.first?.name ?? ""
            
            // save them
            self.geoLocationObtained = "\(name), \(city)"
            self.nameOfLocation = self.geoLocationObtained
            self.cityOfRWHS = city
           
        } else {
            print("Could not find the name of the location")
        }
    }
    
    func informSavingForDownloadingRainfall() {
        
        // if saving the location obtained from the phone
        if choosenLocation.rawValue == 0 {
            Task {
                await findNameOftheLocation()
                alertSavingLocation = true
            }
        }
        
        // if saving the location given by the user
        if choosenLocation.rawValue == 1 {
            Task {
                await findNameOfUserGivenLocation()
                alertSavingLocation = true
            }
        }
        
    }
    
    func saveLocation() {
        
        // if saving the location of the phone
        if choosenLocation.rawValue == 0 {
            Task {
                await findNameOftheLocation()
                saveRWHSLocation()
            }
            
            
            // Dismiss the view and return to the main view
            self.presentationMode.wrappedValue.dismiss()
        }
        
        // if saving the location given by the user
        if choosenLocation.rawValue == 1 {
            Task{
                await findNameOfUserGivenLocation()
                saveRWHSLocation()
            }
            // Dismiss the view and return to the main view
            self.presentationMode.wrappedValue.dismiss()
        }
    }
    
}

struct ObtainLocationView_Previews: PreviewProvider {
    static var previews: some View {
        ObtainLocationView()
    }
}
