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
    @State var isAddingBorder = false
    @StateObject private var gestureHandler = MapGestureHandler()
    @StateObject private var touchHandler = MapTouchHandler()
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
                                    touchHandler.onDragGestureChanged(location: gesture.location,
                                                                      isAddingBorder: isAddingBorder,
                                                                      size: geometry.size,
                                                                      scale: gestureHandler.scale,
                                                                      offset: gestureHandler.offset,
                                                                      map: mapManager.map)
                                  
                                }
                                .onEnded { gesture in
                                    if isAddingBorder == false {
                                        gestureHandler.onDragGestureEnded(isAddingBorder: isAddingBorder)
                                        touchHandler.onDragGestureEnded()

                                    }
                                    if isAddingBorder {
                                        handleTap(at: gesture.location, in: geometry)
                                        touchHandler.currentDragLocation = nil
                                        touchHandler.onDragGestureEnded()

                                    }
                                }
                        )
                    
                    
                    // Временная линия (тянется от первой точки к курсору)
                        BorderDrawingView(
                            isAddingBorder: isAddingBorder,
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
                   

                    BorderPointsView(first: touchHandler.firstTouch, second: touchHandler.secondTouch)

                    
                    MapButtonsView(
                        scale: $gestureHandler.scale,
                        offset: $gestureHandler.offset,
                        lastOffset: $gestureHandler.lastOffset,
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
        if touchHandler.firstTouch == nil && touchHandler.secondTouch == nil {
            touchHandler.firstTouch = location
        } else if touchHandler.firstTouch != nil && touchHandler.secondTouch == nil {
            touchHandler.secondTouch = location
            mapZoneHandler.setValue(touchHandler.borderFillColor, forCells: touchHandler.affectedCells, fillPoints: 0, robotPoint: 50)
            isAddingBorder = false
            touchHandler.firstTouch = nil
            touchHandler.secondTouch = nil
            touchHandler.affectedCells = []
        } else {
            touchHandler.firstTouch = location
            touchHandler.secondTouch = nil
        }
    }
}




