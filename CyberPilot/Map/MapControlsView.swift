//
//  MapControlsView.swift
//  CyberPilot
//
//  Created by Admin on 3/06/25.
//

import SwiftUI

struct MapControlsView: View {
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
                            scale = min(scale + 0.5, 5.0)
                        }
                    }) {
                        Image(systemName: "plus.magnifyingglass")
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }

                    Button(action: {
                        withAnimation {
                            scale = max(scale - 0.5, 0.5)
                        }
                    }) {
                        Image(systemName: "minus.magnifyingglass")
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .clipShape(Circle())
                    }

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
                            Image(systemName: "pencil.and.scribble")
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                    
                    Button(action: {
                        if !borderLines.isEmpty {
                            borderLines.removeAll()
                        }
                        }) {
                            Image(systemName: "eraser")
                                .padding()
                                .background(Color.white.opacity(0.8))
                                .clipShape(Circle())
                        }
                    
                    Button(action: {
                        if !borderLines.isEmpty {
                            borderLines.removeLast()
                            }
                        }) {
                            Image(systemName: "arrowshape.turn.up.backward")
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
