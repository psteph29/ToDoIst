//
//  ItemManager.swift
//  ToDoist
//
//  Created by Parker Rushton on 10/21/22.
//

import Foundation
import CoreData

class ItemManager {
    static let shared = ItemManager()
    
    var allItems = [Item]()
    var items: [Item] {
        allItems.filter { $0.completedAt == nil }.sorted(by: { $0.sortDate >  $1.sortDate })
    }
    var completedItems: [Item] {
        allItems.filter { $0.completedAt != nil }.sorted(by: { $0.sortDate >  $1.sortDate })
    }
    
    
    // Funcs
    
    func createNewItem(with title: String) {
        let newItem = Item(context: PersistenceController.shared.viewContext)
        newItem.id = UUID().uuidString
        newItem.title = title
        newItem.createdAt = Date()
        
        //this is creating a new item in the viewContext and adds the properties, but they're just sitting there on the context. The context is like your working scratch pad, and you need to take those things on the scratch pad and save them. The line below does just that.
        
        PersistenceController.shared.saveContext()
        allItems.append(newItem)
    }

//    func toggleItemCompletion(_ item: Item) {
//        var updatedItem = item
//        updatedItem.completedAt = item.isCompleted ? nil : Date()
//        if let index = allItems.firstIndex(of: item) {
//            allItems.remove(at: index)
//        }
//        allItems.append(updatedItem)
//    }
    
    func toggleItemCompletion(_ item: Item) {
       item.completedAt = item.isCompleted ? nil : Date()
       PersistenceController.shared.saveContext()
     }
    
    func delete(at indexPath: IndexPath) {
        remove(item(at: indexPath))
    }
    
    func remove(_ item: Item) {
        let context = PersistenceController.shared.viewContext
        context.delete(item)
        PersistenceController.shared.saveContext()
    }
    
//    func remove(_ item: Item) {
//        guard let index = allItems.firstIndex(of: item) else { return }
//        allItems.remove(at: index)
//    }
//
    private func item(at indexPath: IndexPath) -> Item {
        let items = indexPath.section == 0 ? items : completedItems
        return items[indexPath.row]
    }
    
    
    
    func fetchIncompleteItems() -> [Item] {
        // Create the fetch request
        let fetchRequest = Item.fetchRequest()
        // Add the predicate/filter for incomplete items
        fetchRequest.predicate = NSPredicate(format: "completedAt == nil")
        // Create a sort descriptor for sorting by the createdAt property in descending order
        let sortDescriptor = NSSortDescriptor(key: "createdAt", ascending: false)
        // Add the sort descriptor to the fetch request
        fetchRequest.sortDescriptors = [sortDescriptor]
        let context = PersistenceController.shared.viewContext
        // Execute the fetch request on a context (view context)
        let fetchedItems = try? context.fetch(fetchRequest)
        // If the fetch request fails, return an empty array of Items
        return fetchedItems ?? []
    }
    
    func fetchCompletedItems() -> [Item] {
        // Create the fetch request
        let fetchRequest = Item.fetchRequest()
        // Add the predicate/filter for completed items
        fetchRequest.predicate = NSPredicate(format: "completedAt != nil")
        // Create a sort descriptor for sorting by the completedAt property in descending order
        let sortDescriptor = NSSortDescriptor(key: "completedAt", ascending: false)
        // Add the sort descriptor to the fetch request
        fetchRequest.sortDescriptors = [sortDescriptor]
        let context = PersistenceController.shared.viewContext
        // Execute the fetch request on a context (view context)
        let fetchedItems = try? context.fetch(fetchRequest)
        // If the fetch request fails, return an empty array of Items
        return fetchedItems ?? []
    }
}
