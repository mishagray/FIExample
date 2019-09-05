//
//  CustomClusterView.swift
//  FiExample
//
//  Created by Michael Gray on 9/2/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import UIKit
import MapKit

extension Annotation {
    var color: UIColor {
        // Based on the official letter colors that appear in the windows
        switch self.lastGrade {
        case .a:
            // NYC A color
            return #colorLiteral(red: 0.1803921569, green: 0.3176470588, blue: 1, alpha: 1)
        case .b:
            return #colorLiteral(red: 0.3058823529, green: 0.6392156863, blue: 0.2509803922, alpha: 1)
            // return UIColor(red: 228/255.0, green: 161.0/255.0, blue: 59.0/255.0, alpha: 1.0)
        case .c:
            return #colorLiteral(red: 0.8941176471, green: 0.631372549, blue: 0.231372549, alpha: 1)
        case .notYetGraded:
            return .black
        default:
            return .red
        }
    }

    var clusteringIdentifier: String {
        return "resturant"
//        switch self.lastGrade {
//        case .a:
//            return "a"
//        case .b:
//            return "b"
//        default:
//            return "other"
//        }
    }
}

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
        guard let annotation = mkannotation as? Annotation else {
            fatalError("Unexpected annotation type: \(mkannotation)")
        }
        //    CONFIGURE

        markerTintColor = annotation.color
        clusteringIdentifier = annotation.clusteringIdentifier
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
        collisionMode = .rectangle
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

//        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 40.0, height: 40.0))
//        let count = annotation.memberAnnotations.count
//        self.image = renderer.image { _ in
//            UIColor.purple.setFill()
//            UIBezierPath(ovalIn: CGRect(x: 0.0, y: 0.0, width: 40.0, height: 40.0)).fill()
//            let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white,
//                                                             .font: UIFont.systemFont(ofSize: 12.0)]
//            let text = "\(count)"
//            let size = text.size(withAttributes: attributes)
//            let rect = CGRect(x: 20 - size.width / 2, y: 20 - size.height / 2, width: size.width, height: size.height)
//            text.draw(in: rect, withAttributes: attributes)
//        }

        DispatchQueue.global(qos: .utility).async {

            let count = annotation.memberAnnotations.count
            let size = count >= 100 ? CGSize(width: 40.0, height: 40.0) : CGSize(width: 30.0, height: 30.0)

            let renderer = UIGraphicsImageRenderer(size: size)
            let image = renderer.image { _ in

                UIColor.purple.setFill()
                UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
                let attributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white,
                                                                 .font: UIFont.systemFont(ofSize: 12.0)]

                let text = count <= 1000 ? "\(count)" : "1000+"
                let textSize = text.size(withAttributes: attributes)
                let rect = CGRect(x: (size.width / 2) - textSize.width / 2,
                                  y: (size.height / 2) - textSize.height / 2,
                                  width: textSize.width,
                                  height: textSize.height)
                text.draw(in: rect, withAttributes: attributes)
            }

            DispatchQueue.main.async {
                if self.annotation === annotation {
                    self.image = image
                }
            }
        }
    }
}
