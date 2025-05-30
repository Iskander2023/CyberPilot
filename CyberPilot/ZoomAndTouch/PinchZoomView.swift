//
//  PinchZoomView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 30/05/25.
//

import SwiftUI
import UIKit


struct PinchZoomView: UIViewRepresentable {
    @Binding var scale: CGFloat
    @Binding var anchor: UnitPoint
    @Binding var isPinching: Bool
    @Binding var touchCount: Int
    
    func makeUIView(context: Context) -> TouchTracker {
        let view = TouchTracker()
        view.onTouchCountChanged = { count in
            self.touchCount = count
        }
        view.onPinchGesture = { gesture in
            self.handlePinch(gesture: gesture, context: context)
        }
        return view
    }
    
    func updateUIView(_ uiView: TouchTracker, context: Context) {}
    
    private func handlePinch(gesture: UIPinchGestureRecognizer, context: Context) {
        isPinching = gesture.state != .ended && gesture.state != .cancelled
        
        switch gesture.state {
        case .began, .changed:
            scale = gesture.scale
            
            if gesture.numberOfTouches >= 2, let view = gesture.view {
                let touch1 = gesture.location(ofTouch: 0, in: view)
                let touch2 = gesture.location(ofTouch: 1, in: view)
                let centerX = (touch1.x + touch2.x) / 2
                let centerY = (touch1.y + touch2.y) / 2
                
                anchor = UnitPoint(
                    x: centerX / view.bounds.width,
                    y: centerY / view.bounds.height
                )
            }
            
        case .ended, .cancelled:
            scale = 1.0
            
        default:
            break
        }
    }
}
