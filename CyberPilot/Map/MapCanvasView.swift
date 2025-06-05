//
//  MapCanvasView.swift
//  CyberPilot
//
//  Created by Admin on 5/06/25.
//
import SwiftUI


struct MapCanvasView: View {
    let map: OccupancyGridMap
    let scale: CGFloat
    let offset: CGSize

    var body: some View {
        Canvas { context, size in
            let mapAspect = CGFloat(map.width) / CGFloat(map.height)
            let viewAspect = size.width / size.height
            let cellSize: CGFloat
            let totalWidth: CGFloat
            let totalHeight: CGFloat
            if mapAspect > viewAspect {
                cellSize = size.width / CGFloat(map.width) * scale
                totalWidth = size.width * scale
                totalHeight = CGFloat(map.height) * cellSize
            } else {
                cellSize = size.height / CGFloat(map.height) * scale
                totalHeight = size.height * scale
                totalWidth = CGFloat(map.width) * cellSize
            }
            let offsetX = (size.width - totalWidth) / 2 + offset.width
            let offsetY = (size.height - totalHeight) / 2 + offset.height

            for y in 0..<map.height {
                for x in 0..<map.width {
                    let index = y * map.width + x
                    let value = map.data[index]
                    let color: Color
                    switch value {
                    case -1: color = .gray
                    case 0: color = .white
                    case 100: color = .black
                    case 500: color = .indigo
                    default: color = .red
                    }
                    let rect = CGRect(
                        x: CGFloat(x) * cellSize + offsetX,
                        y: CGFloat(map.height - y - 1) * cellSize + offsetY,
                        width: cellSize,
                        height: cellSize
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}
