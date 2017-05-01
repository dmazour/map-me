//
//  FirstViewController.swift
//  MapMe-VersionKollada
//
//  Created by Matt Kollada on 4/10/17.
//  Copyright © 2017 Matt Kollada. All rights reserved.
//


//
//  ViewController.swift
//  MapMe
//
//  Created by Daniel Mazour on 4/6/17.
//  Copyright © 2017 Daniel Mazour. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Firebase
import FirebaseAuthUI

//make CLLocationCoordinate2D hashable so that we can use at as a key in the pointDictionary
//https://blog.stormid.com/2015/10/mkmapview-pins-swift/

extension CLLocationCoordinate2D: Hashable {
    public var hashValue: Int {
        get {
            return (latitude.hashValue&*397) &+ longitude.hashValue;
        }
    }
}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

private extension MKPolyline {
    convenience init(coordinates coords: Array<CLLocationCoordinate2D>) {
        let unsafeCoordinates = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: coords.count)
        unsafeCoordinates.initialize(from: coords)
        self.init(coordinates: unsafeCoordinates, count: coords.count)
        unsafeCoordinates.deallocate(capacity: coords.count)
    }
}

class FirstViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    

    @IBOutlet weak var mkMapView: MKMapView!
    let locationManager = CLLocationManager()
    var locationArray: [String:[CLLocation]] = [String:[CLLocation]]()
    var coordArray: [String:[CLLocationCoordinate2D]] = [String:[CLLocationCoordinate2D]]()
    var path: MKPolyline?
    var adjustedRegion: MKCoordinateRegion?
    var polyLineRenderer : MKPolylineRenderer?
    var overlay : MKOverlay?
    
    //FIR Database handlers/refs
    var handle: FIRAuthStateDidChangeListenerHandle?
    var user: FIRUser?
    var rootRef: FIRDatabaseReference?
    var users: FIRDatabaseReference?
    var name: FIRDatabaseReference?
    var locArray: FIRDatabaseReference?

    //create a user defaults object to get settings
    let memory = UserDefaults.standard
    
    //Settings Variables
    var settings: [String:Date] = [:]
    var startDate: Date?
    var stopDate: Date?
    
    //check if loctation did up date
    var didUpdateLocation: Bool = true
    
    
    //Arrays to store and receive data
//    var locs: [Double] = []
    var locDictionary: [String:[Double]] = [String:[Double]]()
    
    
    //CIRCLE VISUALIZATION!
    //var regionArray: [CLLocationCoordinate2D] = []
    var regionArray: [String:[MKCoordinateRegion]] = [String:[MKCoordinateRegion]]()
    //every 15 minutes, update regionArray
    var isExistingLocation: Bool = false
    var currRegion: MKCoordinateRegion!
    //http://stackoverflow.com/questions/38194513/swift-scheduledtimerwithtimeinterval-nsinvocation
    var circleTimer: Timer!
    var locationTimer: Timer!
    
    //POINT DICTIONARY will be populated with Firebase location data
    //For every coordinate in the Firebase location data:
    //  1) Check if that coordinate is within an existing region in the regionArray (which is an array of MKCoordinateRegions).
    //  2) If not:
    //      a) append to the pointDictionary with count = 1 and
    //      b) append to regionArray: a new MKCoordinateRegion with this coordinate as its center and 25m radius.
    //  3) If yes:
    //      a) increment that coordinate's count in the pointDictionary
    //
    //Then, pointDictionary will be used to:
    //  1) create initial viz
    
    //As the app is being used:
    //  1) Check regionArray to see if live-added points are within an existing region.
    //  2) If not, append that location to:
    //      a) locs,
    //      b) locationArray(do we need this anymore?),
    //      c) pointDictionary with count = 1, and
    //      d) regionArray
    
    //var pointDictionary = [CLLocationCoordinate2D:Int]()
    var dictOfPointDicts = [String:[CLLocationCoordinate2D:Int]]()
    
    var selectedUsers = [User]()
    var currentUser: User?
    
    override func viewDidAppear(_ animated: Bool) {
        locationManager.pausesLocationUpdatesAutomatically = false
        if let settingsMemory = memory.dictionary(forKey: "settings"){
            settings = settingsMemory as! [String:Date]
            startDate = settings["startDate"]
            stopDate = settings["stopDate"]
        }
        else {
            startDate = Date(timeIntervalSince1970: 0)
            stopDate = Date(timeIntervalSinceNow: 0)
        }
        
        selectedUsers = []
        
        currentUser = User(userEmail: (FIRAuth.auth()?.currentUser?.email)!, userID: FriendSystem.system.CURRENT_USER_ID)
        selectedUsers.append(currentUser!)
        
        for friend in FriendSystem.system.friendList {
            selectedUsers.append(friend)
        }
        
//        for user in selectedUsers {
//            locationArray[user.id] = []
//            coordArray[user.id] = []
//            dictOfPointDicts[user.id] = [:]
//            regionArray[user.id] = []
//            locDictionary[user.id] = []
//        }
        for user in selectedUsers {
//            if (locationArray[user.id]?.endIndex)! > 0 {
            self.updateCoordArrayForSettings(id: user.id)
//            }
            
            
            loadPointDictionaryWithHistoricalRegions(id: user.id)
            if coordArray[user.id] == nil {
                continue
            }
            for coord in (dictOfPointDicts[user.id]?.keys)! {
                mkMapView.add(MKCircle(center: coord, radius: CLLocationDistance(100*(dictOfPointDicts[user.id]?[coord]!)!/(coordArray[user.id]?.endIndex)!)))
            }
        }
//        if !(coordArray[user.id]?.isEmpty)! {
//            adjustedRegion = mkMapView.regionThatFits(regionForCoordinates(coordinates: (coordArray[user.id])!))
//            mkMapView.setRegion(adjustedRegion!, animated: true)
//        }

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
//        FIRApp.configure()
        user = FIRAuth.auth()?.currentUser
        mkMapView.delegate = self
        mkMapView.showsUserLocation = true
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()

        FriendSystem.system.addFriendObserver { () in
            
        }
        
        if let settingsMemory = memory.dictionary(forKey: "settings"){
            settings = settingsMemory as! [String:Date]
            startDate = settings["startDate"]
            stopDate = settings["stopDate"]
        }
        else {
            startDate = Date(timeIntervalSince1970: 0)
            stopDate = Date(timeIntervalSinceNow: 0)
        }
        
        currentUser = User(userEmail: (FIRAuth.auth()?.currentUser?.email)!, userID: FriendSystem.system.CURRENT_USER_ID)
        selectedUsers.append(currentUser!)
        
        for friend in FriendSystem.system.friendList {
            selectedUsers.append(friend)
        }
        
        for user in selectedUsers {
            locationArray[user.id] = []
            coordArray[user.id] = []
            dictOfPointDicts[user.id] = [:]
            regionArray[user.id] = []
            locDictionary[user.id] = []
        }
        
        //Set FireBase Database references
        rootRef = FIRDatabase.database().reference()
        users = rootRef?.child("users")
        name = users?.child((user?.uid)!)
        locArray = name?.child("location array")
        
        //receives raw firebase location data from firebase and places it into array locs
        users?.observe(.value, with: { snapshot in
            for user in self.selectedUsers {
                if snapshot.childSnapshot(forPath: user.id).childSnapshot(forPath: "location array").value is NSNull {
                    self.locDictionary[user.id] = []
                }
                else {
                    self.locDictionary[user.id] = (snapshot.childSnapshot(forPath: user.id).childSnapshot(forPath: "location array").value as! [Double])
                }
                //adds data to locationArray
                self.downloadFirebaseData(id: user.id)
                self.updateCoordArrayForSettings(id: user.id)
                self.loadPointDictionaryWithHistoricalRegions(id: user.id)
                if self.dictOfPointDicts[user.id]?.keys == nil {
                    
                }
                else {
                    for coord in (self.dictOfPointDicts[user.id]?.keys)! {
                        self.mkMapView.add(MKCircle(center: coord, radius: CLLocationDistance(log(Double(100*(self.dictOfPointDicts[user.id]![coord]!)/self.coordArray[user.id]!.endIndex)))))
                    }
                }
                if self.coordArray[user.id] != nil {
                    if !(self.coordArray[user.id]?.isEmpty)! {
                        self.adjustedRegion = self.mkMapView.regionThatFits(self.regionForCoordinates(coordinates: self.coordArray[user.id]!))
                        self.mkMapView.setRegion(self.adjustedRegion!, animated: true)
                    }
                }
                
                //            self.locationManager.startUpdatingLocation()
                
                //runs appendToCircles array every 300 secs currently. can change by changing timeInterval
                self.circleTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateRegions), userInfo: nil, repeats: true)
                
                //changes how frequently location is updated by firing updateLocation() at specific time intervals
                self.locationTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.updateLocation), userInfo: nil, repeats: true)
            }
        })
        
        

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.distanceFilter = 10.0
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //needed for firebase authorization
    override func viewWillAppear(_ animated: Bool) {
        handle = FIRAuth.auth()?.addStateDidChangeListener() { (auth, user) in
            // ...
        }
        
    }
    
    //needed for firebase authorization
    override func viewWillDisappear(_ animated: Bool) {
        FIRAuth.auth()?.removeStateDidChangeListener(handle!)
        //sends loc information to firebase
        locArray?.setValue(locDictionary[FriendSystem.system.CURRENT_USER_ID])
    }
    
    //takes array received from firebase, turns data into CLLocation objects, and appends to location array
    func downloadFirebaseData(id: String) {
        locationArray = [:]
//        for user in selectedUsers {
            locationArray[id] = []
            print(locDictionary[id])
            if (locDictionary[id]!.endIndex) > 0{
                for i in 0...((locDictionary[id]?.endIndex)!/6)-1 {
                    locationArray[id]!.append(CLLocation(coordinate: CLLocationCoordinate2D(latitude: (locDictionary[id]?[6*i])!, longitude: (locDictionary[id]?[6*i + 1])!), altitude: (locDictionary[id]?[6*i + 2])!, horizontalAccuracy: (locDictionary[id]?[6*i + 4])!, verticalAccuracy: (locDictionary[id]?[6*i + 5])!, timestamp: Date(timeIntervalSince1970: (locDictionary[id]?[6*i + 3])!)))
                }
            }
//        }
    }
    
    func clearMap() {
        print("map was cleared")
        let overlays = mkMapView.overlays
    
        if !overlays.isEmpty {
            mkMapView.removeOverlays(overlays)
        }
    }
    
    func updateCoordArrayForSettings(id: String) {
        var startIndex = 0
        coordArray = [:]
//        for user in selectedUsers {
            coordArray[id] = []
            if locationArray[id] == nil {
                return
            }
            else if (locationArray[id]?.isEmpty)! {
                return
            }
            for i in 0...(locationArray[id]?.count)!-1 {
                if (locationArray[id]?[i].timestamp)! < startDate! {
                    
                }
                else {
                    startIndex = i
                    break
                }
            }
            
            for i in startIndex...(locationArray[id]?.count)!-1 {
                if (locationArray[id]?[i].timestamp)! < stopDate! {
                    coordArray[id]!.append(locationArray[id]![i].coordinate)
                }
                else {
                    break
                }
            }
//        }
        print(coordArray)
    }
    
    //POINT DICTIONARY will be populated with Firebase location data
    //For every coordinate in the Firebase location data:
    //  1) Check if that coordinate is within an existing region in the regionArray (which is an array of MKCoordinateRegions).
    //  2) If not:
    //      a) append to the pointDictionary with count = 1 and
    //      b) append to regionArray: a new MKCoordinateRegion with this coordinate as its center and 25m radius.
    //  3) If yes:
    //      a) increment that coordinate's count in the pointDictionary
    func loadPointDictionaryWithHistoricalRegions(id: String) {
        dictOfPointDicts = [:]
        regionArray = [:]
//        for user in selectedUsers {
//            print(user.id)
//            print(coordArray[user.id])
            if coordArray[id] == nil {
                return
            }
            regionArray[id] = []
            dictOfPointDicts[id] = [:]
            for coord in coordArray[id]! {
                var isInExistingRegion = false
                for existingRegion in regionArray[id]! {
                    if (isCoordinateInsideRegion(coordinate: coord, region: existingRegion)){
                        //coord is within an existing region
                        dictOfPointDicts[id]![existingRegion.center] = dictOfPointDicts[id]![existingRegion.center]! + 2
                        isInExistingRegion = true
                    }
                    else{
                        //coord is not within this region
                        continue
                    }
                }
                if !isInExistingRegion {
                    //coord is not within any region
                    //append to regionArray
                    dictOfPointDicts[id]?[coord] = -1
                    regionArray[id]!.append(MKCoordinateRegionMakeWithDistance(coord, 50, 50))
                }
            }
//        }
    }
    
    //starts updating location and then immediately stops it
    //allows us to change frequency of location tracking in timer in viewDidLoad()
    func updateLocation() {
        locationManager.startUpdatingLocation()
        
//        clearMap()
        for user in selectedUsers {
            print(user.email)
            if self.dictOfPointDicts[user.id]?.keys == nil {
                continue
            }
            for coord in (self.dictOfPointDicts[user.id]?.keys)! {
                mkMapView.add(MKCircle(center: coord, radius: CLLocationDistance(100*(dictOfPointDicts[user.id]?[coord]!)!/(coordArray[user.id]?.endIndex)!)))
            }
        }
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blue
            polylineRenderer.lineWidth = 5
            return polylineRenderer
        }
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
            circleRenderer.fillColor = UIColor.blue
            return circleRenderer
        }
        return MKPolylineRenderer()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let addLoc = locations[locations.endIndex-1]
        locationArray[FriendSystem.system.CURRENT_USER_ID]?.append(addLoc)
        coordArray[FriendSystem.system.CURRENT_USER_ID]?.append(addLoc.coordinate)
//        path = MKPolyline(coordinates: &coordArray, count: coordArray.count)
//        polyLineRenderer = mapView(mkMapView, rendererFor: path!) as? MKPolylineRenderer
//        polyLineRenderer?.strokeColor = UIColor.blue
//        polyLineRenderer?.lineWidth = 5
//        self.mkMapView.add(path!, level: MKOverlayLevel.aboveLabels)
        
        
        //loads loc information to locs to be sent to firebase
        locDictionary[FriendSystem.system.CURRENT_USER_ID]?.append(addLoc.coordinate.latitude as Double)
        locDictionary[FriendSystem.system.CURRENT_USER_ID]?.append(addLoc.coordinate.longitude as Double)
        locDictionary[FriendSystem.system.CURRENT_USER_ID]?.append(addLoc.altitude as Double)
        locDictionary[FriendSystem.system.CURRENT_USER_ID]?.append(addLoc.timestamp.timeIntervalSince1970 as Double)
        locDictionary[FriendSystem.system.CURRENT_USER_ID]?.append(addLoc.horizontalAccuracy as Double)
        locDictionary[FriendSystem.system.CURRENT_USER_ID]?.append(addLoc.verticalAccuracy as Double)
        self.locationManager.stopUpdatingLocation()
        //let howRecent = someLocation.timestamp.timeIntervalSinceNow
    }
        
        //CIRCLE VISUALIZATION!
        //As the app is being used:
        //  1) Check regionArray to see if live-added points are within an existing region.
        //  2) If not, append that location to:
        //      a) locs,
        //      b) locationArray(do we need this anymore?),
        //      c) pointDictionary with count = 1, and
        //      d) regionArray
        func updateRegions(){
                if regionArray[FriendSystem.system.CURRENT_USER_ID] == nil {
                    return
                }
                for region in regionArray[FriendSystem.system.CURRENT_USER_ID]! {
                    if(isCoordinateInsideRegion(coordinate: (coordArray[FriendSystem.system.CURRENT_USER_ID]?[(coordArray[FriendSystem.system.CURRENT_USER_ID]?.endIndex)!-1])!, region: region)){
                        isExistingLocation = true
                        currRegion = region
                        break
                    }
                }
                if(isExistingLocation){
                    //increase radius of existing circle = (constant + increase)*(scale factor based on time period displayed)
                    //how do we access an existing circle?
                    print(dictOfPointDicts[FriendSystem.system.CURRENT_USER_ID])
                    mkMapView.add(MKCircle(center: currRegion.center, radius: CLLocationDistance(100*(dictOfPointDicts[FriendSystem.system.CURRENT_USER_ID]?[currRegion.center])!)))
                    self.dictOfPointDicts[FriendSystem.system.CURRENT_USER_ID]?[currRegion.center] = (self.dictOfPointDicts[FriendSystem.system.CURRENT_USER_ID]?[currRegion.center]!)! + 2
                }
                else{
                    //append MKCoordinateRegion to the regionArray with center at current point and radius of 25 meters
                    if !(coordArray[FriendSystem.system.CURRENT_USER_ID]?.isEmpty)! {
                        self.dictOfPointDicts[FriendSystem.system.CURRENT_USER_ID]?[(coordArray[FriendSystem.system.CURRENT_USER_ID]?[(coordArray[FriendSystem.system.CURRENT_USER_ID]?.endIndex)!-1])!] = 1
                        regionArray[FriendSystem.system.CURRENT_USER_ID]?.append(MKCoordinateRegionMakeWithDistance((coordArray[FriendSystem.system.CURRENT_USER_ID]?[(coordArray[FriendSystem.system.CURRENT_USER_ID]?.endIndex)!-1])!, 50, 50))
                        
                        //draw circle with radius = constant*(scale factor based on time period displayed)
                        mkMapView.add(MKCircle(center: (coordArray[FriendSystem.system.CURRENT_USER_ID]?[(coordArray[FriendSystem.system.CURRENT_USER_ID]?.endIndex)!-1])!, radius: 1))
                    }
                    
                    //            path = MKPolyline(coordinates: &coordArray, count: coordArray.count)
                    //            print(coordArray)
                    //            polyLineRenderer = mapView(mkMapView, rendererFor: path!) as? MKPolylineRenderer
                    //            polyLineRenderer?.strokeColor = UIColor.blue
                    //            polyLineRenderer?.lineWidth = 5
                    //            self.mkMapView.add(path!, level: MKOverlayLevel.aboveLabels)
                }
            
        }
    
        //https://gist.github.com/swissmanu/4943356
        func isCoordinateInsideRegion(coordinate: CLLocationCoordinate2D, region: MKCoordinateRegion)->Bool{
            let center: CLLocationCoordinate2D = region.center
            var northWestCorner: CLLocationCoordinate2D = CLLocationCoordinate2D.init()
            var southEastCorner: CLLocationCoordinate2D = CLLocationCoordinate2D.init()
            
            northWestCorner.latitude  = center.latitude  - (region.span.latitudeDelta  / 2.0)
            northWestCorner.longitude = center.longitude - (region.span.longitudeDelta / 2.0)
            southEastCorner.latitude  = center.latitude  + (region.span.latitudeDelta  / 2.0)
            southEastCorner.longitude = center.longitude + (region.span.longitudeDelta / 2.0)
            
            return(coordinate.latitude  >= northWestCorner.latitude &&
                coordinate.latitude  <= southEastCorner.latitude &&
                coordinate.longitude >= northWestCorner.longitude &&
                coordinate.longitude <= southEastCorner.longitude
            )
        }
        
        //https://gist.github.com/robmooney/923301
        func regionForCoordinates(coordinates : [CLLocationCoordinate2D]) ->MKCoordinateRegion {
            
            var minLat: CLLocationDegrees = 90.0
            var maxLat: CLLocationDegrees = -90.0
            var minLon: CLLocationDegrees = 180.0
            var maxLon: CLLocationDegrees = -180.0
            
            for coordinate in coordinates as [CLLocationCoordinate2D] {
                let lat = Double(coordinate.latitude)
                let long = Double(coordinate.longitude)
                if (lat < minLat) {
                    minLat = lat
                }
                if (long < minLon) {
                    minLon = long
                }
                if (lat > maxLat) {
                    maxLat = lat
                }
                if (long > maxLon) {
                    maxLon = long
                }
            }
            
            let span = MKCoordinateSpanMake(maxLat - minLat, maxLon - minLon)
            
            let center = CLLocationCoordinate2DMake((maxLat - span.latitudeDelta / 2), maxLon - span.longitudeDelta / 2)
            
            return MKCoordinateRegionMake(center, span)
        }
    
}


