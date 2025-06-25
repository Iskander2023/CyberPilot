//
//  Perspective.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 27/04/25.
//

import SwiftUI


struct Perspective {
    let horizontalPixels: CGFloat
    let verticalPixels: CGFloat
    var halfDisplayHeight: CGFloat
    var displayDistance: CGFloat
    var bottomCentralPoint: CGFloat

    init(horizontalPixels: CGFloat, verticalPixels: CGFloat) {
        self.horizontalPixels = horizontalPixels
        self.verticalPixels = verticalPixels
        
        let verticalAngle = AppConfig.Perspective.verticalAngleGrad * 2 * .pi / 360
        let halfVerticalAngle = verticalAngle / 2
        
        let bottomAngle = halfVerticalAngle
        
        if 0 < bottomAngle && bottomAngle <= .pi {
            bottomCentralPoint = AppConfig.Perspective.planeDistance / tan(bottomAngle)
        } else {
            bottomCentralPoint = 1
        }

        let hypotenuse = sqrt(bottomCentralPoint * bottomCentralPoint + AppConfig.Perspective.planeDistance * AppConfig.Perspective.planeDistance)
        displayDistance = hypotenuse * cos(halfVerticalAngle)
        halfDisplayHeight = sqrt(hypotenuse * hypotenuse - displayDistance * displayDistance)
    }

    func project(points: [(CGFloat, CGFloat)]) -> [(CGFloat, CGFloat)] {
        var result: [(CGFloat, CGFloat)] = []
        let ratio = verticalPixels / (halfDisplayHeight * 2)
        
        for (x, y) in points {
            let hypotenuse = sqrt(AppConfig.Perspective.planeDistance * AppConfig.Perspective.planeDistance + y * y)
            let vertAngle = atan(AppConfig.Perspective.planeDistance / y)
            let yDist = -displayDistance * tan(vertAngle)
            let dispHyp = sqrt(yDist * yDist + displayDistance * displayDistance)
            let xDist = x * dispHyp / hypotenuse

            let pixelX = horizontalPixels / 2 + (xDist * ratio)
            let pixelY = verticalPixels / 2 + (yDist * ratio)
            
            result.append((pixelX, pixelY))
        }
        return result
    }
}
