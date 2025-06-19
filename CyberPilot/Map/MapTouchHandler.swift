//
//  MapTouchHandler.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 17/06/25.
//

import SwiftUI


class MapTouchHandler: ObservableObject {
    @Published var firstTouch: CGPoint? = nil
    @Published var secondTouch: CGPoint? = nil
    @Published var currentDragLocation: CGPoint? = nil
    @Published var borderFillColor: Int = 30
    @Published var deleteFillColor: Int = 100
    @Published var affectedCells: [CGPoint] = []
    @Published var firstCell: (Int, Int)? = nil
    var map: OccupancyGridMap?
    let calculator = MapPointCalculator()
    
    
    func onDragGestureChanged(location: CGPoint, size: CGSize, scale: CGFloat, offset: CGSize, map: OccupancyGridMap?) {
        guard let map = map else { return }
        
        let startCell = calculator.convertPointToCell(point: location,
                                                      in: size,
                                                      map: map,
                                                      scale: scale,
                                                      offset: offset)
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
            firstTouch = location
        } else {
            currentDragLocation = location
        }
    }
    
    
    func onDragGestureEnded() {
        firstCell = nil
        affectedCells = []
        
    }
    
    
    
}
