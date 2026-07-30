import AppKit
import QuartzCore

/// Draws the menu bar cup: an outline that is always visible, plus a filled cup
/// revealed by a soft gradient mask that rises or drains like liquid.
final class CoffeeIconView: NSView {
    private let container = CALayer()
    private let outlineLayer = CALayer()
    private let fillLayer = CALayer()
    private let fillMask = CAGradientLayer()
    private let steamContainer = CALayer()
    private var steamWisps: [CAShapeLayer] = []

    private let emptyLevel: CGFloat = -0.35
    private let fullLevel: CGFloat = 1.05
    private let bandHeight: CGFloat = 0.3

    private(set) var isFilled = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()

        outlineLayer.contentsGravity = .resizeAspect
        fillLayer.contentsGravity = .resizeAspect

        fillMask.colors = [NSColor.white.cgColor, NSColor.clear.cgColor]
        fillMask.startPoint = CGPoint(x: 0.5, y: emptyLevel)
        fillMask.endPoint = CGPoint(x: 0.5, y: emptyLevel + bandHeight)
        fillLayer.mask = fillMask

        container.addSublayer(outlineLayer)
        container.addSublayer(fillLayer)
        container.addSublayer(steamContainer)
        layer?.addSublayer(container)

        setupSteamWisps()
        updateImages()
    }

    required init?(coder: NSCoder) { fatalError("not supported") }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        container.frame = bounds
        outlineLayer.frame = container.bounds
        fillLayer.frame = container.bounds
        fillMask.frame = container.bounds
        steamContainer.frame = container.bounds
        positionSteamWisps()
        CATransaction.commit()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        let scale = window?.backingScaleFactor ?? 2
        outlineLayer.contentsScale = scale
        fillLayer.contentsScale = scale
    }

    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        updateImages()
    }

    func setFilled(_ filled: Bool, animated: Bool) {
        guard filled != isFilled || !animated else { return }
        isFilled = filled

        let target = filled ? fullLevel : emptyLevel
        let current = (fillMask.presentation() ?? fillMask).startPoint.y

        if animated {
            NSSound(named: "Pop")?.play()
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fillMask.startPoint = CGPoint(x: 0.5, y: target)
        fillMask.endPoint = CGPoint(x: 0.5, y: target + bandHeight)
        CATransaction.commit()

        if filled {
            startSteamAnimation()
        } else {
            stopSteamAnimation()
        }

        guard animated else {
            fillMask.removeAllAnimations()
            return
        }

        let timing = CAMediaTimingFunction(name: .easeInEaseOut)
        let duration: CFTimeInterval = 0.45

        for key in ["startPoint", "endPoint"] {
            let offset: CGFloat = key == "startPoint" ? 0 : bandHeight
            let animation = CABasicAnimation(keyPath: key)
            animation.fromValue = CGPoint(x: 0.5, y: current + offset)
            animation.toValue = CGPoint(x: 0.5, y: target + offset)
            animation.duration = duration
            animation.timingFunction = timing
            fillMask.add(animation, forKey: key)
        }

        let pop = CASpringAnimation(keyPath: "transform.scale")
        pop.fromValue = filled ? 0.82 : 1.12
        pop.toValue = 1.0
        pop.mass = 0.6
        pop.stiffness = 220
        pop.damping = 12
        pop.duration = pop.settlingDuration
        container.add(pop, forKey: "pop")
    }

    // MARK: - Steam Wisps

    private func setupSteamWisps() {
        for _ in 0..<2 {
            let wisp = CAShapeLayer()
            wisp.fillColor = nil
            wisp.lineWidth = 1.2
            wisp.lineCap = .round
            wisp.opacity = 0
            steamContainer.addSublayer(wisp)
            steamWisps.append(wisp)
        }
    }

    private func positionSteamWisps() {
        let tint = currentTint().cgColor
        let width = bounds.width
        let height = bounds.height

        for (index, wisp) in steamWisps.enumerated() {
            wisp.strokeColor = tint
            let xOffset: CGFloat = index == 0 ? width * 0.42 : width * 0.58
            let startY = height * 0.65
            let path = CGMutablePath()
            let dx: CGFloat = index == 0 ? -1.5 : 1.5
            path.move(to: CGPoint(x: xOffset, y: startY))
            path.addCurve(
                to: CGPoint(x: xOffset + dx, y: startY + 5),
                control1: CGPoint(x: xOffset + dx * 1.5, y: startY + 1.8),
                control2: CGPoint(x: xOffset, y: startY + 3.5)
            )
            wisp.path = path
        }
    }

    private func startSteamAnimation() {
        let duration: CFTimeInterval = 1.3

        for (index, wisp) in steamWisps.enumerated() {
            wisp.removeAllAnimations()
            let delay = Double(index) * 0.35

            let group = CAAnimationGroup()
            group.duration = duration
            group.repeatCount = 2
            group.beginTime = CACurrentMediaTime() + delay

            let rise = CABasicAnimation(keyPath: "transform.translation.y")
            rise.fromValue = 0
            rise.toValue = 4.0

            let fade = CAKeyframeAnimation(keyPath: "opacity")
            fade.values = [0, 0.65, 0.4, 0]
            fade.keyTimes = [0, 0.25, 0.7, 1.0]

            group.animations = [rise, fade]
            group.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            wisp.add(group, forKey: "steam")
        }
    }

    private func stopSteamAnimation() {
        for wisp in steamWisps {
            wisp.removeAllAnimations()
            wisp.opacity = 0
        }
    }

    // MARK: - Appearance & Images

    private func updateImages() {
        let tint = currentTint()
        outlineLayer.contents = symbolImage("cup.and.saucer", tint: tint)
        fillLayer.contents = symbolImage("cup.and.saucer.fill", tint: tint)
        for wisp in steamWisps {
            wisp.strokeColor = tint.cgColor
        }
    }

    private func currentTint() -> NSColor {
        var color = NSColor.labelColor
        effectiveAppearance.performAsCurrentDrawingAppearance {
            color = NSColor.labelColor.usingColorSpace(.deviceRGB) ?? .labelColor
        }
        return color
    }

    private func symbolImage(_ name: String, tint: NSColor) -> NSImage? {
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(config) else { return nil }

        return NSImage(size: base.size, flipped: false) { rect in
            base.draw(in: rect)
            tint.set()
            rect.fill(using: .sourceAtop)
            return true
        }
    }
}
