//
//  MapView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 7/05/25.
//
import SwiftUI



struct MapView: View {
    @EnvironmentObject private var mapManager: MapManager
    @EnvironmentObject private var mapZoneHandler: MapZoneHandler
    @State private var firstTouch: CGPoint? = nil
    @State private var secondTouch: CGPoint? = nil
    @State private var borderLines: [BorderLine] = []
    @State var isAddingBorder = false
    @State private var currentDragLocation: CGPoint? = nil
    @State private var borderFillColor: Int = 30
    @State private var affectedCells: [CGPoint] = []
    @State private var firstCell: (Int, Int)? = nil
    @State var zones: [ZoneInfo] = []
    @State var zoneToEdit: ZoneInfo?
    @State private var newZoneName: String = ""
    @State private var isEditing = false
    @StateObject private var gestureHandler = MapGestureHandler()
    let calculator = MapPointCalculator()

    
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)

    var body: some View {
        GeometryReader { geometry in
            if let map = mapManager.map {
                ZStack {
                    MapCanvasView(map: map, scale: gestureHandler.scale, offset: gestureHandler.offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    gestureHandler.onMagnificationChanged(value)
                                }
                                .onEnded { _ in
                                    gestureHandler.onMagnificationEnded()
                                }
                            )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged {
                                    gesture in
                                    
                                    // если режим установки границ не активен
                                    gestureHandler.onDragGestureChanged(gesture: gesture.translation, isAddingBorder: isAddingBorder)
                                    
                                    // если режим установки границ активен
                                    if isAddingBorder {
                                        let location = gesture.location
                                        let startCell = calculator.convertPointToCell(point: location,
                                                                                      in: geometry.size,
                                                                                      map: map,
                                                                                      scale: gestureHandler.scale,
                                                                                      offset: gestureHandler.offset)
                                        if firstCell == nil,
                                           let cell = startCell {
                                            firstCell = (Int(cell.x), Int(cell.y))
                                        }
                                        if let from = firstCell,
                                           let to = startCell {
                                            let toInt = (Int(to.x), Int(to.y))
                                            affectedCells = calculator.getCellsAlongLineBetweenCells(from: from, to: toInt)
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
                                        gestureHandler.lastOffset = gestureHandler.offset
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
                        BorderDrawingView(
                            isAddingBorder: isAddingBorder,
                            firstTouch: firstTouch,
                            currentDragLocation: currentDragLocation
                        )
                    
                        .allowsHitTesting(false)
                    
                    
                    ZonesOverlayView(
                        calculator: calculator,
                        map: map,
                        scale: gestureHandler.scale,
                        offset: gestureHandler.offset,
                        geometrySize: geometry.size
                    )
                   

                    BorderPointsView(first: firstTouch, second: secondTouch)

                    
                    MapButtonsView(
                        scale: $gestureHandler.scale,
                        offset: $gestureHandler.offset,
                        lastOffset: $gestureHandler.lastOffset,
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
            mapZoneHandler.setValue(borderFillColor, forCells: affectedCells, fillPoints: 0, robotPoint: 50)
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




