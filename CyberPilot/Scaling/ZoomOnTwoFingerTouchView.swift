//
//  ZoomOnTwoFingerTouchView.swift
//  CyberPilot
//
//  Created by Admin on 22/05/25.
//

import Foundation
import SwiftUI



//struct ZoomOnTwoFingerTouchView: View {
//    @State private var scale: CGFloat = 1.0
//    @State private var isZoomingEnabled = false
//    
//    var body: some View {
//        ZStack {
//            // Контент, который можно масштабировать
//            Image(systemName: "globe")
//                .resizable()
//                .scaledToFit()
//                .frame(width: 200, height: 200)
//                .scaleEffect(scale)
//                .gesture(
//                    isZoomingEnabled ? MagnificationGesture()
//                        .onChanged { value in
//                            scale = value
//                        }
//                        .onEnded { _ in
//                            withAnimation {
//                                scale = 1.0 // Возвращаем к исходному масштабу
//                            }
//                            isZoomingEnabled = false // Выключаем зум после жеста
//                        }
//                    : nil
//                )
//            
//            // Детектор касания двумя пальцами
//            TwoFingerTouchDetector {
//                isZoomingEnabled = true // Включаем зум
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//        }
//    }
//}
//
//// Детектор касания двумя пальцами
//struct TwoFingerTouchDetector: UIViewRepresentable {
//    var onTwoFingerTouch: () -> Void
//    
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView()
//        view.isUserInteractionEnabled = true
//        view.isMultipleTouchEnabled = true
//        
//        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
//        panGesture.minimumNumberOfTouches = 2
//        panGesture.maximumNumberOfTouches = 2
//        view.addGestureRecognizer(panGesture)
//        
//        return view
//    }
//    
//    func updateUIView(_ uiView: UIView, context: Context) {}
//    
//    func makeCoordinator() -> Coordinator {
//        Coordinator(onTwoFingerTouch: onTwoFingerTouch)
//    }
//    
//    class Coordinator {
//        var onTwoFingerTouch: () -> Void
//        
//        init(onTwoFingerTouch: @escaping () -> Void) {
//            self.onTwoFingerTouch = onTwoFingerTouch
//        }
//        
//        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
//            if gesture.numberOfTouches == 2 && gesture.state == .began {
//                onTwoFingerTouch()
//            }
//        }
//    }
//}
//
//
//struct ZoomOnTwoFingerTouchModifier: ViewModifier {
//    @Binding var scale: CGFloat
//    @State private var isZoomingEnabled = false
//
//    func body(content: Content) -> some View {
//        ZStack {
//            content
//                .scaleEffect(scale)
//                .gesture(
//                    isZoomingEnabled ? MagnificationGesture()
//                        .onChanged { value in
//                            scale = value
//                        }
//                        .onEnded { _ in
//                            withAnimation {
//                                scale = 1.0
//                            }
//                            isZoomingEnabled = false
//                        } : nil
//                )
//            
//            TwoFingerTouchDetector {
//                isZoomingEnabled = true
//            }
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//        }
//    }
//}
//
//
//extension View {
//    func zoomOnTwoFingerTouch(scale: Binding<CGFloat>) -> some View {
//        modifier(ZoomOnTwoFingerTouchModifier(scale: scale))
//    }
//}
