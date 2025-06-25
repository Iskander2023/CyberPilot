//
//  MapControlsView.swift
//  CyberPilot
//
//  Created by Admin on 3/06/25.
//

import SwiftUI

struct MapButtonsView: View {
    @EnvironmentObject private var mapManager: MapManager
    @EnvironmentObject private var mapZoneHandler: MapZoneHandler
    @Binding var scale: CGFloat
    @Binding var offset: CGSize
    @Binding var lastOffset: CGSize
    @Binding var mapMode: MapMode

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                HStack(spacing: AppConfig.MapButtons.spacing) {
                    
                    Button(action: {
                        withAnimation {
                            scale = AppConfig.MapButtons.scale
                            offset = .zero
                            lastOffset = .zero
                        }
                    }) {
                        Image(systemName: AppConfig.MapButtons.initialScaleButton)
                            .padding()
                            .background(Color.white.opacity(AppConfig.MapButtons.opacity))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        mapMode = .addingBorder
                        
                        }) {
                            Image(systemName: AppConfig.MapButtons.borderButton)
                                .padding()
                                .background(Color.white.opacity(AppConfig.MapButtons.opacity))
                                .clipShape(Circle())
                        }
                    
                    Button(action: {
                        mapZoneHandler.mapZoneFills()
                        }) {
                            Image(systemName: AppConfig.MapButtons.zoneButton)
                                .padding()
                                .background(Color.white.opacity(AppConfig.MapButtons.opacity))
                                .clipShape(Circle())
                        }
                    
                    Button(action: {
                        mapMode = .deletingBorder
                        }) {
                            Image(systemName: AppConfig.MapButtons.deleteBorderButton)
                                .padding()
                                .background(Color.white.opacity(AppConfig.MapButtons.opacity))
                                .clipShape(Circle())
                        }
                    
                }
                .padding(.bottom, AppConfig.MapButtons.mapLocation)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
