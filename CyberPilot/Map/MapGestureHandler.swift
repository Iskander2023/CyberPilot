//
//  MapGestureHandler.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 17/06/25.
//

import SwiftUI



class MapGestureHandler: ObservableObject {
    @Published var scale: CGFloat = 1.0
    var lastScale: CGFloat = 1.0
    
    @Published var offset: CGSize = .zero
    var lastOffset: CGSize = .zero
    
    
    func onMagnificationChanged(_ value: CGFloat) {
        let delta = value / lastScale
        lastScale = value
        scale *= delta
        scale = max(AppConfig.MapGestureHandler.minScale, min(scale, AppConfig.MapGestureHandler.maxScale))
    }
    
    
    func onMagnificationEnded() {
        lastScale = AppConfig.MapGestureHandler.defaultScale
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
    
    func clampOffset(mapSize: CGSize, containerSize: CGSize) {
        let scaledWidth = mapSize.width * scale
        let scaledHeight = mapSize.height * scale

        let horizontalExcess = scaledWidth - containerSize.width
        let verticalExcess = scaledHeight - containerSize.height

        let maxOffsetX = horizontalExcess > 0 ? horizontalExcess / 2 : 0
        let maxOffsetY = verticalExcess > 0 ? verticalExcess / 2 : 0

        offset.width = min(max(offset.width, -maxOffsetX), maxOffsetX)
        offset.height = min(max(offset.height, -maxOffsetY), maxOffsetY)

        lastOffset = offset
    }

}

