//
//  TouchPadView.swift
//  CyberPilot
//
//  Created by Aleksandr Chumakov on 17/04/25.
//

import UIKit



class TouchPadView: UIView {
    
    var onAngleChanged: ((CGFloat) -> Void)?
    var onRotationDirectionChanged: ((RotationDirection) -> Void)?
    var onStop: (() -> Void)?
    
    enum RotationDirection {
        case clockwise
        case counterClockwise
    }
    
    private let touchIndicator = UIView()
    private let directionArrow = CAShapeLayer()
    private var initialTouchPoint: CGPoint = .zero
    private var currentAngle: CGFloat = 0.0
    private var previousAngle: CGFloat?
    private var angleUpdateTimer: Timer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        touchIndicator.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        touchIndicator.layer.cornerRadius = 60
        touchIndicator.layer.borderWidth = 2
        touchIndicator.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        touchIndicator.isHidden = true
        touchIndicator.frame.size = CGSize(width: 120, height: 120)
        addSubview(touchIndicator)
        
        directionArrow.strokeColor = UIColor.systemBlue.cgColor
        directionArrow.fillColor = UIColor.clear.cgColor
        directionArrow.lineWidth = 4
        directionArrow.lineCap = .round
        touchIndicator.layer.addSublayer(directionArrow)
    }
    
    // MARK: - Touches
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        initialTouchPoint = touch.location(in: self)
        touchIndicator.center = initialTouchPoint
        touchIndicator.isHidden = false
        touchIndicator.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        
        UIView.animate(withDuration: 0.3) {
            self.touchIndicator.transform = .identity
        }

        updateAngle(for: initialTouchPoint)
        startAngleUpdateTimer()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let currentPoint = touch.location(in: self)
        updateAngle(for: currentPoint)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetTouchPad()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        resetTouchPad()
    }
    
    private func resetTouchPad() {
        angleUpdateTimer?.invalidate()
        angleUpdateTimer = nil
        previousAngle = nil

        UIView.animate(withDuration: 0.2, animations: {
            self.touchIndicator.alpha = 0
        }) { _ in
            self.touchIndicator.isHidden = true
            self.touchIndicator.alpha = 1
            self.onStop?()
        }
    }
    
    // MARK: - Angle Logic
    
    private func updateAngle(for touchLocation: CGPoint) {
        let dx = touchLocation.x - touchIndicator.center.x
        let dy = touchLocation.y - touchIndicator.center.y
        
        var angle = atan2(dy, dx)
        if angle < 0 {
            angle += 2 * .pi
        }

        if let prev = previousAngle {
            var delta = angle - prev
            if delta > .pi {
                delta -= 2 * .pi
            } else if delta < -.pi {
                delta += 2 * .pi
            }

            let threshold: CGFloat = 0.05
            if abs(delta) > threshold {
                if delta > 0 {
                    onRotationDirectionChanged?(.clockwise)
                } else {
                    onRotationDirectionChanged?(.counterClockwise)
                }
            }
        }

        previousAngle = angle
        currentAngle = angle
        updateArrow(angle: angle)
    }
    
    private func updateArrow(angle: CGFloat) {
        let arrowLength: CGFloat = 50
        let center = CGPoint(x: 60, y: 60)
        
        let path = UIBezierPath()
        path.move(to: center)
        
        let endPoint = CGPoint(
            x: center.x + arrowLength * cos(angle),
            y: center.y + arrowLength * sin(angle)
        )
        path.addLine(to: endPoint)
        
        let arrowHeadLength: CGFloat = 15
        let angle1 = angle + .pi * 0.8
        let angle2 = angle + .pi * 1.2
        
        path.move(to: endPoint)
        path.addLine(to: CGPoint(
            x: endPoint.x + arrowHeadLength * cos(angle1),
            y: endPoint.y + arrowHeadLength * sin(angle1)
        ))
        
        path.move(to: endPoint)
        path.addLine(to: CGPoint(
            x: endPoint.x + arrowHeadLength * cos(angle2),
            y: endPoint.y + arrowHeadLength * sin(angle2)
        ))
        
        directionArrow.path = path.cgPath
    }

    // MARK: - Timer
    
    private func startAngleUpdateTimer() {
        angleUpdateTimer?.invalidate()
        angleUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.onAngleChanged?(self.currentAngle)
        }
    }
}

