//
//  LineView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/05/25.
//
import SwiftUI



struct LineView: View {
    var robotManager: RobotManager
    @ObservedObject var lineStore: LineStore
    //@ObservedObject var controller: TouchController
    @State private var scale: CGFloat = 2.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    
    var body: some View {
        GeometryReader { geometry in
            if lineStore.lines.isEmpty {
                Text("Линии не загружены")
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                ZStack {
                    ForEach(lineStore.lines) { line in
                        Path { path in
                            guard let first = line.points.first else { return }
                            let firstPoint = transformPoint(first.cgPoint, in: geometry)
                            path.move(to: firstPoint)
                            
                            line.points.dropFirst().forEach { point in
                                path.addLine(to: transformPoint(point.cgPoint, in: geometry))
                            }
                        }
                        .stroke(Color.blue, lineWidth: 2)
                    }
                    if let robotPos = lineStore.robotPosition {
                        let transformed = transformPoint(robotPos, in: geometry)
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                            .position(transformed)
                    }
                    
                }
//                .gesture(
//                    MagnificationGesture()
//                        .onChanged { value in
//                            let delta = value / lastScale
//                            lastScale = value
//                            scale *= delta
//                            scale = max(0.5, min(scale, 5.0))
//                        }
//                        .onEnded { _ in
//                            lastScale = 1.0
//                        }
//                        .simultaneously(with:
//                                            DragGesture()
//                            .onChanged { gesture in
//                                offset = CGSize(
//                                    width: lastOffset.width + gesture.translation.width,
//                                    height: lastOffset.height + gesture.translation.height
//                                )
//                            }
//                            .onEnded { _ in
//                                lastOffset = offset
//                            }
//                                       )
//                )
                //TouchPadGestureView(controller: controller)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
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
        }
    }
    
    
    private func transformPoint(_ point: CGPoint, in geometry: GeometryProxy) -> CGPoint {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        return CGPoint(
            x: center.x + (point.x * scale) + offset.width,
            y: center.y + (point.y * scale) + offset.height
        )
    }

}

