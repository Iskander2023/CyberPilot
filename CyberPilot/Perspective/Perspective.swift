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
    let planeDistance: CGFloat = 400
    let horizontalAngleGrad: CGFloat = 145.8
    let verticalAngleGrad: CGFloat = 122.6

    var halfDisplayHeight: CGFloat
    var displayDistance: CGFloat
    var bottomCentralPoint: CGFloat

    init(horizontalPixels: CGFloat, verticalPixels: CGFloat) {
        self.horizontalPixels = horizontalPixels
        self.verticalPixels = verticalPixels
        
        let verticalAngle = verticalAngleGrad * 2 * .pi / 360
        let halfVerticalAngle = verticalAngle / 2
        
        let bottomAngle = halfVerticalAngle
        
        if 0 < bottomAngle && bottomAngle <= .pi {
            bottomCentralPoint = planeDistance / tan(bottomAngle)
        } else {
            bottomCentralPoint = 1
        }

        let hypotenuse = sqrt(bottomCentralPoint * bottomCentralPoint + planeDistance * planeDistance)
        displayDistance = hypotenuse * cos(halfVerticalAngle)
        halfDisplayHeight = sqrt(hypotenuse * hypotenuse - displayDistance * displayDistance)
    }

    func project(points: [(CGFloat, CGFloat)]) -> [(CGFloat, CGFloat)] {
        var result: [(CGFloat, CGFloat)] = []
        let ratio = verticalPixels / (halfDisplayHeight * 2)
        
        for (x, y) in points {
            let hypotenuse = sqrt(planeDistance * planeDistance + y * y)
            let vertAngle = atan(planeDistance / y)
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
