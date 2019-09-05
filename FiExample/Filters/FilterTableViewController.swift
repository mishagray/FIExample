//
//  FilterTableViewController.swift
//  FiExample
//
//  Created by Michael Gray on 9/2/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import UIKit
import Combine

extension FilterViewModel {

    func selectionSet(section: FilterTableViewController.Sections) -> SelectionSet {
        switch section {
        case .cuisines:
            return self.cuisines
        case .grades:
            return self.grades
        }
    }
}

class FilterTableViewController: UITableViewController {

    enum Sections: Int, CaseIterable {
        case grades = 0
        case cuisines = 1

        init(indexPath: IndexPath) {
            self.init(rawValue: indexPath.section)!
        }

        var sectionTitle: String {
            switch self {
            case .grades:
                return NSLocalizedString("Grades", comment: "grades")

            case .cuisines:
                return NSLocalizedString("Cuisines", comment: "cuisines")
            }
        }
    }

    var viewModel = FilterViewModel() {
        didSet {
            self.bindToModel()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.allowsMultipleSelection = true
        self.tableView.allowsMultipleSelectionDuringEditing = true

        self.bindToModel()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    var viewModelCancellable: AnyCancellable?
    func bindToModel() {

        self.tableView?.reloadData()
        // this will automatically discard the previous value of viewModelCancellable,
        // so subsequent calls to bindToModel() cancel the previous bindings.
        viewModelCancellable = viewModel.objectWillChange
            .subscribe(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.tableView?.reloadData()
            }

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Sections.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection sec: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows

        guard let section = Sections(rawValue: sec) else {
            fatalError("unexpected section value \(sec) received in \(#function)")
        }
        let selectionSet = self.viewModel.selectionSet(section: section)
        return selectionSet.allValues.count
   }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = Sections(indexPath: indexPath)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CheckableTableViewCell",
                                                       for: indexPath) as? CheckableTableViewCell else {
            fatalError("expecting CheckableTableViewCell for: \(indexPath) in \(#function)")
        }

        let selectionSet = self.viewModel.selectionSet(section: section)
        guard indexPath.row < selectionSet.allValues.count else {
            fatalError("out of range error \(indexPath) in \(#function)")
        }
        let value = selectionSet.allValues[indexPath.row]
        cell.textLabel?.text = value
        let selected = selectionSet.valueIsSelected(value: value)

        let isAlreadySelected =
            self.tableView.indexPathsForSelectedRows?.contains(indexPath) ?? false

        if selected && !isAlreadySelected {
            self.tableView.selectRow(at: indexPath,
                                     animated: false,
                                     scrollPosition: .none)
        }
        if !selected && isAlreadySelected {
            self.tableView.deselectRow(at: indexPath,
                                       animated: false)
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        let indexPath = IndexPath(row: 0, section: section)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "HeaderCell",
                                                       for: indexPath) as? HeaderTableViewCell else {
            fatalError("expecting HeaderTableViewCell for: \(indexPath) in \(#function)")
        }

        cell.allButton.tag = section
        cell.noneButton.tag = section

        cell.header.text = Sections(rawValue: section)?.sectionTitle

        return cell
    }

    @IBAction func allButtonSelected(_ sender: UIButton) {
        guard let section = Sections(rawValue: sender.tag) else {
            fatalError("no section found with button's tag \(sender.tag)")
        }
        let selectionSet = self.viewModel.selectionSet(section: section)
        selectionSet.selectAll()
    }
    @IBAction func noneButtonSelected(_ sender: UIButton) {
        guard let section = Sections(rawValue: sender.tag) else {
            fatalError("no section found with button's tag \(sender.tag)")
        }
        let selectionSet = self.viewModel.selectionSet(section: section)
        selectionSet.selectNone()
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Sections(rawValue: section)?.sectionTitle
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let section = Sections(rawValue: indexPath.section) else {
            fatalError("unexpected section value \(indexPath.section) received in \(#function)")
        }

        let selectionSet = self.viewModel.selectionSet(section: section)
        selectionSet.setSelected(index: indexPath.row, isSelected: true)
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let section = Sections(rawValue: indexPath.section) else {
            fatalError("unexpected section value \(indexPath.section) received in \(#function)")
        }

        let selectionSet = self.viewModel.selectionSet(section: section)
        selectionSet.setSelected(index: indexPath.row, isSelected: false)
    }

    /*
     
    // Override to support conditional editing of the table view.
    
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array,
            // and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
