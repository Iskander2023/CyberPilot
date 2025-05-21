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

struct Line: Identifiable, Codable {
    var id = UUID()
    var points: [CodablePoint]
}

struct LineMessage: Codable {
    let type: String
    let data: [[CodablePoint]]
}

struct CachedLines: Codable {
    let lines: [Line]
    let robotPosition: CGPoint?
}
