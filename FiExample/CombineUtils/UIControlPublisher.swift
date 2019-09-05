//
//  UIControlPublisher.swift
//  FiExample
//
//  Created by Michael Gray on 9/4/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import UIKit
import Combine

// THANKS TO https://www.avanderlee.com/swift/custom-combine-publisher/

/// A custom subscription to capture UIControl target events.
final class UIControlSubscription<SubscriberType: Subscriber,
                                  Control: UIControl>: Subscription where SubscriberType.Input == Control {
    private var subscriber: SubscriberType?
    private var control: Control?
    private let event: UIControl.Event

    init(subscriber: SubscriberType, control: Control, event: UIControl.Event) {
        self.subscriber = subscriber
        self.control = control
        self.event = event
        control.addTarget(self, action: #selector(eventHandler), for: event)
    }

    func request(_ demand: Subscribers.Demand) {
        // We do nothing here as we only want to send events when they occur.
        // See, for more info: https://developer.apple.com/documentation/combine/subscribers/demand
    }

    func cancel() {
        subscriber = nil
        control?.removeTarget(self, action: #selector(eventHandler), for: event)
        control = nil
    }

    @objc private func eventHandler() {
        guard let subscriber = subscriber, let control = control else {
            return
        }
        _ = subscriber.receive(control)
    }
}

/// A custom `Publisher` to work with our custom `UIControlSubscription`.
struct UIControlPublisher<Control: UIControl>: Publisher {

    typealias Output = Control
    typealias Failure = Never

    let control: Control
    let controlEvents: UIControl.Event

    init(control: Control, events: UIControl.Event) {
        self.control = control
        self.controlEvents = events
    }

    func receive<S>(subscriber: S) where S: Subscriber,
                                         S.Failure == UIControlPublisher.Failure,
                                         S.Input == UIControlPublisher.Output {
        let subscription = UIControlSubscription(subscriber: subscriber, control: control, event: controlEvents)
        subscriber.receive(subscription: subscription)
    }
}

/// Extending the `UIControl` types to be able to produce a `UIControl.Event` publisher.
protocol CombineCompatible { }
extension UIControl: CombineCompatible { }
extension CombineCompatible where Self: UIControl {
    func publisher(for events: UIControl.Event) -> UIControlPublisher<Self> {
        return UIControlPublisher(control: self, events: events)
    }
}
