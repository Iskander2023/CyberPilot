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
    @StateObject private var gestureHandler = MapGestureHandler()
    @StateObject private var touchHandler = MapTouchHandler()
    @StateObject private var mapBorderDelete = MapBorderDelete()
    @State private var mapMode: MapMode = .normal
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
                                    switch mapMode {
                                    case .normal:
                                        gestureHandler.onDragGestureChanged(gesture: gesture.translation)
                                    case .deletingBorder:
                                        mapBorderDelete.deleteBorderOnChanged(location: gesture.location,
                                                                              size: geometry.size,
                                                                              scale: gestureHandler.scale,
                                                                              offset: gestureHandler.offset,
                                                                              map: mapManager.map)
                                    
                                    case .addingBorder:
                                        touchHandler.onDragGestureChanged(location: gesture.location,
                                                                          size: geometry.size,
                                                                          scale: gestureHandler.scale,
                                                                          offset: gestureHandler.offset,
                                                                          map: mapManager.map)
                                        
                                    }
                                }
                                .onEnded { gesture in
                                    switch mapMode {
                                    case .addingBorder:
                                        touchHandlingBorder(at: gesture.location, in: geometry) // запоминает координату точ заполняет firstTouch или secondTouch;может завершить добавление границы и применить зону
                                        touchHandler.currentDragLocation = nil // – сбрасывает текущую позицию перетаскивания (линия от точки к курсору).
                                        touchHandler.onDragGestureEnded() // – завершает работу с прикосновением (сброс текущих состояний).
                                    case .normal:
                                        gestureHandler.onDragGestureEnded() // завершает логику обработки жеста перемещения (масштабирование/перемещение карты).
                                        touchHandler.onDragGestureEnded() // – сбрасывает/завершает состояние прикосновения.
                                        
                                    case .deletingBorder:
                                        touchHandlingBorderDel(at: gesture.location, in: geometry)
                                    }
                                }
                        )

                    
                        // Временная линия (тянется от первой точки к курсору)
                        BorderDrawingView(
                            firstTouch: touchHandler.firstTouch,
                            currentDragLocation: touchHandler.currentDragLocation
                        )
                        .allowsHitTesting(false)
                        
                    
                    
                    ZonesOverlayView(
                        calculator: calculator,
                        map: map,
                        scale: gestureHandler.scale,
                        offset: gestureHandler.offset,
                        geometrySize: geometry.size
                    )
                   
                    // точки при построении ограничений
                    DrawningPointsView(
                                     firstTouch: touchHandler.firstTouch,
                                     currentDragLocation: touchHandler.secondTouch)
                    
                    
//                    DrawningDeletePointView(isDeleteBorder: isDeleteBorder,
//                                            touch: touchHandler.firstTouch
//                    )

                    
                    MapButtonsView(
                        scale: $gestureHandler.scale,
                        offset: $gestureHandler.offset,
                        lastOffset: $gestureHandler.lastOffset,
                        mapMode: $mapMode
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
    func touchHandlingBorder(at location: CGPoint, in geometry: GeometryProxy) {
        if touchHandler.firstTouch == nil && touchHandler.secondTouch == nil {
            touchHandler.firstTouch = location
        } else if touchHandler.firstTouch != nil && touchHandler.secondTouch == nil {
            touchHandler.secondTouch = location
            mapZoneHandler.setValue(touchHandler.borderFillColor,forCells: touchHandler.affectedCells, allowedValues: Array(31...100), fillPoints: 0, robotPoint: 20)
            mapMode = .normal
            touchHandler.firstTouch = nil
            touchHandler.secondTouch = nil
            touchHandler.affectedCells = []
        } else {
            touchHandler.firstTouch = location
            touchHandler.secondTouch = nil
        }
    }
    
    
    
    func touchHandlingBorderDel(at location: CGPoint, in geometry: GeometryProxy) {
        guard let deleteCell = mapBorderDelete.deleteCell else { return }
        mapZoneHandler.setValue(
            100,
            forCells: [deleteCell],
            allowedValues: [30],
            fillPoints: 100,
            robotPoint: 20
        )
        mapMode = .normal
    }

    
}

