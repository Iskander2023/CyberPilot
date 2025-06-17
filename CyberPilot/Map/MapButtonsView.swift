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
    @Binding var borderLines: [BorderLine]
    @Binding var isAddingBorder: Bool

    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                HStack(spacing: 10) {
                    
                    Button(action: {
                        withAnimation {
                            scale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }) {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }
                    
                    Button(action: {
                        isAddingBorder = true
                        
                        }) {
                            Image(systemName: "point.bottomleft.forward.to.point.topright.scurvepath")
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                    
                    Button(action: {
                        mapZoneHandler.mapZoneFills()
                        }) {
                            Image(systemName: "square.on.square")
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                    
                    Button(action: {
                        }) {
                            Image(systemName: "eraser.line.dashed")
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                    
                }
                .padding(.bottom, 40)
                .padding(.horizontal)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
