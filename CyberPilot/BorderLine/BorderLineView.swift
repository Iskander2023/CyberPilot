//
//  BorderLine.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 4/06/25.
//

import SwiftUI

struct BorderLineView: View {
    var start: CGPoint
    var end: CGPoint

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            
            if let dash = AppConfig.BorderLine.dash {
                let style = StrokeStyle(lineWidth: AppConfig.BorderLine.lineWidth, dash: dash)
                context.stroke(path, with: .color(AppConfig.BorderLine.color), style: style)
            } else {
                context.stroke(path, with: .color(AppConfig.BorderLine.color), lineWidth: AppConfig.BorderLine.lineWidth)
            }
        }
    }
}

