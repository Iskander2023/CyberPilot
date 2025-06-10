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
    var cellColors: MapCellColors = MapCellColors()
    

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
                    let color = cellColors.color(for: value)
                    
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
