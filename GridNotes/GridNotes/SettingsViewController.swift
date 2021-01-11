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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        view.backgroundColor = UIColor.white
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    // MARK: - UITableViewDelegate / UITableViewDataSource
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Tonic Note"
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return Note.allCases.count
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            _style(cell: cell, indexPath: indexPath)
            return cell
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        model.tonicNote = Note.allCases[indexPath.row]
        _restyleVisibleCells()
        for iterated in tableView.indexPathsForSelectedRows ?? [] {
            tableView.deselectRow(at: iterated, animated: true)
        }
        modelDidChange?(model)
    }
    
    private func _style(cell: UITableViewCell, indexPath: IndexPath) {
        let note = Note.allCases[indexPath.row]
        let isSelected = model.tonicNote == note
        switch indexPath.section {
        case 0:
            cell.textLabel?.text = note.name
            if isSelected {
                cell.textLabel?.font = UIFont.boldSystemFont(ofSize: cell.textLabel!.font.pointSize)
                cell.accessoryType = .checkmark
            } else {
                cell.textLabel?.font = UIFont.systemFont(ofSize: cell.textLabel!.font.pointSize)
                cell.accessoryType = .none
            }
        default:
            fatalError()
        }
    }

    private func _restyleVisibleCells() {
        for path in tableView.indexPathsForVisibleRows ?? [] {
            if let cell = tableView.cellForRow(at: path) {
                _style(cell: cell, indexPath: path)
            }
        }
    }
    
    // MARK: -
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
