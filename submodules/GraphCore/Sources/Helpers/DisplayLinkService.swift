







import Foundation
#if os(macOS)
import Cocoa
#else
import UIKit
#endif
import CoreGraphics

public protocol DisplayLinkListner: AnyObject {
    func update(delta: TimeInterval)
}


class DisplayLinkService {
    let listners = NSHashTable<AnyObject>.weakObjects()
    static let shared = DisplayLinkService()

    public func add(listner: DisplayLinkListner) {
        listners.add(listner)
        startDisplayLink()
    }

    public func remove(listner: DisplayLinkListner) {
        listners.remove(listner)

        if listners.count == 0 {
            stopDisplayLink()
        }
    }







































    private init() {
        dispatchSourceTimer.schedule(deadline: .now() + 1.0 / 60, repeating: 1.0 / 60)
        dispatchSourceTimer.setEventHandler {
            DispatchQueue.main.sync {
                self.fire()
            }
        }
    }

    private var dispatchSourceTimer = DispatchSource.makeTimerSource(flags: [], queue: .global(qos: .userInteractive))
    private var dispatchSourceTimerStarted: Bool = false
    private var previousTickTime = 0.0

    private func startDisplayLink() {
        guard !dispatchSourceTimerStarted else { return }
        dispatchSourceTimerStarted = true
        previousTickTime = CACurrentMediaTime()
        dispatchSourceTimer.resume()
    }

    private func stopDisplayLink() {
        guard dispatchSourceTimerStarted else { return }
        dispatchSourceTimerStarted = false
        dispatchSourceTimer.suspend()
    }

    public func fire() {
        let currentTime = CACurrentMediaTime()

        let delta = currentTime - previousTickTime
        previousTickTime = currentTime
        let allListners = listners.allObjects
        var hasListners = false
        for listner in allListners {
            (listner as! DisplayLinkListner).update(delta: delta)
            hasListners = true
        }

        if !hasListners {
            stopDisplayLink()
        }
    }
}
