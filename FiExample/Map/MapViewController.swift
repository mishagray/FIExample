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

//    let changes =
//        CurrentValueSubject<AnnotationChanges, Never>(AnnotationChanges(annotations: [],
//                                                                        changes: []))

    var filterViewModel: FilterViewModel

    // swiftlint:disable:next function_body_length
    init<Model: ModelType>(model: Model) {

        let filters = FilterViewModel()
        self.filterViewModel = filters

        // let's defer our publisher so we don't actually fire up the model publisher, until we get a subscriber.
        // 'safer' behavior inside of init()
        let annotations = Deferred<AnyPublisher<[Annotation], Never>> {
            // we can do refresh here, since we are delaying until subscription
            model.refresh()
            return model
                .resturants
                .map {
                    // filter out bad/unmappable data
                    $0.filter {
                        let hasTitle = !$0.name.isEmpty
                        return hasTitle && $0.hasValidCoordinate
                    }
                    // convert them to Annotation
                    .map { Annotation(resturant: $0) }
                }
                .eraseToAnyPublisher()
        }

        let viewModelChanges = filterViewModel.objectDidChange
                // let's add some debounce time so we will ignore
                // changes until the user has stopped selecting them
                .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
                .handleEvents(receiveOutput: { _ in
                    print("got objectDidChange")
                })

        // let's mixup the resturants signal from the API with the user's filters.
        let mapChanges =
            Publishers
                .CombineLatest(viewModelChanges, annotations)
                .map { filterView, annotations -> [Annotation] in

                    // filter out Annotations that the user doesn't want to see
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
        // this is sort of like reduce.
        // this will let us compute what Annotations have been added or removed by either
        // API or by the filtering.
        self.changes = mapChanges.scan(initialChange) { (prevChangeSet, annotations) -> AnnotationChanges in

            // this is supposed to be super fast at computing changes to an array of stuff.
            // very similar to ios 13 diffable datasource
            // but they didn't add diffable datasources to Mapkit, so we will bake our own.
            // super fast even on 25k items.
            let changes = DeepDiff.diff(old: prevChangeSet.annotations, new: annotations)

            print("number of changes = \(changes.count)")

            return AnnotationChanges(annotations: annotations, changes: changes)
        }
        .eraseToAnyPublisher()

    }

}

class MapViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    @IBOutlet weak var mapView: MKMapView!

    static let nycRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.75317535957268,
                                       longitude: -73.86879663961409),
        span: MKCoordinateSpan(latitudeDelta: 0.4565580072588986,
                               longitudeDelta: 0.503999396804474))

    static let model = Model<API>()
    var viewModel = MapViewModel(model: MapViewController.model)

    var cancellables = Set<AnyCancellable>()
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        mapView.register(CustomClusterView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)

        mapView.register(ResturantView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)

        mapView.setRegion(MapViewController.nycRegion, animated: true)

        viewModel
            .changes
            .subscribe(on: DispatchQueue.main)
            .sink { [weak self] annotationChanges in
                self?.applyChanges(changes: annotationChanges.changes)
            }
            .store(in: &cancellables)

        MapViewController.model.refresh()

        // Do any additional setup after loading the view.
    }

    func applyChanges(changes: [Change<Annotation>]) {

        var idx = changes.startIndex
        let maxRangeSize = 50000

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

        if let detailView = segue.destination as? ResturantTableViewController, let annotation = sender as? Annotation {
            detailView.annotation = annotation
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

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        self.activityIndicator.stopAnimating()
    }

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
                        let action = UIAlertAction(title: title, style: .default) { _ in
                            self.performSegue(withIdentifier: "showResturant",
                                              sender: annotation)
                        }
                        alertController.addAction(action)
                    }

                }

                present(alertController, animated: true)
            }
        }
        if let annotation = view.annotation as? Annotation {
            print("\(annotation) found")

            self.performSegue(withIdentifier: "showResturant",
                              sender: annotation)
        }
        print("mapView(_:didSelect: \(view)")
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        print("mapView(_:didDeselect: \(view)")
    }

}
