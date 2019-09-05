//
//  CombineExtras.swift
//  FiExample
//
//  Created by Michael Gray on 9/5/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Combine
import Foundation

extension ObservableObject where Self.ObjectWillChangePublisher == ObservableObjectPublisher {

    // erases to AnyPublisher<Self, Never>
    // questions? Is there a performance cost to AnyPublisher
    // OpenCombine adds a small performance hit to thier implementation

    typealias ObjectDidChangePublisher =
        Publishers.Map<
            Publishers.Concatenate<Publishers.Sequence<[ObservableObjectPublisher.Output],
                                                       ObservableObjectPublisher.Failure>,
                                   Publishers.ReceiveOn<ObservableObjectPublisher, RunLoop>>,
            Self>

    // will always fire on subscribe.
    // will fire AFTER object has changed.
    var objectDidChange: ObjectDidChangePublisher {
        return self.objectWillChange
            // receive(on:) will let the sink run in the NEXT main loop cycle.
            // this will basically turn our objectWillChange into objectDidChange
            .receive(on: RunLoop.main)
            // always send one void at the beginning, so that combineLatest will fire.
            .prepend(())
            .map { _ in self }
    }
}
