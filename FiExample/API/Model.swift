//
//  Model.swift
//  FiExample
//
//  Created by Michael Gray on 9/1/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Foundation
import Combine

protocol ModelType {

    var resturants: CurrentValueSubject<[Restaurant], Never> { get }
    var lastError: CurrentValueSubject<Error?, Never> { get }

    func refresh()
}

class Model<API: APIType>: ModelType {

    let resturants = CurrentValueSubject<[Restaurant], Never>([])
    let lastError = CurrentValueSubject<Error?, Never>(nil)

    private var lastRefresh: AnyCancellable?

    func refresh() {
        self.lastRefresh = API.loadResturants().sink(receiveCompletion: { [weak self] (completion) in
            guard let `self` = self else {
                return
            }
            if case let .failure(error) = completion {
                print("error! \(error)")
                self.lastError.send(error)
            } else {
                self.lastError.send(nil)
            }
        }, receiveValue: { [weak self] (resturants) in
            self?.resturants.send(resturants)
        })
    }
}
