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
    private let logger = CustomLogger(logLevel: .info, includeMetadata: false)
    
    
    
    var body: some View {
        GeometryReader { geometry in
            if let map = mapManager.map {
                ZStack {
                    MapCanvasView(map: map, scale: scale, offset: offset)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { gesture in
                                    if isAddingBorder {
                                        handleTap(at: gesture.location)
                                    }
                                }
                        )

                    ForEach(borderLines) { line in
                        BorderLineView(start: line.start, end: line.end)
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

    
    func handleTap(at location: CGPoint) {
        if firstTouch == nil && secondTouch == nil {
            firstTouch = location
            
        } else if firstTouch != nil && secondTouch == nil{
            secondTouch = location
            if let first = firstTouch, let second = secondTouch {
                let newLine = BorderLine(start: first, end: second)
                borderLines.append(newLine)
                isAddingBorder = false
                firstTouch = nil
                secondTouch = nil
            }
        } else {
            firstTouch = nil
            secondTouch = nil
            firstTouch = location
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
