//
//  KeyRowView.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/10/21.
//

import UIKit


protocol KeyRowDelegate {
    func keyDidGetPressed(absoluteNote: AbsoluteNote)
    func keyDidGetReleased(absoluteNote: AbsoluteNote)
}


class KeyRowView: UIView {

    enum KeyStyle: String {
        case normal
        case shaded
        case disabled
    }
    
    struct Model {
        var styledNotes: [(AbsoluteNote, KeyStyle)?] = []
        var stickyKeys: Bool = false
        var stuckKeys: Set<Int> = []
    }

    private(set) var model: Model = Model()
    
    func set(model: Model) {
        self.model = model
        _reloadViews()
    }
    
    var delegate: KeyRowDelegate? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        _reloadViews()
    }
    
    // MARK: - Internals

    private static let _shadedGray: UIColor = UIColor(white: 0.85, alpha: 1)

    private var _keys: [UIButton] = []
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()
        if !_hasSetUpConstraints {
            _hasSetUpConstraints = true

            // pin each key to the top and bottom of the row.
            for k in _keys {
                topAnchor.constraint(equalTo: k.topAnchor).isActive = true
                bottomAnchor.constraint(equalTo: k.bottomAnchor).isActive = true
            }

            // pin the first key's leading edge to the leading edge of the row.
            leadingAnchor.constraint(equalTo: _keys.first!.leadingAnchor).isActive = true
            
            // stack the keys horizontally.
            for i in 0..<(_keys.count-1) {
                _keys[i+1].leadingAnchor.constraint(equalTo: _keys[i].trailingAnchor).isActive = true
            }
            
            if UIDevice.current.userInterfaceIdiom == .pad, _keys.count < 12 {
                // On iPad, when using less than 12 keys, don't expand the row to full width (use 1/12th per key).
                _keys.first!.widthAnchor.constraint(
                    equalTo: widthAnchor,
                    multiplier: 1.0 / 12.0
                ).isActive = true
            } else {
                // otherwise, pin the last key's trailing edge to the row's trailing edge.
                trailingAnchor.constraint(equalTo: _keys.last!.trailingAnchor).isActive = true
            }

            // set the keys to have equal widths.
            for k in _keys.dropFirst() {
                _keys.first!.widthAnchor.constraint(equalTo: k.widthAnchor).isActive = true
            }
        }
    }
    private var _hasSetUpConstraints: Bool = false

    /// (Re)Construct the views according to the model.
    private func _reloadViews() {
        
        func buttonText(absoluteNote: AbsoluteNote) -> String {
            let note = absoluteNote.note
            let octave = absoluteNote.octave
            switch note {
            case .A, .B, .C, .D, .E, .F, .G:
                return "\(note.rawValue)\(octave.rawValue)"
            case .AsBb:
                return "A\(octave.rawValue)♯\nB\(octave.rawValue)♭"
            case .CsDb:
                return "C\(octave.rawValue)♯\nD\(octave.rawValue)♭"
            case .DsEb:
                return "D\(octave.rawValue)♯\nE\(octave.rawValue)♭"
            case .FsGb:
                return "F\(octave.rawValue)♯\nG\(octave.rawValue)♭"
            case .GsAb:
                return "G\(octave.rawValue)♯\nA\(octave.rawValue)♭"
            }
        }
        
        for subview in subviews {
            subview.removeFromSuperview()
        }
        _keys.removeAll()
        
        for (i, styledNote) in model.styledNotes.enumerated() {
            let key = UIButton(type: .system)
            key.translatesAutoresizingMaskIntoConstraints = false
            addSubview(key)
            key.layer.borderWidth = 1
            key.layer.borderColor = UIColor(white: 0.15, alpha: 1).cgColor
            key.titleLabel?.adjustsFontSizeToFitWidth = true
            key.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
            key.titleLabel?.lineBreakMode = .byWordWrapping
            key.titleLabel?.textAlignment = .center
            key.tag = i

            if let (absoluteNote, keyStyle) = styledNote {
                let title = buttonText(absoluteNote: absoluteNote)
                key.setTitle(title, for: .normal)

                switch keyStyle {
                case .normal:
                    key.isEnabled = true
                    key.backgroundColor = UIColor.white
                case .shaded:
                    key.isEnabled = true
                    key.backgroundColor = KeyRowView._shadedGray
                case .disabled:
                    key.isEnabled = false
                    key.backgroundColor = KeyRowView._shadedGray
                }
                
                if model.stickyKeys {
                    key.addTarget(self, action: #selector(keyDidGetToggled(key:)), for: .touchDown)
                } else {
                    key.addTarget(self, action: #selector(keyDidGetPressed(key:)), for: .touchDown)
                    key.addTarget(self, action: #selector(keyDidGetReleased(key:)), for: .touchUpInside)
                    key.addTarget(self, action: #selector(keyDidGetReleased(key:)), for: .touchDragExit)
                    key.addTarget(self, action: #selector(keyDidGetReleased(key:)), for: .touchCancel)
                }

            } else {
                key.isEnabled = false
                key.backgroundColor = KeyRowView._shadedGray
            }

            _keys.append(key)
        }

        _hasSetUpConstraints = false
        setNeedsUpdateConstraints()
    }

    // MARK: - Target/Action
    
    @objc func keyDidGetPressed(key: UIButton) {
        if let (absoluteNote, _) = model.styledNotes[key.tag] {
            key.backgroundColor = UIColor.yellow
            delegate?.keyDidGetPressed(absoluteNote: absoluteNote)
        }
    }
    
    @objc func keyDidGetReleased(key: UIButton) {
        if let (absoluteNote, keyStyle) = model.styledNotes[key.tag] {
            switch keyStyle {
            case .normal:
                key.backgroundColor = UIColor.white
            case .shaded, .disabled:
                key.backgroundColor = KeyRowView._shadedGray
            }
            delegate?.keyDidGetReleased(absoluteNote: absoluteNote)
        }
    }
    
    @objc func keyDidGetToggled(key: UIButton) {
        if let (absoluteNote, keyStyle) = model.styledNotes[key.tag] {
            if model.stuckKeys.contains(key.tag) {
                model.stuckKeys.remove(key.tag)
                switch keyStyle {
                case .normal:
                    key.backgroundColor = UIColor.white
                case .shaded, .disabled:
                    key.backgroundColor = KeyRowView._shadedGray
                }
                delegate?.keyDidGetReleased(absoluteNote: absoluteNote)
            } else {
                model.stuckKeys.insert(key.tag)
                key.backgroundColor = UIColor.yellow
                delegate?.keyDidGetPressed(absoluteNote: absoluteNote)
            }
        }
    }
}
