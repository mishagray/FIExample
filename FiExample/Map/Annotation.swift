//
//  Annotation.swift
//  FiExample
//
//  Created by Michael Gray on 9/1/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import MapKit
import DeepDiff

class Annotation: NSObject {
    let resturant: Restaurant

    init(resturant rest: Restaurant) {
        self.resturant = rest
    }

    var hasLatLong: Bool {
        return resturant.address.coord.count >= 2
    }
}

extension Annotation: MKAnnotation {

    var latitude: CLLocationDegrees {

        return resturant.address.coord.last ?? 0.0
    }
    var longitude: CLLocationDegrees {
        return resturant.address.coord.first ?? 0.0
    }
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }

    var title: String? {
        return resturant.name
    }

    var subtitle: String? {
        return "\(resturant.address.building) \(resturant.address.street)"
    }

}

extension Annotation: DiffAware {
    typealias DiffId = String

    var diffId: String {
        return self.resturant.restaurantID
    }

    static func compareContent(_ lhs: Annotation, _ rhs: Annotation) -> Bool {
        return lhs.resturant.restaurantID == rhs.resturant.restaurantID
    }

}
