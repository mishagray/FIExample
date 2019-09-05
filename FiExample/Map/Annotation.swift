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

    let lastGrade: Grade?

    init(resturant rest: Restaurant) {
        self.resturant = rest

        let latestInspection = rest.grades.max { (inspectionA, inspectionB) -> Bool in
            inspectionA.date.date < inspectionB.date.date
        }
        self.lastGrade = latestInspection?.grade
    }

    var hasValidCoordinate: Bool {
        return CLLocationCoordinate2DIsValid(self.coordinate)
    }

    var cuisine: Cuisine {
        self.resturant.cuisine
    }
}

extension Restaurant {
    var coordinate: CLLocationCoordinate2D {
        if self.address.coord.count != 2 {
            return kCLLocationCoordinate2DInvalid
        }
        let latitude = self.address.coord[1]
        let longitude = self.address.coord[0]
        return CLLocationCoordinate2D(latitude: latitude,
                                      longitude: longitude)
    }

    var hasValidCoordinate: Bool {
        return CLLocationCoordinate2DIsValid(self.coordinate)
    }

}

extension Annotation: MKAnnotation {

    var coordinate: CLLocationCoordinate2D {
        return resturant.coordinate
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
