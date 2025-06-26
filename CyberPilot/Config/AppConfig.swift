//
//  AppConfig.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 24/06/25.
//
import SwiftUI



struct AppConfig {
    
    
    struct VideoView {
        static var systemName = "road.lane.arrowtriangle.2.inward"
        static let paddingTop: CGFloat = 16
        static let paddingLeading: CGFloat = 16
        static let ikonSize: CGFloat = 30
        static let foreground:Color = .black
    }
    
    
    struct SocketView {
        static let mainContentPadding: CGFloat = 100
        static let mainContentSpacing: CGFloat = 20
        
        static let webViewHeight: CGFloat = 350
        static let webViewPadding: CGFloat = 20
        
        static let connectionAddressFrame: CGFloat = 250
        
        
        static let connectButtonForegroundColor: Color = .white
        static let connectButtonBackgroundColor: Color = .blue
        static let connectButtonCornerRadius: CGFloat = 8
        
        static let disconnectButtonSystemName = "xmark.circle.fill"
        static let disconnectButtonFont: CGFloat = 35
        static let disconnectButtonForegroundColor: Color = .red
        
        static let connectionIndicatorTextSize: CGFloat = 16
        static let connectionIndicatorCircleWidth: CGFloat = 20
        static let connectionIndicatorCircleHeight: CGFloat = 20
        static let connectionIndicatorDisconnectColor: Color = .red
        static let connectionIndicatorConnectColor: Color = .green
        
        static let cameraButtonSystemName = "camera.fill"
        static let cameraButtonForegroundColor: Color = .black
        static let cameraButtonBackground: Color = .white
        static let cameraButtonOpacity: CGFloat = 0.8
        static let cameraButtonPaddingTop: CGFloat = 16
        static let cameraButtonPaddingLeading: CGFloat = 16
        
    }
    
    
    
    struct CommandSender {
        static let stopInterval = 0.5
        static let commandInterval = 0.2
    }
    
    
    struct DirectionArrow {
        static let arrowHeadLength: CGFloat = 15
        static let lineWidth: CGFloat = 4
        
    }
    
    struct DirectionLabels {
        static let width: CGFloat = 6
        static let height: CGFloat = 6
    }
    
    struct RoadView {
        static let roadWidth: CGFloat = 400
        static let lineHeight: CGFloat = 30
        static let segmentAngle: CGFloat = 0
        static let previousDegrees: CGFloat = 270
    }
    
    
    struct Perspective {
        static let planeDistance: CGFloat = 400
        static let horizontalAngleGrad: CGFloat = 145.8
        static let verticalAngleGrad: CGFloat = 122.6
        
    }
    
    struct ZonesOverlay {
        static let texyOffset: CGFloat = 3
        static let inputZoneName = "Введите название"
        static let newZoneName = "Новое название"
        static let buttonSaveText = "Сохранить"
        static let buttonCancelText = "Отмена"
        
    }
    
    struct MapGestureHandler {
        static let minScale: CGFloat = 0.5
        static let maxScale: CGFloat = 5
        static let lastScale: CGFloat = 1
    }
    
    struct MapButtons {
        static let initialScaleButton = "arrow.uturn.backward.circle"
        static let borderButton = "point.bottomleft.forward.to.point.topright.scurvepath"
        static let zoneButton = "square.on.square"
        static let deleteBorderButton = "eraser.line.dashed"
        static let spacing: CGFloat = 10
        static let opacity: CGFloat = 0.8
        static let mapLocation: CGFloat = 40
        static let scale: Double = 1.0
    }
    
    
    
    struct MapManagerMessage {
        static let loadingFromLocalFile = "✅ загрузка с локального файла"
        static let theMapHasChanged = "🔄 Карта изменилась — сохраняем в кэш"
        static let theMapHasNotChanged = "✅ Карта не изменилась"
        static let arrayDoesNotMatchMap = "❌ Размер массива не совпадает с размерами карты."
    }
    
    
    struct MapManager {
        static let socketIp: String = "ws://172.16.17.79:8765"
        static let noLocalIp: String = "http://192.168.0.201:8000/map.yaml" //var noLocalIp: String = "http://127.0.0.1:8000/map.yaml"
        static let mapUpdateTime: TimeInterval = 10
        static let resolution = 0.1
    }
    
    struct Cached {
        static let mapFilename = "cached_map.json"
        static let segmentsFilename = "cached_segments.json"
        
    }
    
    struct LineManager {
        static let socketIp = "ws://172.16.17.79:8765"
        
    }
    
    
    struct LineView {
        static let lineWidth: CGFloat = 2
        static let robotPositionwidth: CGFloat = 10 
        static let robotPositionheight: CGFloat = 10 
    }
    
    
    struct TouchController {
        static let maxSizeTach: CGFloat = 125
        static let maxSize: CGFloat = 250
        static let minSize: CGFloat = 100
        static let minLenghtPerspective: CGFloat = 50
        static let maxLenghtPerspective: CGFloat = 80
        static let updateTime = 0.2
        static let touchIndicatorSize: CGFloat = 100
        static let perspectiveLength: Int = 3
    }
    
    
    struct TouchPadGesture {
        static let minimumDistance: CGFloat = 5
    }
    
    struct TouchIndicator {
        static let color: Color = .blue
        static let opacity: Double = 0.2
        static let lineWidth: CGFloat = 2
        static let backgroundColorOpacity: CGFloat = 0.01
    }
    
    struct BorderLine {
        static let color: Color = .red
        static let lineWidth: CGFloat = 5
        static let dash: [CGFloat]? = [5]
    }
    
    
    struct PointSize {
        static let pointWidth: CGFloat = 10
        static let pointHeight: CGFloat = 10
        
    }
    
    struct UsersData {
        static let defaultUserName = "user"
        
    }
    
    struct Colors {
        static let primaryGreen = Color(red: 34/255, green: 177/255, blue: 76/255)
        static let inactiveGray = Color(red: 220/255, green: 220/255, blue: 220/255)
        static let errorRed = Color.red
        static let successGreen = Color.green
    }
    
    struct Addresses {
        static let serverAddress =  "ws://selekpann.tech:2000"
        static let localAddress = "robot3.local"
        static let userRegistrationUrl = "http://selekpann.tech:3000/register" // адрес для регистрации нового пользователя
        static let userLoginUrl = "http://selekpann.tech:3000/login" // адрес авторизации пользователя
        static let apiID = "5A5A737E-09E1-0492-ADD3-957B269669D8" // апи для отправки кода на номер телефона
        
    }
    
    struct PatternsForInput {
        static let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        static let passwordPattern = "[A-Z]"
        static let phoneNumberPattern = "^[0-9]+$"
        static let confirmationCodePattern = "[0-9]"
    }
    
    struct HttpMethods {
        static let postMethod = "POST"
        static let httpRequestHeader = "Content-Type"
        static let httpRequestValue = "application/json"
    }
    
    
    struct Strings {
        // регистрация
        static let registrationTitle = "Создать аккаунт"
        static let registerButtonTitle = "Зарегистрироваться"
        static let emailRus = "Почта"
        static let loginRus = "Логин"
        static let EmailEng = "Email"
        static let min4Simbols = "Минимум 4 символа"
        static let passwordRus = "Пароль"
        static let confirmPassword = "Подтвердите пароль"
        static let min8Simbols = "Минимум 8 символов"
        static let iconName = "lock.open"
        static let OneSymbolWithACapitalLetter = "Один символ с большой буквы"
        static let passwordMatch = "Пароль должен совпадать с введенным ранее"
        static let registrationStatusTrue = "Регистрация успешна!"
        static let registrationStatusFalse = "Ошибка регистрации:"
        static let responseString = "No response data"
        static let alreadyRegistered = "Пользователь с таким email уже зарегистрирован"
        static let incorrectData =  "Неверные данные регистрации"
        // логин
        static let enterData = "Введите данные"
        static let loginError = "Ошибка входа"
        static let buttonOk = "Ok"
        static let dontHaveAccount = "Нет аккаунта?"
        static let loginEntry = "Вход"
        static let errorLoginMessage = "Не удалось войти. Проверьте данные и попробуйте снова."
        static let successfulLogin = "Успешный вход"
        // телефон
        static let inputPhoneNumber = "Введите номер телефона"
        static let phoneNumberPrefix = "Номер +7"
        static let onlyNumbers = "только цифры"
        static let phoneNumbersCount = "10"
        static let sendPhoneNumber = "Отправить"
        //
        static let backButton = "< Назад"
        // капча
        static let charactersForCaptcha = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        static let inputCaptchaText = "Введите текст ниже:"
        static let inputCaptcha = "Введите капчу"
        static let checkCaptcha = "Проверить"
        static let updateCaptcha = "Обновить капчу"
        static let repeatIn = "Повторить через"
        // код
        static let enterReciverCode = "Введите полученый код"
        static let code = "Код"
        static let codeLength = "4"
        static let incorrectCodeMessage = "Не правильный код"
        static let errorMessage = "Ошибка"
        static let confirm = "Подтвердить"
        
    }
    
    struct Requirements {
        static let minLoginLength = 4
        static let minPasswordLength = 8
    }
    
    struct Flags {
        static let isDebugMode = true
    }
}
