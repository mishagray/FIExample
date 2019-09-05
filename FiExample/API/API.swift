//
//  Model.swift
//  FiExample
//
//  Created by Michael Gray on 9/1/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Foundation

import Combine

protocol APIType {
    associatedtype Failure

    static func loadResturants() -> AnyPublisher<[Restaurant], Error>

}

extension APIType {
    typealias ResturantsPublisher = AnyPublisher<[Restaurant], Error>
}

enum API: APIType {
    enum Failure: Error {
        case unexpectedServerResponse
    }

    static var dataUrl =
        URL(string: "https://raw.githubusercontent.com/mongodb/docs-assets/primer-dataset/primer-dataset.json")!

    static func loadResturants() -> AnyPublisher<[Restaurant], Error> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        return URLSession.shared
            .dataTaskPublisher(for: dataUrl)
            .map { $0.data }
            .map { String(data: $0, encoding: .utf8) }
            .map { $0?.split(separator: "\n") ?? [] }
            .map { subStrings -> [Data] in
                return subStrings.compactMap { $0.data(using: $0.fastestEncoding) }
            }
            .tryMap { datas -> [Restaurant] in
                try datas.map {
                    try decoder.decode(Restaurant.self, from: $0)
                }
            }
            .eraseToAnyPublisher()

    }

}
