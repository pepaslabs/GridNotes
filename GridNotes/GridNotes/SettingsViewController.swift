//
//  SettingsViewController.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/10/21.
//

import UIKit


/// The settings modal.
class SettingsViewController: UITableViewController {

    private(set) var state: AppState = AppState.defaultState
    
    func set(state: AppState) {
        self.state = state
        if isViewLoaded {
            tableView.reloadData()
        }
    }

    var appStateDidChange: ((AppState) -> ())? = nil
    
    // MARK: - Internals
    
    enum Section: Int, CaseIterable {
        case tonic = 0
        case scale = 1
        case nonDiatonic = 2
        case octaveKeys = 3
        case sticky = 4
        case instrument = 5
        case interface = 6
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = ColorTheme.background
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    // MARK: - UITableViewDelegate / UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionCase = Section(rawValue: section) else { fatalError() }
        switch sectionCase {
        case .tonic:
            return "Tonic Note"
        case .scale:
            return "Scale"
        case .nonDiatonic:
            return "Non-Diatonic (Out-of-Scale) Note Treatment"
        case .octaveKeys:
            return "Keys per Octave"
        case .sticky:
            return "Sticky Keys"
        case .instrument:
            return "Instrument (Fluid R3 SoundFont)"
        case .interface:
            return "Interface"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionCase = Section(rawValue: section) else { fatalError() }
        switch sectionCase {
        case .tonic:
            return Note.allCases.count
        case .scale:
            return Scale.allCases.count
        case .nonDiatonic:
            return NonDiatonicKeyStyle.allCases.count
        case .octaveKeys:
            return KeysPerOctave.allCases.count
        case .sticky:
            return 2
        case .instrument:
            return Instrument.allCases.count
        case .interface:
            return Interface.allCases.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        precondition(Section(rawValue: indexPath.section) != nil)
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        _style(cell: cell, indexPath: indexPath)
        cell.separatorInset = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 0)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sectionCase = Section(rawValue: indexPath.section) else { fatalError() }
        switch sectionCase {
        case .tonic:
            state.tonicNote = Note.allCases[indexPath.row]
        case .scale:
            state.scale = Scale.allCases[indexPath.row]
        case .nonDiatonic:
            state.nonScaleStyle = NonDiatonicKeyStyle.allCases[indexPath.row]
        case .octaveKeys:
            state.keysPerOctave = KeysPerOctave.allCases[indexPath.row]
        case .sticky:
            state.stickyKeys = (indexPath.row == 0)
        case .instrument:
            deinitAudio()
            g_instrument = Instrument.allCases[indexPath.row]
            initAudio()
        case .interface:
            state.interface = Interface.allCases[indexPath.row]
        }

        _restyleVisibleCells()
        for iterated in tableView.indexPathsForSelectedRows ?? [] {
            tableView.deselectRow(at: iterated, animated: true)
        }
        appStateDidChange?(state)
    }
    
    private func _style(cell: UITableViewCell, indexPath: IndexPath) {
        guard let sectionCase = Section(rawValue: indexPath.section) else { fatalError() }
        let isSelected: Bool
        switch sectionCase {

        case .tonic:
            let note = Note.allCases[indexPath.row]
            isSelected = state.tonicNote == note
            cell.textLabel?.text = note.displayName

        case .scale:
            let scale = Scale.allCases[indexPath.row]
            isSelected = state.scale == scale
            cell.textLabel?.text = scale.displayName

        case .nonDiatonic:
            let style = NonDiatonicKeyStyle.allCases[indexPath.row]
            isSelected = state.nonScaleStyle == style
            cell.textLabel?.text = style.displayName

        case .octaveKeys:
            let keyCount = KeysPerOctave.allCases[indexPath.row]
            isSelected = state.keysPerOctave == keyCount
            cell.textLabel?.text = keyCount.displayName
            
        case .sticky:
            isSelected = (state.stickyKeys && indexPath.row == 0) || (!state.stickyKeys && indexPath.row == 1)
            cell.textLabel?.text = (indexPath.row == 0) ? "Enabled" : "Disabled"
            
        case .instrument:
            isSelected = g_instrument == Instrument.allCases[indexPath.row]
            cell.textLabel?.text = Instrument.allCases[indexPath.row].displayName
        
        case .interface:
            let interface = Interface.allCases[indexPath.row]
            isSelected = state.interface == interface
            cell.textLabel?.text = interface.displayName
        }

        if isSelected {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: cell.textLabel!.font.pointSize)
            cell.accessoryType = .checkmark
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: cell.textLabel!.font.pointSize)
            cell.accessoryType = .none
        }
    }

    private func _restyleVisibleCells() {
        for indexPath in tableView.indexPathsForVisibleRows ?? [] {
            precondition(Section(rawValue: indexPath.section) != nil)
            guard let cell = tableView.cellForRow(at: indexPath) else { continue }
            _style(cell: cell, indexPath: indexPath)
        }
    }
    
    // MARK: -
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
