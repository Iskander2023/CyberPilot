//
//  MapView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/05/25.
//
import SwiftUI



struct MapView: View {
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    let map: OccupancyGridMap?
    
    var body: some View {
        GeometryReader { geometry in
            
            if let map = map {
                ZStack {
                    Canvas { context, size in
                        logger.info("🔁 MapView updated")
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
                                case 500: 
                                    color = .indigo
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
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale *= delta
                                scale = max(0.5, min(scale, 5.0))
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                            }
                            .simultaneously(with:
                                                DragGesture()
                                .onChanged { gesture in
                                    offset = CGSize(
                                        width: lastOffset.width + gesture.translation.width,
                                        height: lastOffset.height + gesture.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                                           )
                    )
                    
                    // Кнопки масштабирования и сброса
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            VStack {
                                Button(action: {
                                    withAnimation {
                                        scale = min(scale + 0.5, 5.0)
                                    }
                                }) {
                                    Image(systemName: "plus.magnifyingglass")
                                        .padding()
                                        .background(Color.white.opacity(0.8))
                                        .clipShape(Circle())
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        scale = max(scale - 0.5, 0.5)
                                    }
                                }) {
                                    Image(systemName: "minus.magnifyingglass")
                                        .padding()
                                        .background(Color.white.opacity(0.8))
                                        .clipShape(Circle())
                                }
                                
                                Button(action: {
                                    withAnimation {
                                        scale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    }
                                }) {
                                    Image(systemName: "arrow.uturn.backward.circle")
                                        .padding()
                                        .background(Color.white.opacity(0.8))
                                        .clipShape(Circle())
                                }
                            }
                            .padding()
                        }
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            } else {
                Text("Карта не загружена")
            }
        }
    }
}


