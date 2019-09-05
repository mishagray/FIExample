//
//  MapKitExtensions.swift
//  FiExample
//
//  Created by Michael Gray on 9/5/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import MapKit

extension MKMapRect {
    func union(with cood: CLLocationCoordinate2D) -> MKMapRect {
        if !CLLocationCoordinate2DIsValid(cood) {
            return self
        }
        let newPoint = MKMapPoint(cood)
        return self.union(with: newPoint)
    }

    func union(with point: MKMapPoint) -> MKMapRect {
        if !CLLocationCoordinate2DIsValid(point.coordinate) {
            return self
        }
        let newRect = MKMapRect(origin: point, size: MKMapSize(width: 0.0, height: 0.0))

        if self.isNull {
            return newRect
        } else {
            return self.union(newRect)
        }
    }

    var maxPoint: MKMapPoint {
        if self.isNull {
            return MKMapPoint(kCLLocationCoordinate2DInvalid)
        }
        return MKMapPoint(x: self.maxX, y: self.maxY)
    }

    var diagnalDistance: CLLocationDistance {
        self.origin.distance(to: self.maxPoint)
    }
}
