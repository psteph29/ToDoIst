//
//  ViewController.swift
//  ToDoist
//
//  Created by Parker Rushton on 10/15/22.
//

import UIKit

class ItemsViewController: UIViewController {
    
    enum TableSection: Int {
        case incomplete, complete
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    
    // MARK: - Properties
    
    private let itemManager = ItemManager.shared
    private lazy var datasource: ItemDataSource = {
        let datasource = ItemDataSource(tableView: tableView) { tableView, indexPath, item in
            let cell = tableView.dequeueReusableCell(withIdentifier: ItemTableViewCell.reuseIdentifier) as! ItemTableViewCell
            cell.update(with: item)
            cell.delegate = self
            return cell
        }
        datasource.delegate = self
        return datasource
    }()

    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = datasource
        generateNewSnapshot()
    }

}


// MARK: - Item Cell Delegate

extension ItemsViewController: ItemCellDelegate {

    func completeButtonPressed(item: Item) {
        itemManager.toggleItemCompletion(item)
        generateNewSnapshot()
        tableView.reloadData()
    }
    
}


// MARK: - ItemDelegate

extension ItemsViewController: ItemDelegate {
    
    func deleteItem(at indexPath: IndexPath) {
        ItemManager.shared.delete(at: indexPath)
        generateNewSnapshot()
    }
    
}


// MARK: - TextField Delegate

extension ItemsViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text, !text.isEmpty else { return true }
        itemManager.createNewItem(with: text)
        textField.text = ""
        generateNewSnapshot()
        return true
    }
    
}


// MARK: - Private

private extension ItemsViewController {
    
    func generateNewSnapshot() {
        // Create a snapshot
        var snapshot = NSDiffableDataSourceSnapshot<TableSection, Item>()
        // Fetch incomplete and completed items from Core Data
        let incompleteItems = itemManager.fetchIncompleteItems()
        let completedItems = itemManager.fetchCompletedItems()
        
        // If there are incomplete items to show, add them to the tableview
        if !incompleteItems.isEmpty {
            snapshot.appendSections([.incomplete])
            snapshot.appendItems(incompleteItems, toSection: .incomplete)
        }
        // If there are completed items to show, add them to the tableview
        if !completedItems.isEmpty {
            snapshot.appendSections([.complete])
            snapshot.appendItems(completedItems, toSection: .complete)
        }
        // Apply the snapshot
        DispatchQueue.main.async {
            self.datasource.apply(snapshot)
        }
    }
    
}
