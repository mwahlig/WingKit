//
//  Timer.swift
//  WingKit
//
//  Created by Matt Wahlig on 10/13/17.
//  Copyright © 2017 Sparo Labs. All rights reserved.
//

import Foundation

extension Timer {

    /// Create and schedule a timer that will call `block` once after the specified time.

    @discardableResult
    internal  class func after(_ interval: TimeInterval, _ block: @escaping () -> Void) -> Timer {
        let timer = Timer.new(after: interval, block)
        timer.start()
        return timer
    }

    // MARK: Create timers without scheduling

    /// Create a timer that will call `block` once after the specified time.
    ///
    /// - Note: The timer won't fire until it's scheduled on the run loop.
    ///         Use `NSTimer.after` to create and schedule a timer in one step.
    /// - Note: The `new` class function is a workaround for a crashing bug when using convenience initializers (rdar://18720947)
    internal class func new(after interval: TimeInterval, _ block: @escaping () -> Void) -> Timer {
        return CFRunLoopTimerCreateWithHandler(kCFAllocatorDefault, CFAbsoluteTimeGetCurrent() + interval, 0, 0, 0) { _ in
            block()
        }
    }

    /// Schedule this timer on the run loop
    ///
    /// By default, the timer is scheduled on the current run loop for the default mode.
    /// Specify `runLoop` or `modes` to override these defaults.

    internal func start(runLoop: RunLoop = .current, modes: RunLoopMode...) {
        let modes = modes.isEmpty ? [.defaultRunLoopMode] : modes

        for mode in modes {
            runLoop.add(self, forMode: mode)
        }
    }
}
