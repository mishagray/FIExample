//
//  FilterViewModel.swift
//  FiExample
//
//  Created by Michael Gray on 9/4/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import UIKit
import Combine

class FilterViewModel: ObservableObject {

    static let allCuisineValues = Cuisine.allCases.map { $0.rawValue }.sorted()
    static let allGradeValues = Grade.allCases.map { $0.rawValue }

    let cuisines: SelectionSet
    let grades: SelectionSet

    public let objectWillChange: ObservableObjectPublisher

    private let downstream: AnyCancellable

    init(cuisines: SelectionSet = SelectionSet(values: allCuisineValues),
         grades: SelectionSet = SelectionSet(values: allGradeValues)) {

        self.cuisines = cuisines
        self.grades = grades

        let changePublisher = ObservableObjectPublisher()

        self.objectWillChange = changePublisher

        self.downstream = cuisines.objectWillChange
            .merge(with: grades.objectWillChange)
            .sink { _ in
                changePublisher.send()
            }

    }
}
