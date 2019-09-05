//
//  CombineCompatability.swift
//  FiExample
//
//  Created by Michael Gray on 9/4/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import Foundation

import Combine
import OpenCombine

// CHANGE THIS LINE to switch
typealias CombinePackage = UsingNativeCombine
// typealias CombinePackage = UsingOpenCombine

@available(OSX 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
enum UsingNativeCombine {
    typealias AnyCancellable = Combine.AnyCancellable
    typealias AnySubscriber = Combine.AnySubscriber
    typealias AnyPublisher = Combine.AnyPublisher
    typealias CombineIdentifier = Combine.CombineIdentifier
    typealias CurrentValueSubject = Combine.CurrentValueSubject
    typealias ObservableObject = Combine.ObservableObject
    typealias ObservableObjectPublisher = Combine.ObservableObjectPublisher
    typealias PassthroughSubject = Combine.PassthroughSubject

    typealias Publisher = Combine.Publisher
    typealias Publishers = Combine.Publishers
    typealias Subscriber = Combine.Subscriber
    typealias Subscribers = Combine.Subscribers
    typealias Subscription = Combine.Subscription
    typealias Subject = Combine.Subject
}

protocol OpenObservableObject: AnyObject {

    /// The type of publisher that emits before the object has changed.
    associatedtype ObjectWillChangePublisher: OpenCombine.Publisher = UsingOpenCombine.ObservableObjectPublisher
        where Self.ObjectWillChangePublisher.Failure == Never

    /// A publisher that emits before the object has changed.
    var objectWillChange: Self.ObjectWillChangePublisher { get }
}

enum UsingOpenCombine {
    typealias ObservableObjectPublisher = OpenCombine.PassthroughSubject<Void, Never>

    typealias AnyCancellable = OpenCombine.AnyCancellable
    typealias AnySubscriber = OpenCombine.AnySubscriber
    typealias AnyPublisher = OpenCombine.AnyPublisher
    typealias CombineIdentifier = OpenCombine.CombineIdentifier
    typealias CurrentValueSubject = OpenCombine.CurrentValueSubject
    typealias ObservableObject = OpenObservableObject
    typealias PassthroughSubject = OpenCombine.PassthroughSubject
    typealias Publisher = OpenCombine.Publisher
    typealias Publishers = OpenCombine.Publishers
    typealias Subscriber = OpenCombine.Subscriber
    typealias Subscribers = OpenCombine.Subscribers
    typealias Subscription = OpenCombine.Subscription
    typealias Subject = OpenCombine.Subject

}

typealias AnyCancellable = CombinePackage.AnyCancellable
typealias AnySubscriber = CombinePackage.AnySubscriber
typealias AnyPublisher = CombinePackage.AnyPublisher
typealias CombineIdentifier = CombinePackage.CombineIdentifier
typealias CurrentValueSubject = CombinePackage.CurrentValueSubject
typealias ObservableObject = CombinePackage.ObservableObject
typealias ObservableObjectPublisher = CombinePackage.ObservableObjectPublisher
typealias PassthroughSubject = CombinePackage.PassthroughSubject
typealias Publisher = CombinePackage.Publisher
typealias Publishers = CombinePackage.Publishers
typealias Subscriber = CombinePackage.Subscriber
typealias Subscribers = CombinePackage.Subscribers
typealias Subscription = CombinePackage.Subscription
typealias Subject = CombinePackage.Subject
