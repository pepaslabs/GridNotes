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
    
    struct Model {
        var notes: [AbsoluteNote?] = []
    }

    var model: Model = Model() {
        didSet {
            _reloadViews()
        }
    }
    
    var delegate: KeyRowDelegate? = nil

    var keys: [UIButton] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        _reloadViews()
    }
    
    // MARK: - Internals
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var _hasSetUpConstraints: Bool = false
    override func updateConstraints() {
        super.updateConstraints()
        if !_hasSetUpConstraints {
            _hasSetUpConstraints = true

            for k in keys {
                topAnchor.constraint(equalTo: k.topAnchor).isActive = true
                bottomAnchor.constraint(equalTo: k.bottomAnchor).isActive = true
            }

            leadingAnchor.constraint(equalTo: keys.first!.leadingAnchor).isActive = true
            for i in 0..<(keys.count-1) {
                keys[i+1].leadingAnchor.constraint(equalTo: keys[i].trailingAnchor).isActive = true
            }
            trailingAnchor.constraint(equalTo: keys.last!.trailingAnchor).isActive = true

            for k in keys.dropFirst() {
                keys.first!.widthAnchor.constraint(equalTo: k.widthAnchor).isActive = true
            }
        }
    }

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
        keys.removeAll()
        
        for (i, note) in model.notes.enumerated() {
            let key = UIButton()
            key.translatesAutoresizingMaskIntoConstraints = false
            addSubview(key)
            key.layer.borderWidth = 1
            key.layer.borderColor = UIColor.blue.cgColor
            key.titleLabel?.adjustsFontSizeToFitWidth = true
            key.contentEdgeInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
            key.titleLabel?.lineBreakMode = .byWordWrapping
            key.titleLabel?.textAlignment = .center
            key.tag = i
            key.addTarget(self, action: #selector(keyDidGetPressed(key:)), for: .touchDown)
            key.addTarget(self, action: #selector(keyDidGetReleased(key:)), for: .touchUpInside)
            key.addTarget(self, action: #selector(keyDidGetReleased(key:)), for: .touchDragExit)
            key.addTarget(self, action: #selector(keyDidGetReleased(key:)), for: .touchCancel)
            keys.append(key)

            if let note = note {
                let title = buttonText(absoluteNote: note)
                key.setTitle(title, for: .normal)
                key.setTitleColor(UIColor.systemBlue, for: .normal)
            }
        }

        _hasSetUpConstraints = false
        setNeedsUpdateConstraints()
    }

    // MARK: - Target/Action
    
    @objc func keyDidGetPressed(key: UIButton) {
        if let absoluteNote = model.notes[key.tag] {
            key.backgroundColor = UIColor.yellow
            delegate?.keyDidGetPressed(absoluteNote: absoluteNote)
        }
    }
    
    @objc func keyDidGetReleased(key: UIButton) {
        if let absoluteNote = model.notes[key.tag] {
            key.backgroundColor = UIColor.clear
            delegate?.keyDidGetReleased(absoluteNote: absoluteNote)
        }
    }
}
