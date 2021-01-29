//
//  KeyRowView.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/10/21.
//

import UIKit


protocol KeyDelegate {
    func keyDidGetPressed(absoluteNote: AbsoluteNote)
    func keyDidGetReleased(absoluteNote: AbsoluteNote)
}


enum KeyStyle: String {
    case normal
    case shaded
    case disabled
}


/// A row of 7 or 12 piano keys (buttons).
class KeyRowView: UIView {
    
    struct Model {
        var styledNotes: [(AbsoluteNote, KeyStyle)?] = []
        var stickyKeys: Bool = false
        var stuckKeys: Set<Int> = []
    }

    private(set) var model: Model = Model()
    
    func set(model: Model) {
        self.model = model
        _apply(model: model)
    }
    
    var keyDelegate: KeyDelegate? = nil

    /// All of the notes being depressed by the user.
    var depressedNotes: Set<AbsoluteNote> {
        return Set<AbsoluteNote>(
            _keys
                .filter { $0.state == .selected }
                .map { model.styledNotes[$0.tag]?.0 }
                .compactMap { $0 }
        )
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        _apply(model: model)
    }
    
    // MARK: - Internals

    /// The piano keys in this row.
    private var _keys: [UIButton] = []
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateConstraints() {
        super.updateConstraints()
        if _hasSetUpConstraints { return }
        _hasSetUpConstraints = true

        // Pin each key to the top and bottom of the row.
        for k in _keys {
            topAnchor.constraint(equalTo: k.topAnchor).isActive = true
            bottomAnchor.constraint(equalTo: k.bottomAnchor).isActive = true
        }

        // Pin the first key's leading edge to the leading edge of the row.
        leadingAnchor.constraint(equalTo: _keys.first!.leadingAnchor).isActive = true
        
        // Stack the keys horizontally.
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
            // Otherwise, pin the last key's trailing edge to the row's trailing edge.
            trailingAnchor.constraint(equalTo: _keys.last!.trailingAnchor).isActive = true
        }

        // Set the keys to have equal widths.
        for k in _keys.dropFirst() {
            _keys.first!.widthAnchor.constraint(equalTo: k.widthAnchor).isActive = true
        }
    }
    private var _hasSetUpConstraints: Bool = false

    /// (Re)Construct the views according to the model.
    private func _apply(model: Model) {

        func setupKey(index: Int, styledNote: (AbsoluteNote, KeyStyle)?) {
            let key = UIButton(type: .system)
            key.translatesAutoresizingMaskIntoConstraints = false
            addSubview(key)
            key.layer.borderWidth = 1
            key.layer.borderColor = ColorTheme.separator.cgColor
            key.titleLabel?.adjustsFontSizeToFitWidth = true
            key.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
            key.titleLabel?.lineBreakMode = .byWordWrapping
            key.titleLabel?.textAlignment = .center
            key.tag = index

            switch styledNote {

            case let .some((absoluteNote, keyStyle)):
                let title = absoluteNote.buttonText
                key.setTitle(title, for: .normal)

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

            _keys.append(key)
        }

        // Discard any previous keys.
        for subview in subviews {
            subview.removeFromSuperview()
        }
        _keys.removeAll()

        // Install the replacement keys.
        for (i, styledNote) in model.styledNotes.enumerated() {
            setupKey(index: i, styledNote: styledNote)
        }

        // Redo the constraints.
        _hasSetUpConstraints = false
        setNeedsUpdateConstraints()
    }

    // MARK: - Target/Action

    /// The pressed action is used when pressing a non-sticky key.
    @objc func keyDidGetPressed(key: UIButton) {
        precondition(model.stickyKeys == false)
        guard let (absoluteNote, _) = model.styledNotes[key.tag] else { return }
        key.backgroundColor = ColorTheme.activeKey
        keyDelegate?.keyDidGetPressed(absoluteNote: absoluteNote)
    }
    
    /// The pressed action is used when releasing a non-sticky key.
    @objc func keyDidGetReleased(key: UIButton) {
        precondition(model.stickyKeys == false)
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
        precondition(model.stickyKeys == true)
        let index = key.tag
        if let (absoluteNote, keyStyle) = model.styledNotes[index] {
            if model.stuckKeys.contains(index) {
                model.stuckKeys.remove(index)
                switch keyStyle {
                case .normal:
                    key.backgroundColor = ColorTheme.background
                case .shaded, .disabled:
                    key.backgroundColor = ColorTheme.shadedKey
                }
                keyDelegate?.keyDidGetReleased(absoluteNote: absoluteNote)
            } else {
                model.stuckKeys.insert(index)
                key.backgroundColor = ColorTheme.activeKey
                keyDelegate?.keyDidGetPressed(absoluteNote: absoluteNote)
            }
        }
    }
}
