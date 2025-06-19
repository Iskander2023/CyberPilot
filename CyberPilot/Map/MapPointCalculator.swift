//
//  MapPointCalculator.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 17/06/25.
//

import Foundation



struct MapPointCalculator {
    
    
    // перевод CGPoint в позицию на Canvas
    func convertMapPointToScreen(_ point: CGPoint, map: OccupancyGridMap, in size: CGSize, scale: CGFloat, offset: CGSize) -> CGPoint {
        let (cellSize, offsetX, offsetY) = calculateCellSize(in: size, map: map, scale: scale, offset: offset)
        let screenX = point.x * cellSize + offsetX + cellSize / 2
        let screenY = point.y * cellSize + offsetY + cellSize / 2
        return CGPoint(x: screenX, y: screenY)
    }
    
    

    // расчет положения текущей на карте
    func calculateCellSize(in size: CGSize, map: OccupancyGridMap, scale: CGFloat, offset: CGSize) -> (cellSize: CGFloat, offsetX: CGFloat, offsetY: CGFloat) {
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
        return (cellSize, offsetX, offsetY)
    }
    
    
    // преобразует координату касания на экране (CGPoint) в координаты ячейки карты (OccupancyGridMap), с учётом масштаба, смещения, и размера экрана.
    func convertPointToCell(point: CGPoint, in size: CGSize, map: OccupancyGridMap, scale: CGFloat, offset: CGSize) -> CGPoint? {
        let (cellSize, offsetX, offsetY) = calculateCellSize(
                in: size,
                map: map,
                scale: scale,
                offset: offset
            )
        let x = Int((point.x - offsetX) / cellSize)
        let y = Int((point.y - offsetY) / cellSize)
        guard x >= 0, x < map.width, y >= 0, y < map.height else {
            return nil
        }
        return CGPoint(x: x, y: y)
    }
    
    
    
    // вычисляет координаты массива точек с помощью алгоритма Брезенхема(от начальной точки до конечной)
    func getCellsAlongLineBetweenCells(from start: (Int, Int), to end: (Int, Int)) -> [CGPoint] {
        let (x0, y0) = start
        let (x1, y1) = end
        
        var points = [CGPoint]()
        
        let dx = abs(x1 - x0)
        let dy = abs(y1 - y0)
        let sx = x0 < x1 ? 1 : -1
        let sy = y0 < y1 ? 1 : -1
        var err = dx - dy
        var currentX = x0
        var currentY = y0
        while true {
            points.append(CGPoint(x: currentX, y: currentY))
            if currentX == x1 && currentY == y1 {
                break
            }
            let e2 = 2 * err
            if e2 > -dy {
                err -= dy
                currentX += sx
            }
            if e2 < dx {
                err += dx
                currentY += sy
            }
        }
        return points
    }
}


