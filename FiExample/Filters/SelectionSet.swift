//
//  SelectionSet.swift
//  FiExample
//
//  Created by Michael Gray on 9/4/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Foundation
import Combine

class SelectionSet: ObservableObject {
    let allValues: [String]
    var selectedValues: Set<String>

    public let objectWillChange =  ObservableObjectPublisher()

    init(values: [String] = []) {
        allValues = values
        selectedValues = Set(values)

        assert(allValues.count == selectedValues.count, "duplicates in allValues are not allowed!")
    }
    init(values: [String], selectedValues set: Set<String>) {
        allValues = values.sorted()
        selectedValues = set

        assert(selectedValues.intersection(allValues).count == selectedValues.count,
               "selectedValues may contain a value that is not in allValues")

    }
}

extension SelectionSet {

    var allValuesSelected: Bool {
        selectedValues.count == allValues.count
    }

    func valueIsSelected(value: String) -> Bool {
        return self.selectedValues.contains(value)
    }

    func indexIsSelected(index: Int) -> Bool {
        guard index < allValues.count else {
            fatalError("out of index error index: \(index) in \(#function)")
        }
        let value = allValues[index]
        return self.selectedValues.contains(value)
    }

    func setSelected(index: Int, isSelected: Bool) {
        guard index < allValues.count else {
            fatalError("out of index error index: \(index) in \(#function)")
        }
        let value = allValues[index]
        self.setSelected(value: value, isSelected: isSelected)
   }
    func setSelected(value: String, isSelected: Bool) {
        // the combine mystery... why is this update BEFORE the change? interesting.
        self.objectWillChange.send()
        if isSelected {
            self.selectedValues.insert(value)
        } else {
            self.selectedValues.remove(value)
        }
    }
    func selectAll() {
        self.objectWillChange.send()
        selectedValues = Set(allValues)
    }

    func selectNone() {
        self.objectWillChange.send()
        selectedValues.removeAll()
    }

}
