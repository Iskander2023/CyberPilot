//
//  TouchCountView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 30/05/25.
//
import SwiftUI




final class TouchTracker: UIView {
    private var activeTouches = Set<UITouch>()
    private var gestureTouchCount = 0
    private var lastReportedCount = 0
    var onTouchCountChanged: ((Int) -> Void)?
    var onPinchGesture: ((UIPinchGestureRecognizer) -> Void)?
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    private lazy var pinchRecognizer: UIPinchGestureRecognizer = {
        let recognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        recognizer.delegate = self
        return recognizer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addGestureRecognizer(pinchRecognizer)
        self.isMultipleTouchEnabled = true
    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        touches.forEach { activeTouches.insert($0) }
        updateTouchCount(force: true)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        updateTouchCount()
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touches.forEach { activeTouches.remove($0) }
        updateTouchCount(force: true)
    }
    
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        touches.forEach { activeTouches.remove($0) }
        gestureTouchCount = pinchRecognizer.numberOfTouches
        updateTouchCount(force: true)
    }
    
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        gestureTouchCount = gesture.numberOfTouches
        onPinchGesture?(gesture)
        
        if gesture.state == .ended || gesture.state == .cancelled {
            gestureTouchCount = 0
        }
        
        updateTouchCount()
    }
    
    private func updateTouchCount(force: Bool = false) {
        let count = max(activeTouches.count, gestureTouchCount)
        if force || count != lastReportedCount {
            lastReportedCount = count
            DispatchQueue.main.async {
                self.onTouchCountChanged?(count)
            }
        }
    }
}

extension TouchTracker: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                         shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

