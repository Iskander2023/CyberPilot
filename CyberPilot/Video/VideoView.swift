//
//  VideoView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 16/04/25.
//
import SwiftUI
import WebKit


struct VideoView: View {
    var videoURL: String?
    @EnvironmentObject private var touchPadController: TouchController
    @Environment(\.presentationMode) var presentationMode
    
    init(videoURL: String?, commandSender: CommandSender) {
        self.videoURL = videoURL
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Видео
                WebView(urlString: videoURL ?? "")
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(false)

                // Перспектива
                RoadView(horizontalPixels: geometry.size.width,
                         verticalPixels: geometry.size.height,
                         angle: touchPadController.currentAngle,
                         segmentsCount: touchPadController.perspectiveLength)
                    .animation(.linear(duration: 0.2), value: touchPadController.currentAngle)

                // Управление тачпадом
                TouchPadGestureView()

                // Индикатор тачпада
                if touchPadController.touchIndicatorVisible {
                    TouchIndicatorView(controller: touchPadController)
                }
                
                // Кнопка отключения
                CloseButton {
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .background(Color.black)
            .onDisappear {
                touchPadController.onDisappear()
            }
        }
    }
}




