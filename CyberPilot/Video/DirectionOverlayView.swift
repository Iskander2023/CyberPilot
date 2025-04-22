//
//  DirectionOverlayView.swift
//  CyberPilot
//
//  Created by Admin on 17/04/25.
//
import WebKit
import UIKit


class DirectionOverlayView: UIView {
    
    private let shapeLayer = CAShapeLayer()
    
    var directionAngle: CGFloat = 0.0 {
        didSet {
            updateDirectionLine()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
        backgroundColor = .clear // Прозрачный фон
        isUserInteractionEnabled = false // Чтобы пропускать тачи
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.lineWidth = 4.0 // Более толстая линия для видимости
        shapeLayer.fillColor = UIColor.clear.cgColor
        layer.addSublayer(shapeLayer)
    }

    private func updateDirectionLine() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY) // Создает точку в центре view, используя середину по X и Y (bounds.midX/Y)
        let length: CGFloat = min(bounds.width, bounds.height) * 0.6 // Берет минимальное из значений ширины или высоты view
        
        // Использует тригонометрию (cos/sin) для расчета конечной точки линии
        let endPoint = CGPoint(
            x: center.x + length * cos(directionAngle),
            y: center.y + length * sin(directionAngle)
        )

        let path = UIBezierPath() //Создает новый путь (BezierPath)
        path.move(to: center) // Начинает путь из центра
        path.addLine(to: endPoint) // Добавляет линию до конечной точки
        shapeLayer.path = path.cgPath // Присваивает путь слою для отображения
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateDirectionLine() // Важно: обновляем при изменении размеров
    }
}

