//
//  IndoorMapView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/05/25.
//
import SwiftUI
import Yams


struct MapView: View {
    let map: OccupancyGridMap?

    var body: some View {
        GeometryReader { geometry in
            if let map = map {
                Canvas { context, size in
                    let cellWidth = size.width / CGFloat(map.width)
                    let cellHeight = size.height / CGFloat(map.height)
                    print("Data count: \(map.data.count), Expected: \(map.width * map.height)")
                    for y in 0..<map.height {
                        for x in 0..<map.width {
                            let index = y * map.width + x
                            let value = map.data[index]

                            let color: Color
                            switch value {
                            case -1: color = .gray
                            case 0: color = .white
                            case 100: color = .black
                            default: color = .red
                            }

                            let rect = CGRect(
                                x: CGFloat(x) * cellWidth,
                                y: CGFloat(map.height - y - 1) * cellHeight,
                                width: cellWidth,
                                height: cellHeight
                            )

                            context.fill(Path(rect), with: .color(color))
                        }
                    }
                }
            } else {
                Text("Карта не загружена")
            }
        }
    }
}





