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
    var lineWidth: CGFloat = 10
    
    
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: start)
            path.addLine(to: end)
            context.stroke(path, with: .color(color), lineWidth: lineWidth)
            
        }
    }
}
