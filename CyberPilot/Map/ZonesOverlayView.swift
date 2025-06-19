//
//  ZonesOverlayView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 17/06/25.
//
import SwiftUI


struct ZonesOverlayView: View {
    @EnvironmentObject var mapZoneHandler: MapZoneHandler
    let calculator: MapPointCalculator
    let map: OccupancyGridMap 
    let scale: CGFloat
    let offset: CGSize
    let geometrySize: CGSize
    
    @State private var zoneToEdit: ZoneInfo?
    @State private var newZoneName: String = ""
    @State private var isEditing = false
    
    var body: some View {
        ForEach(mapZoneHandler.zones) { zone in
            let center = calculator.convertMapPointToScreen(zone.center, map: map, in: geometrySize, scale: scale, offset: offset)
            Text(zone.name)
                .position(x: center.x, y: center.y - 3)
                .onTapGesture {
                    zoneToEdit = zone
                    newZoneName = zone.name
                    isEditing = true
                }
                .sheet(isPresented: $isEditing) {
                    VStack {
                        Text("Введите название")
                        TextField("Новое название", text: $newZoneName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Сохранить") {
                            if let zone = zoneToEdit {
                                mapZoneHandler.renameZone(id: zone.id, newName: newZoneName)
                            }
                            isEditing = false
                        }
                        
                        Button("Отмена") {
                            isEditing = false
                        }
                    }
                    .padding()
                }
        }
    }
}
