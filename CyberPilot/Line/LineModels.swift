//
//  LineSructs.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/05/25.
//
import SwiftUI

struct CodablePoint: Codable {
    var x: CGFloat
    var y: CGFloat

    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }

    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        x = try container.decode(CGFloat.self)
        y = try container.decode(CGFloat.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(x)
        try container.encode(y)
    }
}


struct SegmentMessage: Codable {
    let data: [[[Double]]]
    let center: CodablePoint
}

struct CachedSegments: Codable {
    let segments: [ShapeSegment]
    let robotPosition: CGPoint?
}



enum ShapeSegment: Codable, Equatable {
    case line(start: CodablePoint, end: CodablePoint)
    case arc(start: CodablePoint, end: CodablePoint, radius: CGFloat)
    
    enum CodingKeys: String, CodingKey {
        case type, start, end, radius
    }
    
    enum SegmentType: String, Codable {
        case line, arc
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(SegmentType.self, forKey: .type)
        let start = try container.decode(CodablePoint.self, forKey: .start)
        let end = try container.decode(CodablePoint.self, forKey: .end)
        
        switch type {
        case .line:
            self = .line(start: start, end: end)
        case .arc:
            let radius = try container.decode(CGFloat.self, forKey: .radius)
            self = .arc(start: start, end: end, radius: radius)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case let .line(start, end):
            try container.encode(SegmentType.line, forKey: .type)
            try container.encode(start, forKey: .start)
            try container.encode(end, forKey: .end)
            
        case let .arc(start, end, radius):
            try container.encode(SegmentType.arc, forKey: .type)
            try container.encode(start, forKey: .start)
            try container.encode(end, forKey: .end)
            try container.encode(radius, forKey: .radius)
        }
    }
}


extension ShapeSegment {
    static func == (lhs: ShapeSegment, rhs: ShapeSegment) -> Bool {
        switch (lhs, rhs) {
        case let (.line(start1, end1), .line(start2, end2)):
            return start1 == start2 && end1 == end2
        case let (.arc(start1, end1, radius1), .arc(start2, end2, radius2)):
            return start1 == start2 && end1 == end2 && abs(radius1 - radius2) < 0.001
        default:
            return false
        }
    }
    
    static func arcCenter(from p1: CGPoint, to p2: CGPoint, radius: CGFloat) -> (center: CGPoint, clockwise: Bool)? {
        let mid = CGPoint(x: (p1.x + p2.x) / 2, y: (p1.y + p2.y) / 2)
        let dx = p2.x - p1.x
        let dy = p2.y - p1.y
        let d = hypot(dx, dy)
        
        if d > 2 * abs(radius) { return nil }

        let h = sqrt(radius * radius - (d / 2) * (d / 2))
        let perpendicular = CGPoint(x: -dy / d, y: dx / d)
        let direction = radius > 0 ? 1.0 : -1.0

        let center = CGPoint(
            x: mid.x + direction * h * perpendicular.x,
            y: mid.y + direction * h * perpendicular.y
        )

        let clockwise = radius < 0
        return (center, clockwise)
    }
}



extension CodablePoint: Equatable {
    static func == (lhs: CodablePoint, rhs: CodablePoint) -> Bool {
        abs(lhs.x - rhs.x) < 0.001 && abs(lhs.y - rhs.y) < 0.001
    }
}
