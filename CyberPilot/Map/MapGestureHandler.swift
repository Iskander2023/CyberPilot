//
//  MapGestureHandler.swift
//  CyberPilot
//
//  Created by Admin on 17/06/25.
//

import SwiftUI
import Combine


class MapGestureHandler: ObservableObject {
    @Published var scale: CGFloat = 1.0
    var lastScale: CGFloat = 1.0
    
    @Published var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    
    
    func onMagnificationChanged(_ value: CGFloat) {
        let delta = value / lastScale
        lastScale = value
        scale *= delta
        scale = max(0.5, min(scale, 5.0))
    }
    
    
    func onMagnificationEnded() {
        lastScale = 1
    }
       
    
    func onDragGestureChanged(gesture: CGSize) {
            offset = CGSize(
                width: lastOffset.width + gesture.width,
                height: lastOffset.height + gesture.height
            )
    }
    
    func onDragGestureEnded() {
            lastOffset = offset
    }
    
                    
}


//
//class MapGestureHandler: ObservableObject {
//    @Published var scale: CGFloat = 1.0
//    var lastScale: CGFloat = 1.0
//    
//    @Published var offset: CGSize = .zero
//    var lastOffset: CGSize = .zero
//    
//    
//    func onMagnificationChanged(_ value: CGFloat) {
//        let delta = value / lastScale
//        lastScale = value
//        scale *= delta
//        scale = max(0.5, min(scale, 5.0))
//    }
//    
//    
//    func onMagnificationEnded() {
//        lastScale = 1
//    }
//       
//    
//    func onDragGestureChanged(gesture: CGSize, isAddingBorder: Bool) {
//        if !isAddingBorder {
//            offset = CGSize(
//                width: lastOffset.width + gesture.width,
//                height: lastOffset.height + gesture.height
//            )
//        }
//    }
//    
//    func onDragGestureEnded(isAddingBorder: Bool) {
//        if isAddingBorder == false {
//            lastOffset = offset
//        }
//    }
//    
//                    
//}
