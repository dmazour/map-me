//
//  FirstViewController.swift
//  MapMe-VersionKollada
//
//  Created by Matt Kollada on 4/10/17.
//  Copyright © 2017 Matt Kollada. All rights reserved.
//

import UIKit
import MapKit


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

//https://developer.apple.com/reference/mapkit/mkmapviewdelegate
class CustomLocation: NSData {
    var lat : NSNumber?
    var long : NSNumber?
    var timestamp : NSDate?
    var altitude : NSNumber?
    var verticalAccuracy : NSNumber?
    var horizontalAccuracy : NSNumber?
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
    let memory = UserDefaults.standard
    
    
    //CIRCLE VISUALIZATION!
    //var circlesArray: [CLLocationCoordinate2D] = []
    var circlesArray: [MKCoordinateRegion] = []
    //every 15 minutes, update circlesArray
    var isExistingLocation: Bool = false
    var currRegion: MKCoordinateRegion!
    //http://stackoverflow.com/questions/38194513/swift-scheduledtimerwithtimeinterval-nsinvocation
    var timer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mkMapView.delegate = self
        mkMapView.showsUserLocation = true
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        //        if(memory.array(forKey: "locations") != nil) {
        //            for location in memory.array(forKey: "locations")! {
        //                let loc = CLLocation(coordinate: CLLocationCoordinate2D(latitude: (location as! CustomLocation).lat as! CLLocationDegrees, longitude: (location as! CustomLocation).long as! CLLocationDegrees), altitude: (location as! CustomLocation).altitude as! CLLocationDistance, horizontalAccuracy: (location as! CustomLocation).horizontalAccuracy as! CLLocationAccuracy, verticalAccuracy: (location as! CustomLocation).verticalAccuracy as! CLLocationAccuracy, timestamp: (location as! CustomLocation).timestamp! as Date)
        //                coordArray.append(loc.coordinate)
        //                locationArray.append(loc)
        //            }
        //        }
        //DispatchQueue.main.async {
        
        self.locationManager.startUpdatingLocation()
        //}
        
        
        //ADD THIS STUFF - 4/16
        //A higher distanceFilter could reduce the zigging and zagging and thus give you a more accurate line. Unfortunately, too high a filter would pixelate your readings. That’s why 10 meters is a good balance.
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0
        
        timer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { (Timer) in
                self.appendToCirclesArray()
        }

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //HOW DO WE AUTOMATICALLY ZOOM THE MAP JUST TO SEE THE RELEVANT COORDINATES
    /*
     override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
     <#code#>
     }
     */
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let polylineRenderer = MKPolylineRenderer(overlay: overlay)
            polylineRenderer.strokeColor = UIColor.blue
            polylineRenderer.lineWidth = 5
            print(10)
            return polylineRenderer
        }
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(circle: overlay as! MKCircle)
            circleRenderer.fillColor = UIColor.blue
            return circleRenderer
        }
        
        
        print(1)
        
        return MKPolylineRenderer()
    }
    
    //    func saveLocation(location: CLLocation) {
    //        let customLocation = CustomLocation()
    //        print(location.coordinate.latitude)
    //        customLocation.lat = location.coordinate.latitude as NSNumber
    //        customLocation.long = location.coordinate.latitude as NSNumber
    //        customLocation.timestamp = location.timestamp as NSDate
    //        customLocation.altitude = location.altitude as NSNumber
    //        customLocation.verticalAccuracy = location.verticalAccuracy as NSNumber
    //        customLocation.horizontalAccuracy = location.horizontalAccuracy as NSNumber
    //        if var savedLocations = memory.array(forKey: "locations") {
    //            savedLocations.append(customLocation)
    //            memory.set(savedLocations, forKey: "locations")
    //        }
    //        else {
    //            var savedLocations = [CustomLocation]()
    //            savedLocations.append(customLocation)
    //            memory.set(savedLocations, forKey: "locations")
    //        }
    //
    //    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //        print(locations[locations.endIndex-1])
        locationArray.append(locations[locations.endIndex-1])
        coordArray.append(locations[locations.endIndex-1].coordinate)
        //        saveLocation(location: locations[locations.endIndex-1])
        path = MKPolyline(coordinates: &coordArray, count: coordArray.count)
        print(coordArray)
        polyLineRenderer = mapView(mkMapView, rendererFor: path!) as? MKPolylineRenderer
        polyLineRenderer?.strokeColor = UIColor.blue
        polyLineRenderer?.lineWidth = 5
        self.mkMapView.add(path!, level: MKOverlayLevel.aboveLabels)
        
        //http://stackoverflow.com/questions/41189147/swift-3-mapkit-zoom-to-user-current-location
        //one degree of latitude is always approximately 111 kilometers (69 miles)
        //one degree of longitude spans a distance of approximately 111 kilometers (69 miles) at the equator but shrinks to 0 kilometers at the poles
        
        //CHANGE = IMPORTANT: THIS USES THE FIRST PAIR OF COORDINATES IN THE ARRAY, SO IF THE USER'S PATH IS LONGER THAN ~17 MILES, IT'LL GO OFF-SCREEN.
        //ALSO, I WOULD LIKE FOR THIS TO SCALE AUTOMATICALLY TO THE PATH, NOT AT A FIXED RADIUS.
        //adjustedRegion = mapView.regionThatFits(MKCoordinateRegionMake(coordArray[0], MKCoordinateSpan(latitudeDelta: 0.25,longitudeDelta: 0.25)))
        
        adjustedRegion = mkMapView.regionThatFits(regionForCoordinates(coordinates: coordArray))
        mkMapView.setRegion(adjustedRegion!, animated: true)
        
        /*
         let someLocation = locations[0]
         print("A single location is \(someLocation)")
         
         let howRecent = someLocation.timestamp.timeIntervalSinceNow
         
         if (howRecent < -10 ){ return }
         
         let accuracy = someLocation.horizontalAccuracy
         print("how recent is it? \(howRecent) and this accurate \(accuracy) in meters")
         */
    }
    //CIRCLE VISUALIZATION!
    func appendToCirclesArray(){
        for region in circlesArray {
            if(isCoordinateInsideRegion(coordinate: coordArray[locationArray.endIndex-1], region: region)){
                isExistingLocation = true
                currRegion = region
                break
            }
        }
        if(isExistingLocation){
            //increase radius of existing circle = (constant + increase)*(scale factor based on time period displayed)
                //how do we access an existing circle?
            mkMapView.add(MKCircle(center: currRegion.center, radius: 45))
        }
        else{
            //append MKCoordinateRegion to the circlesArray with center at current point and radius of 25 meters
            circlesArray.append(MKCoordinateRegionMake(coordArray[locationArray.endIndex-1], MKCoordinateSpanMake(0.00022522522, 0.00022522522)))
            
            //draw circle with radius = constant*(scale factor based on time period displayed)
            mkMapView.add(MKCircle(center: coordArray[locationArray.endIndex-1], radius: 25))

            
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
