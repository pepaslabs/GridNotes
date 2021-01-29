//
//  GridChordsKeyboardViewController.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/19/21.
//

import UIKit


/// The grid-layout piano view controller.
class GridChordsKeyboardViewController: UIViewController, InterfaceDelegating {
    
    private(set) var state: AppState = AppState.defaultState
    
    func set(state: AppState) {
        self.state = state
        if isViewLoaded {
            _apply(state: state)
        }
    }
    
    public var interfaceDelegate: InterfaceChanging? = nil
    
    init(state: AppState) {
        self.state = state
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: - Internals
    
    /// The rows of piano keys.
    private var _keyRows: [KeyRowView] = []

    /// The toolbar for the app label, clear button, and settings button.
    private var _toolbar: UIToolbar!

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // The view consists of a toolbar of buttons and several rows of keys.
    override func viewDidLoad() {
        super.viewDidLoad()

        func assembleViewHierarchy() {
            _toolbar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(_toolbar)

            for row in _keyRows {
                row.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(row)
            }

            // Toolbar height.
            _toolbar.heightAnchor.constraint(equalToConstant: 44).isActive = true

            // Pin the toolbar to the top and sides.
            view.topAnchor.constraint(equalTo: _toolbar.topAnchor).isActive = true
            view.leadingAnchor.constraint(equalTo: _toolbar.leadingAnchor).isActive = true
            view.trailingAnchor.constraint(equalTo: _toolbar.trailingAnchor).isActive = true

            // Pin the toolbar bottom the the first row of keys.
            _toolbar.bottomAnchor.constraint(equalTo: _keyRows.first!.topAnchor).isActive = true

            // Stack the key rows vertically.
            for i in 0..<(state.octaves.count-1) {
                _keyRows[i].bottomAnchor.constraint(equalTo: _keyRows[i+1].topAnchor).isActive = true
            }

            // Set the key rows to have equal heights.
            for row in _keyRows.dropFirst() {
                row.heightAnchor.constraint(equalTo: _keyRows.first!.heightAnchor).isActive = true
            }

            // The OS-level swipe gesture recognizers will steal some of our touches which are near the edge of the
            // screen (despite preferredScreenEdgesDeferringSystemGestures).  On iPhone, the screen real estate is
            // more important than losing a few touches.  On iPad, we can affort to use a bit of screen-edge margin
            // to avoid the lost touches.
            switch UIDevice.current.userInterfaceIdiom {
            case .phone:
                // On iPhone, pin the key rows all the way to the edges of the screen.
                for row in _keyRows {
                    view.leadingAnchor.constraint(equalTo: row.leadingAnchor).isActive = true
                    view.trailingAnchor.constraint(equalTo: row.trailingAnchor).isActive = true
                }
                view.bottomAnchor.constraint(equalTo: _keyRows.last!.bottomAnchor).isActive = true
            case .pad:
                // On iPad, pin the key rows to the layout margin guide.
                let guide = view.layoutMarginsGuide
                for row in _keyRows {
                    guide.leadingAnchor.constraint(equalTo: row.leadingAnchor).isActive = true
                    guide.trailingAnchor.constraint(equalTo: row.trailingAnchor).isActive = true
                }
                guide.bottomAnchor.constraint(
                    equalToSystemSpacingBelow: _keyRows.last!.bottomAnchor,
                    multiplier: 2)
                .isActive = true
            default:
                fatalError()
            }
        }
        
        for _ in state.octaves {
            _keyRows.append(KeyRowView())
        }

        view.backgroundColor = ColorTheme.background

        // UIToolbar.init() uses a zero frame and results in constraint conflicts, so instead we use init(frame).
        _toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
        _apply(state: state)
        assembleViewHierarchy()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // For some reason, a simple setNeedsDisplay() is not sufficient to fully account for a dark-mode change.
        didPressClear()
    }

    /// (Re)Configure the UI to reflect the application state.
    private func _apply(state: AppState) {
        _reconfigureToolbar(state: state)
        _reconfigureKeyRows(state: state)
    }

    /// (Re)Populate the toolbar with labels and buttons according to our model.
    private func _reconfigureToolbar(state: AppState) {
        _toolbar.barTintColor = ColorTheme.background
        var items = [UIBarButtonItem]()

        // The app name label.
        let titleItem = UIBarButtonItem.init(
            title: "GridChords \(Bundle.main.marketingVersion)",
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
            // The clear button.
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

        // The settings button.
        items.append(
            UIBarButtonItem.init(
                title: "\(state.tonicNote.displayName) \(state.scale.displayName)",
                style: .done,
                target: self,
                action: #selector(didPressSettings)
            )
        )

        _toolbar.setItems(items, animated: false)
    }

    /// (Re)Configure the key rows according to our model.
    private func _reconfigureKeyRows(state: AppState) {
        
        func reconfigureKeyRow(index: Int, octave: Octave) {
            let tonicNote = AbsoluteNote(note: state.tonicNote, octave: octave)
            let styledNotes: [(AbsoluteNote, KeyStyle)?]
            switch state.keysPerOctave {

            // 12 keys.
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

            // 7 keys.
            case .diatonicKeys:
                styledNotes = state.scale.absoluteNotes(fromTonic: tonicNote).map { note in
                    guard let note = note else { return nil }
                    return (note, KeyStyle.normal)
                }

            }

            let rowModel = KeyRowView.Model(styledNotes: styledNotes, stickyKeys: state.stickyMode)
            _keyRows[index].set(model: rowModel)
        }
        
        // Unstick any stuck notes, but without calling the delegate.
        self.state.stuckKeys = []
        stopPlayingAllNotes()

        for (i, octave) in state.octaves.reversed().enumerated() {
            reconfigureKeyRow(index: i, octave: octave)
        }
        for row in _keyRows {
            row.keyDelegate = self
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
    
    /// Action which shows the settings modal.
    @objc func didPressSettings() {
        didPressClear()
        
        let settingsVC = SettingsViewController(style: .grouped)
        settingsVC.set(state: state)

        settingsVC.appStateDidChange = { [weak self] state in
            guard let self = self else { return }
            self.set(state: state)
            self.dismissSettings()
            if state.interface != .gridNotes {
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
        _reconfigureKeyRows(state: state)
    }
}

extension GridChordsKeyboardViewController: KeyDelegate {
    
    func keyDidGetPressed(absoluteNote: AbsoluteNote) {
        startPlaying(absoluteNote: absoluteNote)
        if state.stickyMode {
            state.stuckKeys.insert(absoluteNote)
        }
        _reconfigureToolbar(state: state)
    }
    
    func keyDidGetReleased(absoluteNote: AbsoluteNote) {
        stopPlaying(absoluteNote: absoluteNote)
        if state.stickyMode {
            state.stuckKeys.remove(absoluteNote)
        }
        _reconfigureToolbar(state: state)
    }
}

