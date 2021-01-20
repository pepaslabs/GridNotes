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
        if isViewLoaded {
            _apply(state: state)
        }
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
        view.backgroundColor = ColorTheme.background

        // Configure the ring view.
        _ringView.keyDelegate = self
        _ringView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(_ringView)
        // Pin to the screen edges.
        view.topAnchor.constraint(equalTo: _ringView.topAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: _ringView.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: _ringView.trailingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: _ringView.bottomAnchor).isActive = true

        // Configure the app label.
        let appNameLabel: UILabel = UILabel()
        appNameLabel.textColor = ColorTheme.label
        appNameLabel.text = "GridNotes \(Bundle.main.marketingVersion)"
        appNameLabel.font = UIFont.boldSystemFont(ofSize: appNameLabel.font.pointSize)
        appNameLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(appNameLabel)
        // Pin to upper left of screen.
        appNameLabel.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 1).isActive = true
        appNameLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 1).isActive = true

        // Configure the settings button.
        _settingsButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: _settingsButton.titleLabel!.font.pointSize)
        _settingsButton.addTarget(self, action: #selector(didPressSettings), for: .touchUpInside)
        _settingsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(_settingsButton)
        // Pin to upper right of screen.
        _settingsButton.topAnchor.constraint(equalToSystemSpacingBelow: view.topAnchor, multiplier: 1).isActive = true
        view.trailingAnchor.constraint(equalToSystemSpacingAfter: _settingsButton.trailingAnchor, multiplier: 1).isActive = true

        // Configure the clear button.
        _clearButton.setTitle("Clear", for: .normal)
        _clearButton.titleLabel!.font = UIFont.boldSystemFont(ofSize: _clearButton.titleLabel!.font.pointSize)
        _clearButton.addTarget(self, action: #selector(didPressClear), for: .touchUpInside)
        _clearButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(_clearButton)
        // Pin to lower left of screen.
        view.bottomAnchor.constraint(equalToSystemSpacingBelow: _clearButton.bottomAnchor, multiplier: 1).isActive = true
        _clearButton.leadingAnchor.constraint(equalToSystemSpacingAfter: view.leadingAnchor, multiplier: 1).isActive = true

        _apply(state: state)
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        // for some reason, a simple setNeedsDisplay() is not sufficient to fully account for a dark-mode change.
        didPressClear()
    }
    
    /// (Re)Configure the UI to reflect the application state.
    private func _apply(state: AppState) {
        _settingsButton.setTitle("\(state.tonicNote.displayName) \(state.scale.displayName)", for: .normal)
        _hideOrShowClearButton()

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

    private func _hideOrShowClearButton() {
        let shouldShowClearButton = state.stickyKeys && state.stuckKeys.count > 0
        _clearButton.isHidden = !shouldShowClearButton
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
    
    /// Action which clears all of the stuck keys.
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
        _hideOrShowClearButton()
    }
    
    func keyDidGetReleased(absoluteNote: AbsoluteNote) {
        stopPlaying(absoluteNote: absoluteNote)
        if state.stickyKeys {
            state.stuckKeys.remove(absoluteNote)
        }
        _hideOrShowClearButton()
    }
}
