//
//  RingKeyboardView.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/19/21.
//

import UIKit


/// A circular ring of 7 or 12 piano keys.
class RingKeyboardView: UIView {
    
    struct Model {
        var styledNotes: [(AbsoluteNote, KeyStyle)?] = []
        var stickyKeys: Bool = false
        var stuckKeys: Set<AbsoluteNote> = []
    }
    
    var model: Model = Model(styledNotes: [])

    func set(model: Model) {
        self.model = model
        _apply(model: model)
    }

    var keyDelegate: KeyDelegate? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = ColorTheme.background
        _apply(model: model)
    }
    
    // MARK: - Internals

    /// The piano keys.
    private var _keys: [UIButton] = []
    
    private var _buttonRadius: CGFloat {
        return min(bounds.width, bounds.height) * 0.085
    }
    
    private var _buttonFontSize: CGFloat {
        return round(min(bounds.width, bounds.height) * 0.03)
    }
    
    private var _buttonCenterlineDiameter: CGFloat {
        let padding: CGFloat = 16
        return min(bounds.width, bounds.height) - (padding * 2) - (_buttonRadius * 2)
    }

    private var _semitoneTickmarkLength: CGFloat {
        return min(bounds.width, bounds.height) * 0.075
    }
    
    private func _tickmarkAngle(index: Int) -> CGFloat {
        return CGFloat.pi / 6 * CGFloat(-index) + CGFloat.pi
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {

        func drawButtonCenterlineCircle() {
            let circleRect: CGRect = CGRect
                .square(dimension: _buttonCenterlineDiameter)
                .centered(within: rect)
            let path = UIBezierPath(ovalIn: circleRect)
            path.lineWidth = round(_semitoneTickmarkLength * 0.1)
            ColorTheme.separator.setStroke()
            path.stroke()
        }

        func drawSemitoneTickmarks() {

            func tickmarkStart(index: Int) -> CGPoint {
                let centerToTickmarkStartRadius: CGFloat = (_buttonCenterlineDiameter / 2) - (_semitoneTickmarkLength / 2)
                let x: CGFloat = center.x + sin(_tickmarkAngle(index: index)) * centerToTickmarkStartRadius
                let y: CGFloat = center.y + cos(_tickmarkAngle(index: index)) * centerToTickmarkStartRadius
                return CGPoint(x: x, y: y)
            }
            
            func tickmarkEnd(index: Int) -> CGPoint {
                let centerToTickmarkEndRadius: CGFloat = (_buttonCenterlineDiameter / 2) + (_semitoneTickmarkLength / 2)
                let x: CGFloat = center.x + sin(_tickmarkAngle(index: index)) * centerToTickmarkEndRadius
                let y: CGFloat = center.y + cos(_tickmarkAngle(index: index)) * centerToTickmarkEndRadius
                return CGPoint(x: x, y: y)
            }

            for i in 0..<12 {
                let path = UIBezierPath()
                path.lineWidth = round(_semitoneTickmarkLength * 0.05)
                path.move(to: tickmarkStart(index: i))
                path.addLine(to: tickmarkEnd(index: i))
                ColorTheme.separator.setStroke()
                path.stroke()
            }
        }

        drawButtonCenterlineCircle()
        drawSemitoneTickmarks()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        func buttonCenter(index: Int) -> CGPoint {
            let centerToButtonCenterRadius: CGFloat = _buttonCenterlineDiameter / 2
            let x: CGFloat = center.x + sin(_tickmarkAngle(index: index)) * centerToButtonCenterRadius
            let y: CGFloat = center.y + cos(_tickmarkAngle(index: index)) * centerToButtonCenterRadius
            return CGPoint(x: x, y: y)
        }

        for k in _keys {
            k.frame = CGRect(x: 0, y: 0, width: _buttonRadius * 2, height: _buttonRadius * 2)
            k.center = buttonCenter(index: k.tag)
            k.layer.cornerRadius = _buttonRadius
            k.layer.borderWidth = round(_semitoneTickmarkLength * 0.05)
            if UIDevice.current.userInterfaceIdiom == .pad {
                k.titleLabel?.font = UIFont.systemFont(ofSize: _buttonFontSize)
            }
        }
    }
    
    /// (Re)Construct the views according to the model.
    private func _apply(model: Model) {
        
        func setupKey(index: Int, styledNote: (AbsoluteNote, KeyStyle)?) {
            let key = UIButton(type: .system)
            key.translatesAutoresizingMaskIntoConstraints = false
            key.backgroundColor = ColorTheme.background
            key.layer.borderColor = ColorTheme.separator.cgColor
            key.titleLabel?.adjustsFontSizeToFitWidth = true
            key.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
            key.titleLabel?.lineBreakMode = .byWordWrapping
            key.titleLabel?.textAlignment = .center
            key.tag = index

            switch styledNote {

            case let .some((absoluteNote, keyStyle)):
                key.setTitle(absoluteNote.buttonText, for: .normal)

                switch keyStyle {
                case .normal:
                    key.isEnabled = true
                    key.backgroundColor = ColorTheme.background
                case .shaded:
                    key.isEnabled = true
                    key.backgroundColor = ColorTheme.shadedKey
                case .disabled:
                    key.isEnabled = false
                    key.backgroundColor = ColorTheme.shadedKey
                }
                addSubview(key)
                _keys.append(key)
                
                if model.stickyKeys {
                    key.addTarget(self, action: #selector(keyDidGetToggled(key:)), for: .touchDown)
                } else {
                    key.addTarget(self, action: #selector(keyDidGetPressed(key:)), for: .touchDown)
                    key.addTarget(self, action: #selector(keyDidGetReleased(key:)), for: .touchUpInside)
                    key.addTarget(self, action: #selector(keyDidGetReleased(key:)), for: .touchDragExit)
                    key.addTarget(self, action: #selector(keyDidGetReleased(key:)), for: .touchCancel)
                }

            case .none:
                key.isEnabled = false
                key.backgroundColor = ColorTheme.shadedKey
            }
        }
        
        // Discard any previous keys.
        for k in _keys {
            k.removeFromSuperview()
        }
        _keys.removeAll()

        // Install the replacement keys.
        for (i, styledNote) in model.styledNotes.enumerated() {
            setupKey(index: i, styledNote: styledNote)
        }
        
        setNeedsLayout()
    }

    // MARK: - Target/Action
    
    /// The pressed action is used when pressing a non-sticky key.
    @objc func keyDidGetPressed(key: UIButton) {
        guard let (absoluteNote, _) = model.styledNotes[key.tag] else { return }
        key.backgroundColor = ColorTheme.activeKey
        keyDelegate?.keyDidGetPressed(absoluteNote: absoluteNote)
    }

    /// The pressed action is used when releasing a non-sticky key.
    @objc func keyDidGetReleased(key: UIButton) {
        guard let (absoluteNote, keyStyle) = model.styledNotes[key.tag] else { return }
        switch keyStyle {
        case .normal:
            key.backgroundColor = ColorTheme.background
        case .shaded, .disabled:
            key.backgroundColor = ColorTheme.shadedKey
        }
        keyDelegate?.keyDidGetReleased(absoluteNote: absoluteNote)
    }
    
    /// The toggled action is used for sticky keys.
    @objc func keyDidGetToggled(key: UIButton) {
        if let (absoluteNote, keyStyle) = model.styledNotes[key.tag] {
            if model.stuckKeys.contains(absoluteNote) {
                model.stuckKeys.remove(absoluteNote)
                switch keyStyle {
                case .normal:
                    key.backgroundColor = ColorTheme.background
                case .shaded, .disabled:
                    key.backgroundColor = ColorTheme.shadedKey
                }
                keyDelegate?.keyDidGetReleased(absoluteNote: absoluteNote)
            } else {
                model.stuckKeys.insert(absoluteNote)
                key.backgroundColor = ColorTheme.activeKey
                keyDelegate?.keyDidGetPressed(absoluteNote: absoluteNote)
            }
        }
    }
}
