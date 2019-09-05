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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] annotationChanges in
                self?.applyChanges(changes: annotationChanges.changes)
            }
            .store(in: &cancellables)

        MapViewController.model.refresh()

        // Do any additional setup after loading the view.
    }

    func applyChanges(changes: [Change<Annotation>]) {

        for change in changes {
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

            // we have more than one place at the same poin t
            if rect.diagnalDistance < 10.0 {
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
