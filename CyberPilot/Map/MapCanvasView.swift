//
//  MapCanvasView.swift
//  CyberPilot
//
//  Created by Admin on 5/06/25.
//
import SwiftUI



struct MapCanvasView: View {
    @EnvironmentObject private var mapManager: MapManager
    let map: OccupancyGridMap
    let scale: CGFloat
    let offset: CGSize
    @Binding var affectedCells: [CGPoint]

    var body: some View {
        Canvas { context, size in
            let (cellSize, offsetX, offsetY) = mapManager.calculateCellSize(
                in: size,
                map: map,
                scale: scale,
                offset: offset
            )

            for y in 0..<map.height {
                for x in 0..<map.width {
                    let index = y * map.width + x
                    let value = map.data[index]
                    let color: Color
                    
                    switch value {
                    case -1: color = .gray
                    case 0: color = .white
                    case 50: color = .green
                    case 100: color = .black
                    case 500: color = .indigo
                    default: color = .red
                    }
                    
                    let rect = CGRect(
                        x: CGFloat(x) * cellSize + offsetX,
                        y: CGFloat(y) * cellSize + offsetY,
                        width: cellSize,
                        height: cellSize
                    )
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}
