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
    var locationArray: [CLLocation] = []
    var coordArray: [CLLocationCoordinate2D] = []
    var path: MKPolyline?
    var adjustedRegion: MKCoordinateRegion?
    var polyLineRenderer : MKPolylineRenderer?
    var overlay : MKOverlay?
    
    //FIR Database handlers/refs
    var handle: FIRAuthStateDidChangeListenerHandle?
    var user: FIRUser?
    var rootRef: FIRDatabaseReference?
    var locations: FIRDatabaseReference?
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
    var locs: [Double] = []
    
    //CIRCLE VISUALIZATION!
    //var regionArray: [CLLocationCoordinate2D] = []
    var regionArray: [MKCoordinateRegion] = []
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
    var pointDictionary = [CLLocationCoordinate2D:Int]()
    
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
        
        if locationArray.endIndex > 0 {
            self.updateCoordArrayForSettings()
        }
        
        clearMap()
        loadPointDictionaryWithHistoricalRegions()
        if !coordArray.isEmpty {
            adjustedRegion = mkMapView.regionThatFits(regionForCoordinates(coordinates: coordArray))
            mkMapView.setRegion(adjustedRegion!, animated: true)
        }
        for coord in pointDictionary.keys {
            mkMapView.add(MKCircle(center: coord, radius: CLLocationDistance(100*(pointDictionary[coord]!)/coordArray.endIndex)))
        }
        print("pointDictionary \(pointDictionary.count)")
        print(regionArray.endIndex)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.allowsBackgroundLocationUpdates = true
        user = FIRAuth.auth()?.currentUser
        mkMapView.delegate = self
        mkMapView.showsUserLocation = true
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()

        if let settingsMemory = memory.dictionary(forKey: "settings"){
            settings = settingsMemory as! [String:Date]
            startDate = settings["startDate"]
            stopDate = settings["stopDate"]
            print(0)
        }
        else {
            startDate = Date(timeIntervalSince1970: 0)
            stopDate = Date(timeIntervalSinceNow: 0)
        }
        
        //Set FireBase Database references
        rootRef = FIRDatabase.database().reference()
        locations = rootRef?.child("locations")
        name = locations?.child((user?.uid)!)
        locArray = name?.child("location array")
        
        //receives raw firebase location data from firebase and places it into array locs
        locArray?.observe(.value, with: { snapshot in
            if snapshot.value is NSNull {
                print("locs is null")
                self.locs = []
            }
            else {
                self.locs = (snapshot.value as! [Double])
            }
            
            //adds data to locationArray
            self.downloadFirebaseData()
            self.updateCoordArrayForSettings()
            self.loadPointDictionaryWithHistoricalRegions()
            for coord in self.pointDictionary.keys {
                self.mkMapView.add(MKCircle(center: coord, radius: CLLocationDistance(log(Double(100*(self.pointDictionary[coord]!)/self.coordArray.endIndex)))))
            }
            if self.coordArray.isEmpty {
            }
            else {
                self.adjustedRegion = self.mkMapView.regionThatFits(self.regionForCoordinates(coordinates: self.coordArray))
                self.mkMapView.setRegion(self.adjustedRegion!, animated: true)
            }
            
//            self.locationManager.startUpdatingLocation()
            
            //runs appendToCircles array every 300 secs currently. can change by changing timeInterval
            self.circleTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(self.updateRegions), userInfo: nil, repeats: true)
            
            //changes how frequently location is updated by firing updateLocation() at specific time intervals
            self.locationTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(self.updateLocation), userInfo: nil, repeats: true)
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
        locArray?.setValue(locs)
    }
    
    //takes array received from firebase, turns data into CLLocation objects, and appends to location array
    func downloadFirebaseData() {
        locationArray = []
        if  locs.endIndex > 0 {
            for i in 0...(locs.endIndex/6)-1 {
                locationArray.append(CLLocation(coordinate: CLLocationCoordinate2D(latitude: (locs[6*i]), longitude: (locs[6*i + 1])), altitude: (locs[6*i + 2]), horizontalAccuracy: (locs[6*i + 4]), verticalAccuracy: (locs[6*i + 5]), timestamp: Date(timeIntervalSince1970: (locs[6*i + 3]))))
//                coordArray.append(CLLocationCoordinate2D(latitude: locs[6*i], longitude: locs[6*i + 1]))
            }
        }
    }
    
    func clearMap() {
        let overlays = mkMapView.overlays
    
        if !overlays.isEmpty {
            mkMapView.removeOverlays(overlays)
        }
    }
    
    func updateCoordArrayForSettings() {
        var startIndex = 0
        coordArray = []
        if locationArray.isEmpty {
            return
        }
        for i in 0...locationArray.count-1 {
            if locationArray[i].timestamp < startDate! {
                
            }
            else {
                startIndex = i
                break
            }
        }
        
        for i in startIndex...locationArray.count-1 {
            if locationArray[i].timestamp < stopDate! {
                coordArray.append(locationArray[i].coordinate)
            }
            else {
                break
            }
        }
    }
    
    //POINT DICTIONARY will be populated with Firebase location data
    //For every coordinate in the Firebase location data:
    //  1) Check if that coordinate is within an existing region in the regionArray (which is an array of MKCoordinateRegions).
    //  2) If not:
    //      a) append to the pointDictionary with count = 1 and
    //      b) append to regionArray: a new MKCoordinateRegion with this coordinate as its center and 25m radius.
    //  3) If yes:
    //      a) increment that coordinate's count in the pointDictionary
    func loadPointDictionaryWithHistoricalRegions() {
        pointDictionary = [:]
        regionArray = []
        for coord in coordArray {
            var isInExistingRegion = false
            for existingRegion in regionArray {
                if (isCoordinateInsideRegion(coordinate: coord, region: existingRegion)){
                    //coord is within an existing region
                    pointDictionary[existingRegion.center] = pointDictionary[existingRegion.center]! + 1
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
                pointDictionary[coord] = 1
                //regionArray.append(MKCoordinateRegionMake(coord, MKCoordinateSpanMake(0.00022522522, 0.00022522522)))
                regionArray.append(MKCoordinateRegionMakeWithDistance(coord, 50, 50))
            }
        }
        
    }
    
    //starts updating location and then immediately stops it
    //allows us to change frequency of location tracking in timer in viewDidLoad()
    func updateLocation() {
        locationManager.startUpdatingLocation()
        
        clearMap()
        for coord in pointDictionary.keys {
            mkMapView.add(MKCircle(center: coord, radius: CLLocationDistance(100*(pointDictionary[coord]!)/coordArray.endIndex)))
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
        locationArray.append(addLoc)
        coordArray.append(addLoc.coordinate)
//        path = MKPolyline(coordinates: &coordArray, count: coordArray.count)
//        polyLineRenderer = mapView(mkMapView, rendererFor: path!) as? MKPolylineRenderer
//        polyLineRenderer?.strokeColor = UIColor.blue
//        polyLineRenderer?.lineWidth = 5
//        self.mkMapView.add(path!, level: MKOverlayLevel.aboveLabels)
        
        
        //loads loc information to locs to be sent to firebase
        locs.append(addLoc.coordinate.latitude)
        locs.append(addLoc.coordinate.longitude)
        locs.append(addLoc.altitude)
        locs.append(addLoc.timestamp.timeIntervalSince1970)
        locs.append(addLoc.horizontalAccuracy)
        locs.append(addLoc.verticalAccuracy)
        
        print("location updating")
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
            for region in regionArray {
                if(isCoordinateInsideRegion(coordinate: coordArray[coordArray.endIndex-1], region: region)){
                    isExistingLocation = true
                    currRegion = region
                    break
                }
            }
            if(isExistingLocation){
                //increase radius of existing circle = (constant + increase)*(scale factor based on time period displayed)
                //how do we access an existing circle?
                mkMapView.add(MKCircle(center: currRegion.center, radius: CLLocationDistance(100*pointDictionary[currRegion.center]!)))
                pointDictionary[currRegion.center] = pointDictionary[currRegion.center]! + 1
            }
            else{
                //append MKCoordinateRegion to the regionArray with center at current point and radius of 25 meters
                if !coordArray.isEmpty {
                    pointDictionary[coordArray[coordArray.endIndex-1]] = 1
                    //regionArray.append(MKCoordinateRegionMake(coordArray[coordArray.endIndex-1], MKCoordinateSpanMake(0.00022522522, 0.00022522522)))
                    regionArray.append(MKCoordinateRegionMakeWithDistance(coordArray[coordArray.endIndex-1], 50, 50))
                    
                    //draw circle with radius = constant*(scale factor based on time period displayed)
                    mkMapView.add(MKCircle(center: coordArray[coordArray.endIndex-1], radius: 1))
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


