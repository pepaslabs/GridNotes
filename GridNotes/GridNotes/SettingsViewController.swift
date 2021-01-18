//
//  SettingsViewController.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/10/21.
//

import UIKit


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
    
    private let _tonicSection: Int = 0
    private let _scaleSection: Int = 1
    private let _nonDiatonicSection: Int = 2
    private let _octaveKeysSection: Int = 3
    private let _stickySection: Int = 4
    private let _instrumentSection: Int = 5
    private let _interfaceSection: Int = 6

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = UIColor.white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    // MARK: - UITableViewDelegate / UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case _tonicSection:
            return "Tonic Note"
        case _scaleSection:
            return "Scale"
        case _nonDiatonicSection:
            return "Non-Diatonic (Out-of-Scale) Note Treatment"
        case _octaveKeysSection:
            return "Keys per Octave"
        case _stickySection:
            return "Sticky Keys"
        case _instrumentSection:
            return "Instrument (Fluid R3 SoundFont)"
        case _interfaceSection:
            return "Interface"
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case _tonicSection:
            return Note.allCases.count
        case _scaleSection:
            return Scale.allCases.count
        case _nonDiatonicSection:
            return NonDiatonicKeyStyle.allCases.count
        case _octaveKeysSection:
            return KeysPerOctave.allCases.count
        case _stickySection:
            return 2
        case _instrumentSection:
            return Instrument.allCases.count
        case _interfaceSection:
            return Interface.allCases.count
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        switch indexPath.section {
        case _tonicSection, _scaleSection, _nonDiatonicSection, _octaveKeysSection, _stickySection,
             _instrumentSection, _interfaceSection:
            _style(cell: cell, indexPath: indexPath)
        default:
            fatalError()
        }
        cell.separatorInset = UIEdgeInsets(top: 0, left: 32, bottom: 0, right: 0)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case _tonicSection:
            state.tonicNote = Note.allCases[indexPath.row]
        case _scaleSection:
            state.scale = Scale.allCases[indexPath.row]
        case _nonDiatonicSection:
            state.nonScaleStyle = NonDiatonicKeyStyle.allCases[indexPath.row]
        case _octaveKeysSection:
            state.keysPerOctave = KeysPerOctave.allCases[indexPath.row]
        case _stickySection:
            state.stickyKeys = (indexPath.row == 0)
        case _instrumentSection:
            deinitAudio()
            g_instrument = Instrument.allCases[indexPath.row]
            initAudio()
        case _interfaceSection:
            state.interface = Interface.allCases[indexPath.row]
        default:
            fatalError()
        }

        _restyleVisibleCells()
        for iterated in tableView.indexPathsForSelectedRows ?? [] {
            tableView.deselectRow(at: iterated, animated: true)
        }
        appStateDidChange?(state)
    }
    
    private func _style(cell: UITableViewCell, indexPath: IndexPath) {
        let isSelected: Bool
        switch indexPath.section {

        case _tonicSection:
            let note = Note.allCases[indexPath.row]
            isSelected = state.tonicNote == note
            cell.textLabel?.text = note.name

        case _scaleSection:
            let scale = Scale.allCases[indexPath.row]
            isSelected = state.scale == scale
            cell.textLabel?.text = scale.name

        case _nonDiatonicSection:
            let style = NonDiatonicKeyStyle.allCases[indexPath.row]
            isSelected = state.nonScaleStyle == style
            cell.textLabel?.text = style.name

        case _octaveKeysSection:
            let keyCount = KeysPerOctave.allCases[indexPath.row]
            isSelected = state.keysPerOctave == keyCount
            cell.textLabel?.text = keyCount.name
            
        case _stickySection:
            isSelected = (state.stickyKeys && indexPath.row == 0) || (!state.stickyKeys && indexPath.row == 1)
            cell.textLabel?.text = (indexPath.row == 0) ? "Enabled" : "Disabled"
            
        case _instrumentSection:
            isSelected = g_instrument == Instrument.allCases[indexPath.row]
            cell.textLabel?.text = Instrument.allCases[indexPath.row].displayName
        
        case _interfaceSection:
            let interface = Interface.allCases[indexPath.row]
            isSelected = state.interface == interface
            cell.textLabel?.text = interface.name
            
        default:
            fatalError()
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
            guard let cell = tableView.cellForRow(at: indexPath) else { continue }
            switch indexPath.section {
            case _tonicSection, _scaleSection, _nonDiatonicSection, _octaveKeysSection, _stickySection,
                 _instrumentSection, _interfaceSection:
                _style(cell: cell, indexPath: indexPath)
            default:
                fatalError()
            }
        }
    }
    
    // MARK: -
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
