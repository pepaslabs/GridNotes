//
//  GridKeyboardViewController.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/10/21.
//

import UIKit


class GridKeyboardViewController: UIViewController {

    var rows: [KeyRowView] = []
    var toolbar: UIToolbar!

    enum KeysPerOctave: String, CaseIterable {
        case chromaticKeys
        case diatonicKeys
        
        var name: String {
            switch self {
            case .chromaticKeys:
                return "Chromatic (all keys)"
            case .diatonicKeys:
                return "Diatonic (only in-scale keys)"
            }
        }
    }
    
    enum NonDiatonicKeyStyle: String, CaseIterable {
        case shaded
        case disabled
        
        var name: String {
            switch self {
            case .shaded:
                return "Shaded, but Enabled"
            case .disabled:
                return "Shaded and Disabled"
            }
        }
    }
    
    struct Model {
        var tonicNote: Note
        var scale: Scale
        var octaves: [Octave]
        var keysPerOctave: KeysPerOctave
        var nonScaleStyle: NonDiatonicKeyStyle
        var stickyKeys: Bool
        var stuckKeys: Set<AbsoluteNote>
        
        static var defaultModel: Model {
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                return Model(
                    tonicNote: .C,
                    scale: .major,
                    octaves: Octave.octavesForPhone,
                    keysPerOctave: .diatonicKeys,
                    nonScaleStyle: .disabled,
                    stickyKeys: false,
                    stuckKeys: []
                )
            case .pad:
                return Model(
                    tonicNote: .C,
                    scale: .major,
                    octaves: Octave.octavesForPad,
                    keysPerOctave: .chromaticKeys,
                    nonScaleStyle: .disabled,
                    stickyKeys: false,
                    stuckKeys: []
                )
            default:
                fatalError()
            }
        }
    }
    
    private(set) var model: Model = Model.defaultModel
    
    func set(model: Model) {
        self.model = model
        _configureToolbar()
        _configureKeyRows()
    }
    
    // MARK: - Internals
    
    override func viewDidLoad() {
        super.viewDidLoad()

        for _ in model.octaves {
            rows.append(KeyRowView())
        }

        func assembleViewHierarchy() {
            toolbar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(toolbar)

            for row in rows {
                row.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(row)
            }

            view.topAnchor.constraint(equalTo: toolbar.topAnchor).isActive = true
            view.leadingAnchor.constraint(equalTo: toolbar.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor).isActive = true
            toolbar.bottomAnchor.constraint(equalTo: rows.first!.topAnchor).isActive = true
            toolbar.heightAnchor.constraint(equalToConstant: 44).isActive = true

            for i in 0..<(model.octaves.count-1) {
                rows[i].bottomAnchor.constraint(equalTo: rows[i+1].topAnchor).isActive = true
            }

            for i in 1..<model.octaves.count {
                rows[i].heightAnchor.constraint(equalTo: rows[0].heightAnchor).isActive = true
            }

            let guide = view.layoutMarginsGuide

            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                for row in rows {
                    view.leadingAnchor.constraint(equalTo: row.leadingAnchor).isActive = true
                    view.trailingAnchor.constraint(equalTo: row.trailingAnchor).isActive = true
                }
                view.bottomAnchor.constraint(equalTo: rows.last!.bottomAnchor).isActive = true
            case .pad:
                for row in rows {
                    guide.leadingAnchor.constraint(equalTo: row.leadingAnchor).isActive = true
                    guide.trailingAnchor.constraint(equalTo: row.trailingAnchor).isActive = true
                }
                guide.bottomAnchor.constraint(
                    equalToSystemSpacingBelow: rows.last!.bottomAnchor,
                    multiplier: 2)
                .isActive = true
            default:
                fatalError()
            }
        }
        
        view.backgroundColor = UIColor.white

        // Using UIToolbar.init() results in constraint conflicts, so instead we init with a frame.
        toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))

        assembleViewHierarchy()
        _configureToolbar()
        _configureKeyRows()
    }

    private func _configureToolbar() {
        toolbar.barTintColor = UIColor.white
        var items = [UIBarButtonItem]()

        let titleItem = UIBarButtonItem.init(
            title: "GridNotes",
            style: .done,
            target: nil,
            action: nil
        )
        titleItem.isEnabled = false
        titleItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .disabled)
        items.append(titleItem)

        items.append(
            UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        )

        if model.stuckKeys.count > 0 {
            items.append(
                UIBarButtonItem.init(
                    title: "Clear",
                    style: .done,
                    target: self,
                    action: #selector(didPressClear)
                )
            )

            items.append(
                UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            )
        }

        items.append(
            UIBarButtonItem.init(
                title: "\(model.tonicNote.name) \(model.scale.name)",
                style: .done,
                target: self,
                action: #selector(didPressSettings)
            )
        )

        toolbar.setItems(items, animated: false)
    }

    @objc func didPressClear() {
        for note in model.stuckKeys {
            keyDidGetReleased(absoluteNote: note)
        }
        _configureKeyRows()
    }
    
    private func _configureKeyRows() {
        self.model.stuckKeys = []
        stopPlayingAllNotes()

        for (i, octave) in model.octaves.reversed().enumerated() {
            _configureKeyRow(index: i, octave: octave)
        }
        for row in rows {
            row.delegate = self
        }
    }

    private func _configureKeyRow(index: Int, octave: Octave) {
        let firstNote = AbsoluteNote(note: model.tonicNote, octave: octave)
        let allNotes = AbsoluteNote.chromaticScale(from: firstNote)
        let scaleIndices = model.scale.semitoneIndices

        let styledNotes: [(AbsoluteNote, KeyRowView.KeyStyle)?]
        switch model.keysPerOctave {

        case .chromaticKeys:
            styledNotes = allNotes.enumerated().map { (index, note) in
                if let note = note {
                    if scaleIndices.contains(index) {
                        return (note, .normal)
                    } else {
                        let keyStyle = KeyRowView.KeyStyle(rawValue: model.nonScaleStyle.rawValue)!
                        return (note, keyStyle)
                    }
                } else {
                    return nil
                }

            }

        case .diatonicKeys:
            styledNotes = model.scale.absoluteNotes(fromTonic: firstNote).map { note in
                guard let note = note else { return nil }
                return (note, KeyRowView.KeyStyle.normal)
            }

        }

        let rowModel = KeyRowView.Model(styledNotes: styledNotes, stickyKeys: model.stickyKeys)
        rows[index].set(model: rowModel)
    }
    
    // Allow button presses to register near the edges of the screen.
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .all
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .landscape
        case .pad:
            return .all
        default:
            fatalError()
        }
    }
    
    // MARK: - Target/Action
    
    @objc func didPressSettings() {
        let settingsVC = SettingsViewController()
        settingsVC.model = model
        settingsVC.modelDidChange = { [weak self] model in
            guard let self = self else { return }
            self.set(model: model)
            self.dismissSettings()
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
}

extension GridKeyboardViewController: KeyRowDelegate {
    
    func keyDidGetPressed(absoluteNote: AbsoluteNote) {
        startPlaying(absoluteNote: absoluteNote)
        if model.stickyKeys {
            model.stuckKeys.insert(absoluteNote)
        }
        _configureToolbar()
    }
    
    func keyDidGetReleased(absoluteNote: AbsoluteNote) {
        stopPlaying(absoluteNote: absoluteNote)
        if model.stickyKeys {
            model.stuckKeys.remove(absoluteNote)
        }
        _configureToolbar()
    }
}
