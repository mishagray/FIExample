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

    init<Model: ModelType>(model: Model) {

        // let's defer our publisher so we don't actually fire up the model publisher, until we get a subscriber.
        // 'safer' behavior inside of init()

        self.changes = Deferred { () -> CurrentValueSubject<[Restaurant], Never> in
            model.refresh()
            return model.resturants
        }
        .map {
            $0.map { Annotation(resturant: $0) }
                .filter { $0.hasLatLong }
        }
        .scan(AnnotationChanges(annotations: [], changes: [])) { (prevChangeSet, annotations) -> AnnotationChanges in
            // this is supposed to be super fast at computing changes to an array of stuff.
            // very similar to ios13 diffable datasource, excepct that doesn't work for MapKit
            let changes = diff(old: prevChangeSet.annotations, new: annotations)

            return AnnotationChanges(annotations: annotations, changes: changes)
        }
        .eraseToAnyPublisher()
    }

}

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    static let model = Model<API>()
    var viewModel = MapViewModel(model: MapViewController.model)

    var cancellabbles = Set<AnyCancellable>()
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.register(CustomClusterView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)

        mapView.register(ResturantView.self,
                         forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
