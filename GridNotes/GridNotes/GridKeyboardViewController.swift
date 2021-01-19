//
//  GridKeyboardViewController.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/10/21.
//

import UIKit


/// The grid-layout piano view controller.
class GridKeyboardViewController: UIViewController, InterfaceDelegating {
    
    private(set) var state: AppState = AppState.defaultState
    
    func set(state: AppState) {
        self.state = state
        if isViewLoaded {
            _reconfigureToolbar()
            _reconfigureKeyRows()
        }
    }
    
    public var interfaceDelegate: InterfaceChanging? = nil
    
    init(state: AppState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Internals
    
    private var _rows: [KeyRowView] = []
    private var _toolbar: UIToolbar!

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
            for i in 0..<(state.octaves.count-1) {
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
        
        for _ in state.octaves {
            _rows.append(KeyRowView())
        }

        view.backgroundColor = ColorTheme.background

        // Using UIToolbar.init() results in constraint conflicts, so instead we init with a frame.
        _toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))

        assembleViewHierarchy()
        _reconfigureToolbar()
        _reconfigureKeyRows()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // for some reason, a simple setNeedsDisplay() is not sufficient to fully account for a dark-mode change.
        didPressClear()
    }

    /// (Re)Populate the toolbar with labels and buttons according to our model.
    private func _reconfigureToolbar() {
        _toolbar.barTintColor = ColorTheme.background
        var items = [UIBarButtonItem]()

        let titleItem = UIBarButtonItem.init(
            title: "GridNotes \(Bundle.main.marketingVersion)",
            style: .done,
            target: nil,
            action: nil
        )
        titleItem.isEnabled = false
        titleItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: ColorTheme.label], for: .disabled)
        items.append(titleItem)

        items.append(
            UIBarButtonItem.init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        )

        if state.stuckKeys.count > 0 {
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
                title: "\(state.tonicNote.name) \(state.scale.name)",
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
            let tonicNote = AbsoluteNote(note: state.tonicNote, octave: octave)
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
                styledNotes = state.scale.absoluteNotes(fromTonic: tonicNote).map { note in
                    guard let note = note else { return nil }
                    return (note, KeyStyle.normal)
                }

            }

            let rowModel = KeyRowView.Model(styledNotes: styledNotes, stickyKeys: state.stickyKeys)
            _rows[index].set(model: rowModel)
        }
        
        self.state.stuckKeys = []
        stopPlayingAllNotes()

        for (i, octave) in state.octaves.reversed().enumerated() {
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
        didPressClear()
        
        let settingsVC = SettingsViewController(style: .grouped)
        settingsVC.set(state: state)

        settingsVC.appStateDidChange = { [weak self] state in
            guard let self = self else { return }
            self.set(state: state)
            self.dismissSettings()
            if state.interface != .grid {
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
    
    /// Action for the button which clears all of the stuck keys.
    @objc func didPressClear() {
        for note in state.stuckKeys {
            keyDidGetReleased(absoluteNote: note)
        }
        _reconfigureKeyRows()
    }
}

extension GridKeyboardViewController: KeyDelegate {
    
    func keyDidGetPressed(absoluteNote: AbsoluteNote) {
        startPlaying(absoluteNote: absoluteNote)
        if state.stickyKeys {
            state.stuckKeys.insert(absoluteNote)
        }
        _reconfigureToolbar()
    }
    
    func keyDidGetReleased(absoluteNote: AbsoluteNote) {
        stopPlaying(absoluteNote: absoluteNote)
        if state.stickyKeys {
            state.stuckKeys.remove(absoluteNote)
        }
        _reconfigureToolbar()
    }
}
