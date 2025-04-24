//
//  Perspective.swift
//  CyberPilot
//
//  Created by Admin on 17/04/25.
//
import SwiftUI
import CoreGraphics


//
//class Perspective {
//    var horizontalAngle: Double = 0
//    var verticalAngle: Double = 0
//    var planeDistance: Double = 0
//    var horizontalPixels: Int = 0
//    var verticalPixels: Int = 0
//    
//    init(parameters: [String: Any]) {
//        if let angle = parameters["horizontalAngle"] as? Double {
//            self.horizontalAngle = degreesToRadians(angle)
//        }
//        if let angle = parameters["verticalAngle"] as? Double {
//            self.verticalAngle = degreesToRadians(angle)
//        }
//        if let distance = parameters["planeDistance"] as? Double {
//            self.planeDistance = distance
//        }
//        if let pixels = parameters["horizontalPixels"] as? Int {
//            self.horizontalPixels = pixels
//        }
//        if let pixels = parameters["verticalPixels"] as? Int {
//            self.verticalPixels = pixels
//        }
//    }
//    
//    private func degreesToRadians(_ degrees: Double) -> Double {
//        return degrees * .pi / 180.0
//    }
//    
//    func calculateDirectionArc(wheelAngle: Double, width: CGFloat, height: CGFloat) -> Path {
//        let radius: CGFloat = 150
//        let centerY = height - 200
//        
//        // Нормализация угла колеса: 270° - прямо, 0° - право, 90° - назад, 180° - лево
//        let normalizedAngle = (wheelAngle + 90).truncatingRemainder(dividingBy: 360)
//        let sensitivityFactor: CGFloat = 0.8
//        let angle = CGFloat(normalizedAngle) * sensitivityFactor
//        
//        return Path { path in
//            let start = CGPoint(x: width * 0.2, y: height - 40)
//            let end = CGPoint(
//                x: width * 0.2 + radius * sin(angle * .pi / 180),
//                y: centerY - radius * cos(angle * .pi / 180)
//            )
//            
//            let control = CGPoint(
//                x: (start.x + end.x) / 2,
//                y: (start.y + end.y) / 2 - abs(radius * 0.3 * angle * .pi / 180)
//            )
//            
//            path.move(to: start)
//            path.addQuadCurve(to: end, control: control)
//        }
//    }
//    
//    func calculate(points: [(x: Double, y: Double)]) -> [CGPoint] {
//        var result = [CGPoint]()
//        let ratio = Double(verticalPixels) / (Double(verticalPixels) * 2)
//        
//        for point in points {
//            let hypotenuse = sqrt(pow(planeDistance, 2) + pow(point.y, 2))
//            let vertAngle = atan(planeDistance / point.y)
//            let horizAngle = atan(point.x / hypotenuse)
//            
//            let yDist = -planeDistance * tan(vertAngle)
//            let dispHyp = sqrt(pow(yDist, 2) + pow(planeDistance, 2))
//            let xDist = point.x * dispHyp / hypotenuse
//            
//            let pixelX = CGFloat(horizontalPixels) / 2 + CGFloat(xDist * ratio)
//            let pixelY = CGFloat(verticalPixels) / 2 + CGFloat(yDist * ratio)
//            
//            result.append(CGPoint(x: pixelX, y: pixelY))
//        }
//        
//        return result
//    }
//}
