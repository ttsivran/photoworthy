//
//  HashableCoordinate.swift
//  Photoworthy
//
//  Created by Theodore Tsivranidis on 6/16/18.
//  Copyright © 2018 Teo Tsivranidis. All rights reserved.
//

import UIKit
import GoogleMaps

class Place: Hashable {
    
    var coordinates: CLLocationCoordinate2D
    var name: String
    
    init(coordinates: CLLocationCoordinate2D, name: String) {
        self.coordinates = coordinates
        self.name = name
    }
    
    var hashValue: Int {
        return (self.coordinates.latitude + self.coordinates.longitude).hashValue
    }
    
    static func == (lhs: Place, rhs: Place) -> Bool {
        return (lhs.coordinates.latitude == rhs.coordinates.latitude) && (lhs.coordinates.longitude == rhs.coordinates.longitude)
    }

}
