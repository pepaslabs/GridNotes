//
//  RingKeyboardViewController.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/17/21.
//

import UIKit


/// The ring-layout piano view controller.
class RingKeyboardViewController: UIViewController, InterfaceDelegating {

    var state: AppState
    
    func set(state: AppState) {
        self.state = state
        _apply(state: state)
    }
    
    var interfaceDelegate: InterfaceChanging? = nil
    
    init(state: AppState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Internals
    
    private let _ringView: RingKeyboardView = RingKeyboardView()
    private let _settingsButton: UIButton = UIButton(type: .system)
    private let _clearButton: UIButton = UIButton(type: .system)
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white

        // configure the ring view.
        _ringView.delegate = self
        _ringView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(_ringView)
        view.topAnchor.constraint(equalTo: _ringView.topAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: _ringView.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: _ringView.trailingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: _ringView.bottomAnchor).isActive = true

        // configure the app label.
        let appNameLabel: UILabel = UILabel()
        appNameLabel.textColor = UIColor.darkGray
        appNameLabel.text = "GridNotes \(Bundle.main.marketingVersion)"
        appNameLabel.font = UIFont.boldSystemFont(ofSize: appNameLabel.font.pointSize)
        appNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(appNameLabel)
        // pin to upper left of screen.
        appNameLabel.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 1).isActive = true
        appNameLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 1).isActive = true

        // configure the settings button.
        _settingsButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: _settingsButton.titleLabel!.font.pointSize)
        _settingsButton.addTarget(self, action: #selector(didPressSettings), for: .touchUpInside)
        _settingsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(_settingsButton)
        // pin to upper right of screen.
        _settingsButton.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 1).isActive = true
        view.trailingAnchor.constraint(equalToSystemSpacingAfter: _settingsButton.trailingAnchor, multiplier: 1).isActive = true

        // configure the clear button.
        _clearButton.setTitle("Clear", for: .normal)
        _clearButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: _clearButton.titleLabel!.font.pointSize)
        _clearButton.addTarget(self, action: #selector(didPressClear), for: .touchUpInside)
        _clearButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(_clearButton)
        // pin to lower left of screen.
        view.bottomAnchor.constraint(equalToSystemSpacingBelow: _clearButton.bottomAnchor, multiplier: 1).isActive = true
        _clearButton.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 1).isActive = true

        _apply(state: state)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    private func _apply(state: AppState) {
        _settingsButton.setTitle("\(state.tonicNote.name) \(state.scale.name)", for: .normal)
        _reconfigureClearButton()

        let tonicNote = AbsoluteNote(note: state.tonicNote, octave: .four)
        let styledNotes: [(AbsoluteNote, KeyStyle)?]
        switch state.keysPerOctave {

        case .chromaticKeys:
            let allNotes = AbsoluteNote.chromaticScale(from: tonicNote)
            let scaleIndices = state.scale.semitoneIndices
            styledNotes = allNotes.enumerated().map { (index, note) in
                if let note = note {
                    if scaleIndices.contains(index) {
                        return (note, .normal)
                    } else {
                        let keyStyle = KeyStyle(rawValue: state.nonScaleStyle.rawValue)!
                        return (note, keyStyle)
                    }
                } else {
                    return nil
                }

            }

        case .diatonicKeys:
            styledNotes = state.scale.sparseAbsoluteNotes(fromTonic: tonicNote).map { note in
                guard let note = note else { return nil }
                return (note, KeyStyle.normal)
            }

        }

        let model: RingKeyboardView.Model = RingKeyboardView.Model(
            styledNotes: styledNotes,
            stickyKeys: state.stickyKeys,
            stuckKeys: state.stuckKeys
        )
        _ringView.set(model: model)
    }

    private func _reconfigureClearButton() {
        let shouldShowClearButton = state.stickyKeys && state.stuckKeys.count > 0
        _clearButton.isHidden = !shouldShowClearButton
    }

    // MARK: - Target/Action
    
    @objc func didPressSettings() {
        didPressClear()

        let settingsVC = SettingsViewController(style: .grouped)
        settingsVC.set(state: state)

        settingsVC.appStateDidChange = { [weak self] state in
            guard let self = self else { return }
            self.set(state: state)
            self.dismissSettings()
            if state.interface != .ring {
                self.interfaceDelegate?.interfaceDidGetSelected(interface: state.interface, state: state)
            }
        }

        settingsVC.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissSettings)
        )
        let nav = UINavigationController(rootViewController: settingsVC)
        present(nav, animated: true)
    }
    
    @objc func dismissSettings() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didPressClear() {
        for note in state.stuckKeys {
            keyDidGetReleased(absoluteNote: note)
        }
        _apply(state: state)
    }
}

extension RingKeyboardViewController: KeyDelegate {
    
    func keyDidGetPressed(absoluteNote: AbsoluteNote) {
        startPlaying(absoluteNote: absoluteNote)
        if state.stickyKeys {
            state.stuckKeys.insert(absoluteNote)
        }
        _reconfigureClearButton()
    }
    
    func keyDidGetReleased(absoluteNote: AbsoluteNote) {
        stopPlaying(absoluteNote: absoluteNote)
        if state.stickyKeys {
            state.stuckKeys.remove(absoluteNote)
        }
        _reconfigureClearButton()
    }
}


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

    var delegate: KeyDelegate? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.white
        _apply(model: model)
    }
    
    // MARK: - Internals
    
    private var _keys: [UIButton] = []
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

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

    override func draw(_ rect: CGRect) {

        func drawButtonCenterlineCircle() {
            let circleRect: CGRect = CGRect
                .square(dimension: _buttonCenterlineDiameter)
                .centered(within: rect)
            let path = UIBezierPath(ovalIn: circleRect)
            path.lineWidth = round(_semitoneTickmarkLength * 0.1)
            UIColor.darkGray.setStroke()
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
                UIColor.darkGray.setStroke()
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
    
    private func _apply(model: Model) {
        for k in _keys {
            k.removeFromSuperview()
        }
        _keys.removeAll()

        for (i, pair) in model.styledNotes.enumerated() {
            let key = UIButton(type: .system)
            key.translatesAutoresizingMaskIntoConstraints = false
            key.backgroundColor = UIColor.white
            key.layer.borderColor = UIColor.darkGray.cgColor
            key.titleLabel?.adjustsFontSizeToFitWidth = true
            key.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
            key.titleLabel?.lineBreakMode = .byWordWrapping
            key.titleLabel?.textAlignment = .center
            key.tag = i

            switch pair {

            case let .some((absoluteNote, style)):
                key.setTitle(absoluteNote.buttonText, for: .normal)

                switch style {
                case .normal:
                    key.isEnabled = true
                    key.backgroundColor = UIColor.white
                case .shaded:
                    key.isEnabled = true
                    key.backgroundColor = UIColor.shadedKeyGray
                case .disabled:
                    key.isEnabled = false
                    key.backgroundColor = UIColor.shadedKeyGray
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
                key.backgroundColor = UIColor.shadedKeyGray
            }
        }
        
        setNeedsLayout()
    }

    // MARK: - Target/Action
    
    @objc func keyDidGetPressed(key: UIButton) {
        guard let (absoluteNote, _) = model.styledNotes[key.tag] else { return }
        key.backgroundColor = UIColor.yellow
        delegate?.keyDidGetPressed(absoluteNote: absoluteNote)
    }

    @objc func keyDidGetReleased(key: UIButton) {
        guard let (absoluteNote, keyStyle) = model.styledNotes[key.tag] else { return }
        switch keyStyle {
        case .normal:
            key.backgroundColor = UIColor.white
        case .shaded, .disabled:
            key.backgroundColor = UIColor.shadedKeyGray
        }
        delegate?.keyDidGetReleased(absoluteNote: absoluteNote)
    }
    
    @objc func keyDidGetToggled(key: UIButton) {
        if let (absoluteNote, keyStyle) = model.styledNotes[key.tag] {
            if model.stuckKeys.contains(absoluteNote) {
                model.stuckKeys.remove(absoluteNote)
                switch keyStyle {
                case .normal:
                    key.backgroundColor = UIColor.white
                case .shaded, .disabled:
                    key.backgroundColor = UIColor.shadedKeyGray
                }
                delegate?.keyDidGetReleased(absoluteNote: absoluteNote)
            } else {
                model.stuckKeys.insert(absoluteNote)
                key.backgroundColor = UIColor.yellow
                delegate?.keyDidGetPressed(absoluteNote: absoluteNote)
            }
        }
    }
}
