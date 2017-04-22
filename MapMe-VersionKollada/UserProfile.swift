//
//  UserProfile.swift
//  MapMe-VersionKollada
//
//  Created by Matt Kollada on 4/13/17.
//  Copyright © 2017 Matt Kollada. All rights reserved.
//

import Foundation
import CoreLocation

struct UserProfile {
    
    var username: String = ""
    var password: String = ""
    var name: String = ""
    var locationArray: [CLLocation] = []
    
    func toAnyObject() -> Any {
        return [
            "name": name,
            "username": username,
            "password": password,
            "locArray": locationArray
        ]
    }
    
}
