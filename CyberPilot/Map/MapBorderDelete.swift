//
//  MapBorderDelete.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 18/06/25.
//

import SwiftUI


class MapBorderDelete: ObservableObject {
    let calculator = MapPointCalculator()
    @Published var deleteCell: CGPoint? = nil
    
    
    func deleteBorderOnChanged(location: CGPoint, size: CGSize, scale: CGFloat, offset: CGSize, map: OccupancyGridMap?) {
        guard let map = map else { return }
        if let deleteCell = calculator.convertPointToCell(point: location,
                                                          in: size,
                                                          map: map,
                                                          scale: scale,
                                                          offset: offset) {
            self.deleteCell = deleteCell
        } else {
            self.deleteCell = nil
        }
    }
}
