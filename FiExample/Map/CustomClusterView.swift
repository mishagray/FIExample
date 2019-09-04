//
//  CustomClusterView.swift
//  FiExample
//
//  Created by Michael Gray on 9/2/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import UIKit
import MapKit

// MARK: Battle Rapper View
internal final class ResturantView: MKMarkerAnnotationView {
    // MARK: Properties
    internal override var annotation: MKAnnotation? {
        willSet {
            newValue.flatMap(configure(with:))
        }
    }
}
// MARK: Configuration
private extension ResturantView {
    func configure(with mkannotation: MKAnnotation) {
        guard (mkannotation as? Annotation) != nil else {
            fatalError("Unexpected annotation type: \(mkannotation)")
        }
        //    CONFIGURE

        clusteringIdentifier = String(describing: ResturantView.self)
        canShowCallout = true
//        animatesWhenAdded = true
    }
}

class CustomClusterView: MKAnnotationView {
    // MARK: Properties
    internal override var annotation: MKAnnotation? {
        willSet {
            newValue.flatMap(configure(with:))
        }
    }
    // MARK: Initialization
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        displayPriority = .defaultHigh
        collisionMode = .circle
        centerOffset = CGPoint(x: 0.0, y: -10.0)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) not implemented.")
    }
}
// MARK: Configuration
private extension CustomClusterView {
    func configure(with annotation: MKAnnotation) {
        guard let annotation = annotation as? MKClusterAnnotation else { return }
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40.0, height: 40.0))
        let count = annotation.memberAnnotations.count
        image = renderer.image { _ in
            UIColor.purple.setFill()
            UIBezierPath(ovalIn: CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)).fill()
            let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white,
                                                             .font: UIFont.systemFont(ofSize: 12.0)]
            let text = "\(count)"
            let size = text.size(withAttributes: attributes)
            let rect = CGRect(x: 20 - size.width / 2, y: 20 - size.height / 2, width: size.width, height: size.height)
            text.draw(in: rect, withAttributes: attributes)
        }    }
}
