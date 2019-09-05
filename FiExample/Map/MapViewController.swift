//
//  MapViewController.swift
//  FiExample
//
//  Created by Michael Gray on 9/1/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import UIKit
import Combine
import MapKit
import DeepDiff

struct AnnotationChanges {
    let annotations: [Annotation]
    let changes: [Change<Annotation>]
}

class MapViewModel {

    let changes: AnyPublisher<AnnotationChanges, Never>

    var filterViewModel: FilterViewModel

    init<Model: ModelType>(model: Model) {

        let filters = FilterViewModel()
        self.filterViewModel = filters

        // let's defer our publisher so we don't actually fire up the model publisher, until we get a subscriber.
        // 'safer' behavior inside of init()
        let annotations = Deferred { () -> CurrentValueSubject<[Restaurant], Never> in
            // we will auto refresh the model when subscription happens.
            // this is the secret to 'Defered'
            model.refresh()
            return model.resturants
        }
        .map {
            $0.map { Annotation(resturant: $0) }
                .filter {
                    let hasTitle = !$0.resturant.name.isEmpty
                    return $0.hasLatLong && hasTitle
            }  // ignore un-map-able resturants.
        }

        // we want to add prepend() to objectwillchange so it will always initial fire.
        // otherwise combineLatest won't fire right away.
        let filterViewModelChanges = filterViewModel
            .objectWillChange
            .receive(on: RunLoop.main)
            .prepend(())
            .map { _ in filters }

        // let's mixup the resturants signal from the API with the user's filters.
        let mapChanges =
            Publishers
                .CombineLatest(filterViewModelChanges, annotations)
                .map { filterView, annotations -> [Annotation] in

                    let byCuisine: [Annotation]
                    if !filterView.cuisines.allValuesSelected {
                        byCuisine = annotations.compactMap {
                            if filterView.cuisines.valueIsSelected(value: $0.cuisine.rawValue) {
                                return $0
                            }
                            return nil
                        }
                    } else {
                        byCuisine = annotations
                    }

                    let byGrade: [Annotation]
                    if !filterView.grades.allValuesSelected {
                        byGrade = byCuisine.compactMap {
                            guard let lastGrade = $0.lastGrade else {
                                return nil
                            }
                            if filterView.grades.valueIsSelected(value: lastGrade.rawValue) {
                                return $0
                            }
                            return nil
                        }
                    } else {
                        byGrade = byCuisine
                    }
                    return byGrade
                }

        let initialChange = AnnotationChanges(annotations: [], changes: [])
        self.changes = mapChanges.scan(initialChange) { (prevChangeSet, annotations) -> AnnotationChanges in
            // this is supposed to be super fast at computing changes to an array of stuff.
            // very similar to ios13 diffable datasource, excepct that doesn't work for MapKit
            let changes = diff(old: prevChangeSet.annotations, new: annotations)

            print("number of changes = \(changes.count)")

            return AnnotationChanges(annotations: annotations, changes: changes)
        }
        .eraseToAnyPublisher()
    }

}

class MapViewController: UIViewController {

    let nycRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.75317535957268,
                                                                      longitude: -73.86879663961409),
                                       span: MKCoordinateSpan(latitudeDelta: 0.4565580072588986,
                                                              longitudeDelta: 0.503999396804474))

    @IBOutlet weak var mapView: MKMapView!

    static let model = Model<API>()
    var viewModel = MapViewModel(model: MapViewController.model)

    var cancellabbles = Set<AnyCancellable>()
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.register(CustomClusterView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)

        mapView.register(ResturantView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)

        mapView.setRegion(nycRegion, animated: true)

        viewModel
            .changes
            .subscribe(on: DispatchQueue.main)
            .sink { [weak self] annotationChanges in
                self?.applyChanges(changes: annotationChanges.changes)
            }
            .store(in: &cancellabbles)

        // Do any additional setup after loading the view.
    }

    func applyChangesOld(changes: [Change<Annotation>]) {

        print("adding changes")
        let deletions = changes.compactMap { change -> Annotation? in
            switch change {
            case let .delete(deletion):
                return deletion.item
            case let .replace(replacement):
                return replacement.oldItem
            default:
                return nil
            }
        }

        let insertions = changes.compactMap { change -> Annotation? in
            switch change {
            case let .insert(insertion):
                return insertion.item
            case let .replace(replacement):
                return replacement.newItem
            default:
                return nil
            }
        }

        if !deletions.isEmpty {
            self.mapView.removeAnnotations(deletions)
        }
        if !insertions.isEmpty {
            self.mapView.addAnnotations(insertions)
        }
        print("changes added")
    }

    func applyChanges(changes: [Change<Annotation>]) {

        var idx = changes.startIndex
        let maxRangeSize = 1000

        if changes.count == 0 {
            print("no changes")
            return
        }

        while idx < changes.endIndex {
            let startRange = idx
            let endRange = changes.index(idx, offsetBy: maxRangeSize, limitedBy: changes.endIndex) ?? changes.endIndex
            let subRange = changes[startRange..<endRange]

            DispatchQueue.main.async {
                print("adding changes [\(startRange)..<\(endRange)]")
                for change in subRange {
                    switch change {
                    case let .delete(deletion):
                        self.mapView.removeAnnotation(deletion.item)
                    case let .insert(insertion):
                        self.mapView.addAnnotation(insertion.item)
                    case let .replace(replacement):
                        self.mapView.removeAnnotation(replacement.oldItem)
                        self.mapView.addAnnotation(replacement.newItem)
                    case let .move(movement):
                        // do nothing
                        print("unexpected change .move(\(movement))")
                    }
                }
                print("changes added")
            }

            idx = endRange

        }
    }

     // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let filterTable = segue.destination as? FilterTableViewController {
            filterTable.viewModel = self.viewModel.filterViewModel
        }
    }

}

extension CLLocationCoordinate2D: Hashable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.latitude)
        hasher.combine(self.longitude)
    }

}

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

extension MapViewController: MKMapViewDelegate {
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        print("mapViewWillStartLoadingMap")
    }

    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        print("mapViewDidFinishLoadingMap")
    }

    func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
        print("mapViewWillStartRenderingMap")
    }

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView) {
        print("mapViewDidFinishRenderingMap")
    }

//    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
//        print("new region = \(mapView.region)")
//    }

//    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
//        print("mapView(_:didAdd: \(views.count)")
//    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        if let cluster = view.annotation as? MKClusterAnnotation {
            let rect = cluster.memberAnnotations.reduce(.null) { (rect, annotation) -> MKMapRect in
                rect.union(with: annotation.coordinate)
            }

            print("count =\(cluster.memberAnnotations.count) diagnalDistance= \(rect.diagnalDistance)")

            let points = Set(cluster.memberAnnotations.map { $0.coordinate })

            // we have more than one place at the same poin t
            if points.count == 1 {
                let alertController = UIAlertController(title: nil,
                                                        message: NSLocalizedString("Select", comment: ""),
                                                        preferredStyle: .actionSheet)

                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
                  // when cancel is tapped
                }
                alertController.addAction(cancelAction)

                for annotation in cluster.memberAnnotations {
                    if let title = annotation.title {
                        let action = UIAlertAction(title: title, style: .default) { (_) in
                            // when ok is tapped
                        }
                        alertController.addAction(action)
                    }

                }

                present(alertController, animated: true)
            }
        }
        if let annotation = view.annotation as? Annotation {
            print("\(annotation) found")
        }
        print("mapView(_:didSelect: \(view)")
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        print("mapView(_:didDeselect: \(view)")
    }

}
