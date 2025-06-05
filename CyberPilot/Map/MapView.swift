//
//  MapView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/05/25.
//
import SwiftUI



struct MapView: View {
    @EnvironmentObject private var mapManager: MapManager
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var firstTouch: CGPoint? = nil
    @State private var secondTouch: CGPoint? = nil
    @State private var borderLines: [BorderLine] = []
    @State var isAddingBorder = false
    @State private var currentDragLocation: CGPoint? = nil
    
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)

    var body: some View {
        GeometryReader { geometry in
            if let map = mapManager.map {
                ZStack {
                    MapCanvasView(map: map, scale: scale, offset: offset)
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
                            )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { gesture in
                                    
                                    if isAddingBorder == false {
                                        offset = CGSize(
                                            width: lastOffset.width + gesture.translation.width,
                                            height: lastOffset.height + gesture.translation.height
                                        )
                                    }
                                    
                                    if isAddingBorder {
                                        if firstTouch == nil {
                                            firstTouch = gesture.location
                                        } else {
                                            currentDragLocation = gesture.location
                                        }
                                    }
                                }
                                .onEnded { gesture in
                                    if isAddingBorder == false {
                                        lastOffset = offset
                                    }
                                    if isAddingBorder {
                                        handleTap(at: gesture.location, in: geometry)
                                        currentDragLocation = nil
                                    }
                                }
                        )

                    // Постоянные линии
                    ForEach(borderLines) { line in
                        BorderLineView(
                            start: convertToScreenCoordinates(line.start, in: geometry),
                            end: convertToScreenCoordinates(line.end, in: geometry)
                        )
                        .allowsHitTesting(false)
                    }

                    // Временная линия (тянется от первой точки к курсору)
                    if isAddingBorder, let start = firstTouch, let current = currentDragLocation {
                        BorderLineView(
                            start: start,
                            end: current,
                            color: .red,
                            lineWidth: 2,
                            dash: [5]
                        )
                        .allowsHitTesting(false)
                    }

                    BorderPointsView(first: firstTouch, second: secondTouch)

                    MapControlsView(
                        scale: $scale,
                        offset: $offset,
                        lastOffset: $lastOffset,
                        borderLines: $borderLines,
                        isAddingBorder: $isAddingBorder
                    )
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
            } else {
                Text("Карта не загружена")
            }
        }
    }

    // Преобразование: экран → карта
    func convertToMapCoordinates(_ point: CGPoint, in geometry: GeometryProxy) -> CGPoint {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let translatedX = (point.x - center.x - offset.width) / scale
        let translatedY = (point.y - center.y - offset.height) / scale
        return CGPoint(x: translatedX, y: translatedY)
    }

    // Преобразование: карта → экран
    func convertToScreenCoordinates(_ point: CGPoint, in geometry: GeometryProxy) -> CGPoint {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let screenX = point.x * scale + center.x + offset.width
        let screenY = point.y * scale + center.y + offset.height
        return CGPoint(x: screenX, y: screenY)
    }

    // Обработка касания
    func handleTap(at location: CGPoint, in geometry: GeometryProxy) {
        if firstTouch == nil && secondTouch == nil {
            firstTouch = location
        } else if firstTouch != nil && secondTouch == nil {
            secondTouch = location
            if let first = firstTouch, let second = secondTouch {
                let firstMapCoord = convertToMapCoordinates(first, in: geometry)
                let secondMapCoord = convertToMapCoordinates(second, in: geometry)
                let newLine = BorderLine(start: firstMapCoord, end: secondMapCoord)
                borderLines.append(newLine)
                isAddingBorder = false
                firstTouch = nil
                secondTouch = nil
            }
        } else {
            firstTouch = location
            secondTouch = nil
        }
    }
}





//    .gesture(
//        MagnificationGesture()
//            .onChanged { value in
//                let delta = value / lastScale
//                lastScale = value
//                scale *= delta
//                scale = max(0.5, min(scale, 5.0))
//            }
//            .onEnded { _ in
//                lastScale = 1.0
//            }
//            .simultaneously(with:
//                                DragGesture()
//                .onChanged { gesture in
//                    offset = CGSize(
//                        width: lastOffset.width + gesture.translation.width,
//                        height: lastOffset.height + gesture.translation.height
//                    )
//                }
//                .onEnded { _ in
//                    lastOffset = offset
//                }
//                           )
//    )
