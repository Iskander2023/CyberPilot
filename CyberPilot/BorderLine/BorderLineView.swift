//
//  BorderLine.swift
//  CyberPilot
//
//  Created by Admin on 4/06/25.
//

import SwiftUI

struct BorderLineView: View {
    var start: CGPoint
    var end: CGPoint
    var color: Color = .red
    var lineWidth: CGFloat = 5
    var dash: [CGFloat]? = nil

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            
            if let dash = dash {
                let style = StrokeStyle(lineWidth: lineWidth, dash: dash)
                context.stroke(path, with: .color(color), style: style)
            } else {
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }
        }
    }
}

