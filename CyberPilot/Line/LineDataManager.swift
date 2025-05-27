//
//  LineDataService.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 27/05/25.
//

import Foundation


class LineDataManager {
    @Published var segments: [ShapeSegment] = []
    @Published var robotPosition: CGPoint? = nil
    
    func updateLines(_ newSegments: [ShapeSegment]) {
        segments = newSegments
    }
    
    func updateRobotPosition(_ newPosition: CGPoint?) {
        robotPosition = newPosition
    }
    
    func parseSegments(from raw: [[[Double]]]) -> [ShapeSegment] {
        var segments: [ShapeSegment] = []
        
        for segmentData in raw {
            if segmentData.count == 2 {
                let start = CodablePoint(x: CGFloat(segmentData[0][0]), y: CGFloat(segmentData[0][1]))
                let end = CodablePoint(x: CGFloat(segmentData[1][0]), y: CGFloat(segmentData[1][1]))
                segments.append(.line(start: start, end: end))
            }
            if segmentData.count == 3 {
                let start = CodablePoint(x: CGFloat(segmentData[0][0]), y: CGFloat(segmentData[0][1]))
                let end = CodablePoint(x: CGFloat(segmentData[1][0]), y: CGFloat(segmentData[1][1]))
                let radius = CGFloat(segmentData[2][0])
                segments.append(.arc(start: start, end: end, radius: radius))
            }
        }
        return segments
    }
}
