//
//  GridKeyboardViewController.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/10/21.
//

import UIKit


/// The main piano view controller.
class GridKeyboardViewController: UIViewController {

    enum KeysPerOctave: String, CaseIterable {
        case chromaticKeys
        case diatonicKeys
        
        var name: String {
            switch self {
            case .chromaticKeys:
                return "Chromatic (all 12 keys)"
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
        if isViewLoaded {
            _reconfigureToolbar()
            _reconfigureKeyRows()
        }
    }
    
    // MARK: - Internals
    
    private var _rows: [KeyRowView] = []
    private var _toolbar: UIToolbar!

    override func viewDidLoad() {
        super.viewDidLoad()

        func assembleViewHierarchy() {
            _toolbar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(_toolbar)

            for row in _rows {
                row.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(row)
            }

            // toolbar height.
            _toolbar.heightAnchor.constraint(equalToConstant: 44).isActive = true

            // pin the toolbar to the top and sides.
            view.topAnchor.constraint(equalTo: _toolbar.topAnchor).isActive = true
            view.leadingAnchor.constraint(equalTo: _toolbar.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: _toolbar.trailingAnchor).isActive = true

            // pin the toolbar bottom the the first row of keys.
            _toolbar.bottomAnchor.constraint(equalTo: _rows.first!.topAnchor).isActive = true

            // stack the key rows vertically.
            for i in 0..<(model.octaves.count-1) {
                _rows[i].bottomAnchor.constraint(equalTo: _rows[i+1].topAnchor).isActive = true
            }

            // set the key rows to have equal heights.
            for row in _rows.dropFirst() {
                row.heightAnchor.constraint(equalTo: _rows.first!.heightAnchor).isActive = true
            }

            let guide = view.layoutMarginsGuide

            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                // on iPhone, pin the key rows all the way to the edges of the screen.
                for row in _rows {
                    view.leadingAnchor.constraint(equalTo: row.leadingAnchor).isActive = true
                    view.trailingAnchor.constraint(equalTo: row.trailingAnchor).isActive = true
                }
                view.bottomAnchor.constraint(equalTo: _rows.last!.bottomAnchor).isActive = true
            case .pad:
                // on iPad, pin the key rows to the layout margin guide.
                for row in _rows {
                    guide.leadingAnchor.constraint(equalTo: row.leadingAnchor).isActive = true
                    guide.trailingAnchor.constraint(equalTo: row.trailingAnchor).isActive = true
                }
                guide.bottomAnchor.constraint(
                    equalToSystemSpacingBelow: _rows.last!.bottomAnchor,
                    multiplier: 2)
                .isActive = true
            default:
                fatalError()
            }
        }
        
        for _ in model.octaves {
            _rows.append(KeyRowView())
        }

        view.backgroundColor = UIColor.white

        // Using UIToolbar.init() results in constraint conflicts, so instead we init with a frame.
        _toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))

        assembleViewHierarchy()
        _reconfigureToolbar()
        _reconfigureKeyRows()
    }

    /// (Re)Populate the toolbar with labels and buttons according to our model.
    private func _reconfigureToolbar() {
        _toolbar.barTintColor = UIColor.white
        var items = [UIBarButtonItem]()

        let titleItem = UIBarButtonItem.init(
            title: "GridNotes \(Bundle.main.marketingVersion)",
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

        _toolbar.setItems(items, animated: false)
    }

    /// (Re)Configure the key rows according to our model.
    private func _reconfigureKeyRows() {
        
        func reconfigureKeyRow(index: Int, octave: Octave) {
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
            _rows[index].set(model: rowModel)
        }
        
        self.model.stuckKeys = []
        stopPlayingAllNotes()

        for (i, octave) in model.octaves.reversed().enumerated() {
            reconfigureKeyRow(index: i, octave: octave)
        }
        for row in _rows {
            row.delegate = self
        }
    }
    
    // Allow button presses to register near the edges of the screen.
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge {
        return .all
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    // MARK: - Target/Action
    
    /// Action to present the settings screen.
    @objc func didPressSettings() {
        let settingsVC = SettingsViewController()
        settingsVC.set(model: model)

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
    
    /// Action for the button which clears all of the stuck keys.
    @objc func didPressClear() {
        for note in model.stuckKeys {
            keyDidGetReleased(absoluteNote: note)
        }
        _reconfigureKeyRows()
    }
}

extension GridKeyboardViewController: KeyRowDelegate {
    
    func keyDidGetPressed(absoluteNote: AbsoluteNote) {
        startPlaying(absoluteNote: absoluteNote)
        if model.stickyKeys {
            model.stuckKeys.insert(absoluteNote)
        }
        _reconfigureToolbar()
    }
    
    func keyDidGetReleased(absoluteNote: AbsoluteNote) {
        stopPlaying(absoluteNote: absoluteNote)
        if model.stickyKeys {
            model.stuckKeys.remove(absoluteNote)
        }
        _reconfigureToolbar()
    }
}


extension Bundle {
    var marketingVersion: String {
        return infoDictionary!["CFBundleShortVersionString"] as! String
    }
}
