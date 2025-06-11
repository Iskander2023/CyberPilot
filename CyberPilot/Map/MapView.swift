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
    @State private var borderFillColor: Int = 30
    @State private var affectedCells: [CGPoint] = []
    @State private var firstCell: (Int, Int)? = nil
    @State var zones: [ZoneInfo] = []


    
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
                                    // если режим установки границ не активен
                                    if isAddingBorder == false {
                                        offset = CGSize(
                                            width: lastOffset.width + gesture.translation.width,
                                            height: lastOffset.height + gesture.translation.height
                                        )
                                    }
                                    // если режим установки границ активен
                                    if isAddingBorder {
                                        let location = gesture.location
                                        let startCell = mapManager.convertPointToCell(point: location,
                                                                         in: geometry.size,
                                                                         map: map,
                                                                         scale: scale,
                                                                         offset: offset)
                                        if firstCell == nil, let cell = startCell {
                                            firstCell = (Int(cell.x), Int(cell.y))
                                        }
                                        if let from = firstCell, let to = startCell {
                                            let toInt = (Int(to.x), Int(to.y))
                                            affectedCells = mapManager.getCellsAlongLineBetweenCells(from: from, to: toInt)
                                        }
                           
                                        
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
                                        firstCell = nil
                                        affectedCells = []
                                    }
                                    if isAddingBorder {
                                        handleTap(at: gesture.location, in: geometry)
                                        currentDragLocation = nil
                                        firstCell = nil
                                        affectedCells = []
                                    }
                                }
                        )
                    
                    
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
                    
                    ForEach(mapManager.zones) { zone in
                        
                        let center = mapManager.convertMapPointToScreen(zone.center, map: map, in: geometry.size, scale: scale, offset: offset)
                        Text(zone.name)
                            .position(x: center.x, y: center.y)
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
    

    // Обработка касания
    func handleTap(at location: CGPoint, in geometry: GeometryProxy) {
        guard mapManager.map != nil else { return }
        if firstTouch == nil && secondTouch == nil {
            firstTouch = location
        } else if firstTouch != nil && secondTouch == nil {
            secondTouch = location
            mapManager.setValue(borderFillColor, forCells: affectedCells)
            isAddingBorder = false
            firstTouch = nil
            secondTouch = nil
            affectedCells = []
        } else {
            firstTouch = location
            secondTouch = nil
        }
    }
}
