//
//  SettingsViewController.swift
//  GridNotes
//
//  Created by Jason Pepas on 1/10/21.
//

import UIKit


class SettingsViewController: UITableViewController {

    var model: GridKeyboardViewController.Model = GridKeyboardViewController.Model.defaultModel
    
    func set(model: GridKeyboardViewController.Model) {
        self.model = model
        if isViewLoaded {
            tableView.reloadData()
        }
    }

    var modelDidChange: ((GridKeyboardViewController.Model) -> ())? = nil
    
    // MARK: - Internals
    
    private let _tonicSection: Int = 0
    private let _scaleSection: Int = 1
    private let _nonDiatonicSection: Int = 2
    private let _octaveKeysSection: Int = 3

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = UIColor.white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    // MARK: - UITableViewDelegate / UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case _tonicSection:
            return "Tonic Note"
        case _scaleSection:
            return "Scale"
        case _nonDiatonicSection:
            return "Non-Diatonic Note Treatment"
        case _octaveKeysSection:
            return "Keys per Octave"
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
            return GridKeyboardViewController.NonDiatonicKeyStyle.allCases.count
        case _octaveKeysSection:
            return GridKeyboardViewController.KeysPerOctave.allCases.count
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        switch indexPath.section {
        case _tonicSection, _scaleSection, _nonDiatonicSection, _octaveKeysSection:
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
            model.tonicNote = Note.allCases[indexPath.row]
        case _scaleSection:
            model.scale = Scale.allCases[indexPath.row]
        case _nonDiatonicSection:
            model.nonScaleStyle = GridKeyboardViewController.NonDiatonicKeyStyle.allCases[indexPath.row]
        case _octaveKeysSection:
            model.keysPerOctave = GridKeyboardViewController.KeysPerOctave.allCases[indexPath.row]
        default:
            fatalError()
        }

        _restyleVisibleCells()
        for iterated in tableView.indexPathsForSelectedRows ?? [] {
            tableView.deselectRow(at: iterated, animated: true)
        }
        modelDidChange?(model)
    }
    
    private func _style(cell: UITableViewCell, indexPath: IndexPath) {
        let isSelected: Bool
        switch indexPath.section {

        case _tonicSection:
            let note = Note.allCases[indexPath.row]
            isSelected = model.tonicNote == note
            cell.textLabel?.text = note.name

        case _scaleSection:
            let scale = Scale.allCases[indexPath.row]
            isSelected = model.scale == scale
            cell.textLabel?.text = scale.name

        case _nonDiatonicSection:
            let style = GridKeyboardViewController.NonDiatonicKeyStyle.allCases[indexPath.row]
            isSelected = model.nonScaleStyle == style
            cell.textLabel?.text = style.name

        case _octaveKeysSection:
            let keyCount = GridKeyboardViewController.KeysPerOctave.allCases[indexPath.row]
            isSelected = model.keysPerOctave == keyCount
            cell.textLabel?.text = keyCount.name
            
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
            case _tonicSection, _scaleSection, _nonDiatonicSection, _octaveKeysSection:
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
