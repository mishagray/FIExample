//
//  MapViewModel.swift
//  FiExample
//
//  Created by Michael Gray on 9/5/19.
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
