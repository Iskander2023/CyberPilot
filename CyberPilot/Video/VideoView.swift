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
    @State private var videoFailedToLoad = false
    @State private var webView: WKWebView?
    @State private var showPerspective = false
    @State private var voiceControl = false
    
    
    init(videoURL: String?, commandSender: CommandSender) {
        self.videoURL = videoURL
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Видео
                if videoFailedToLoad {
                    Text("⚠️ Видео недоступно")
                        .foregroundColor(.white)
                        .font(.headline)
                } else {
                    WebView(
                        urlString: videoURL ?? "",
                        onLoadFailed: {
                            videoFailedToLoad = true
                        }
                    )
                    .edgesIgnoringSafeArea(.all)
                    .allowsHitTesting(false)
                }

                // Перспектива
                if showPerspective {
                    RoadView(horizontalPixels: geometry.size.width,
                             verticalPixels: geometry.size.height,
                             angle: touchPadController.currentAngle,
                             segmentsCount: touchPadController.perspectiveLength)
                    .animation(.linear(duration: 0.2), value: touchPadController.currentAngle)
                }
                // Управление тачпадом
                TouchPadGestureView()

                // Индикатор тачпада
                if touchPadController.touchIndicatorVisible {
                    TouchIndicatorView(controller: touchPadController)
                }
                
                // кнопка включения/выключения перспективы
                PerspectiveButton(showPerspective: $showPerspective)
                
                // кнопка голосового управления
                VoiceControlButton(voiceControl: $voiceControl)
                
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




