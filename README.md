# CoreDataToDoist (Lab)
# Part 1
## Intro
- If you look at the `main` branch you'll see a lot of code already. In fact, this is a functioning to-do app already! 
- But we can do better than functional!
- For starters, this app doesn't save the user's to-do items accross launches. How useful is that?
- For this lab, you will be helping the user persist their data accross launches using (you guessed it) CORE DATA
- Before we dive into Core Data though, familiarize yourself with the project. 

## Get to know the project
  - 🔨🏃‍♂️ Build and Run
  - Type some to-do items
  - check any number of them off as completed
  - Check out the code!
    - Focus on the data flow
    - Where do the Items live?-
    - How do you create a new Item?
    - Check out the Diffable DataSource
        - Refamiliarize yourself [here](https://wwdcbysundell.com/2019/diffable-data-sources-first-look/) or [here](https://developer.apple.com/wwdc19/220) if you have no idea what this is
    - Especially look at the `ItemManager` That's where we'll do a lot of our work
      - Right now its simple because all the data is stored in a local array of `[Item]`
      - But pretty soon it will be on the AFTER side of a Before and After Core Data facelift!
  
## Add Core Data Model
- Lets do some modeling. . . Lets start with `Blue Steel` and then move on to `Magnum` jk 😜
- There's already a model file in the project but no entities to be found
- Add a new entity called `Item`
  - Make it match the `Item` found in `Item.swift`
    - id: String
    - title: String
    - createdAt: Date
    - completedAt: Date
  - Set the code generation to `Class Definition`
- 🔨🏃‍♂️ Build and run
- You'll notice some compile errors. What's going on?
  - Remember what `Class Definition` does? It creates a secret class definition of `Item` and now there are two objects called `Item` and the compiler is not happy!
- Go over to `Item.swift`  and lets make some changes:
  - Delete the struct definition, and the 4 properties and replace it with this line:
  ```
  extension Item { 
  ```
  - Delete all the other code that says  `// Remove for Core Data`
  - You'll notice you still can't build and run. A Core Data subclass is a lot different than a swift struct. We'll need to jump through the `Core Data` hoops to get this app working again. 
  - Onward!
  
## Add the Stack
- To access the guts of Core Data you have to have an `NSPersistentContainer` and an `NSPersistentStoreCoordinator` and a handfu of other long names that start with `NS`
  - And remember we DON'T expect a 10 page essay on the inner workings of the Core Data Stack (only 7 pages 😏 jk)
  - We just expect you to know that there's a core data stack that gives you access to the ManagedObjectContext which is where all your work will happen. 
- Go check out the projects `AppDelegate.swift`
- You'll find a bunch of code at the bottom of the file under the `// MARK: - Core Data stack`
- That is a full Core Data Stack Apple provides as part of your project. That's one of the things you get when you check the `Core Data` box when the project is created
- Create the Stack
  - Ceate a new swift file called `PersistenceController` 
  - Create a class with the same name
  - `import CoreData`
  - Add a shared instance (`static let shared = PersistenceController()`)
  - Copy all the code in the `AppDelegate` under the `MARK: - Core Data Stack`
  - paste it into the `Persistence` class
  - (make sure to not take too many `{` and `}` with you)
- Get access to the context:
  - Now lets write a computed property to be able to access the context directly
  - Add this above the `persistenceContainer`
  ```
  var viewContext: NSManagedObjectContext {
    return persistentContainer.viewContext
  }
  ```
  - When we need the use the viewContext, we'll use `PersistenceController.shared.viewContext`
  - Let's put that context to use. We'll use the context in creating, retreiving, updating, and deleting to do items
  
## Crud (Create)
- Go to the `ItemManager` and check out the `createNewItem()` function
- It use to just initialize an Item, and append it to the array of items. 
- But you can't just initialize a subclass of `NSManagedObject` like you would a swift struct. You have to use a designated initializer.
- Remove everything after the equals on this line:  `let newItem = Item(title: title)`, and then retype `Item(` to see the autocomplete suggestions
- Use the one that takes a `context`
- So the line will look like this: 
```
let newItem = Item(context: PersistenceController.shared.viewContext)
```
This creates a new item, but doesn't fill in all of its properties. Let's do that next. 
```
newItem.id = UUID().uuidString
newItem.title = title
newItem.createdAt = Date()
newItem.completedAt = nil
```
- So we've created the item in the viewContext, and added the properties but they're just sitting there on the context. Remember the context is like your working scratch pad. We need to take the things on the scratch pad and save them. 
`PersistenceController.shared.saveContext()`
- That's it! We're creating new items and storing them in core data  
- If you build and run, you will be adding items into Core Data, but your list of items is still based on the local array of item, so they won't show up
- Lets do that next
  
## cRud (Retrieve)
- So how do you get data out of core data?
- A: Fetch Requests
- A Fetch Request is a request for a specific subset of Core Data entities. 
- Lets write a Fetch Request for all the incomplete Items stored in Core Data
- First, let's import CoreData in the `ItemManager`
- Now lets add a function that will fetch all the incomplete Items
  - First you create the fetch request
  - Then specify the filter (or predicate) of which specific entities you want
    - NSPredicate could be a whole day in itself! 
    - We won't cover it right now but you could check out [this article](https://nshipster.com/nspredicate/) which is an oldie but a goodie
  - Then you execute the fetch request on a `NSManagedObjectContext` (we'll use the viewContext)
- Here's what it should look like in the end: 
```
func fetchIncompleteItems() -> [Item] {
    // Create the fetch request
    let fetchRequest = Item.fetchRequest()
    // Add the predicate for either incomplete or complete
    fetchRequest.predicate = NSPredicate(format: "completedAt == nil")
    let context = PersistenceController.shared.viewContext
    // Execute the fetch request on a context (view context)
    let fetchedItems = try? context.fetch(fetchRequest)
    // If the fetch request fails, return an empty array of Items
    return fetchedItems ?? []
}

```

- Now lets head over to the `ItemsViewController` and fix the errors
- Luckily the errors are only in one function `generateNewSnapshot()`
- `generateNewSnapshot()` is the function responsible for finding the right items, and populating the tableview's datasource with the right data. 
- Instead of populating the `Item`s from the array of items (that we deleted) we're going to use the new `fetchItems(completed:)` function we just wrote
- Lets create a variable called `incompleteItems` and set it to the return value of `fetchItems(completed: false)`
- Then do the same but for `completedItems`
- Then if they are not empty we'll add them to the snapshot section like we did before. 
- It should look like this: 
```
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
```
- 🔨🏃‍♂️ Build and run! (You will need to comment out the code in `ItemManager.toggleItemCompleted(item:)` and `ItemManager.remove(item:)`)
- Assuming you did everything correctly, and if you added any items earlier before they were showing up, they should show up now! They were saved in Core Data and persist accross launches now! 
- What if we want the newest item to show up at the top?
- Queue: Sort Descriptors

### Sorting
- Fetch Requests can have a sort descriptor to indicate which order the data should come back in
- Sort descriptors look like this: 
- `NSSortDescriptor(key: "createdAt", ascending: false)`
- Basically you give it a key of the property you want the items to be sorted on, and if they should be ordered ascending (1->10) or descrending (10->1)
- You add them to the fetch request like this:
- `fetchRequest.sortDescriptors = [sortDescriptor]`
- Make sure to add it the `fetchCompletedItems` function as well (but with `completedAt`)
- And voila, sorted by the right date

## crUd (Update)
- You'll notice the button to mark an item as completed does not work. That's because we commented out the code.
- Let's refactor it for Core Data
- Updating is easy, just make a change to the entity, and save the context.
- Should look like this:
  ```
    func toggleItemCompletion(_ item: Item) {
      item.completedAt = item.isCompleted ? nil : Date()
      PersistenceController.shared.saveContext()
    }

  ```

## cruD (Delete)
- Lets buy the last letter to solve the puzzle
- Deletion is simple as well. 
- Just get the context, and call `.delete()` on it
- Should look like this: 
  ```
      func remove(_ item: Item) {
        let context = PersistenceController.shared.viewContext
        context.delete(item)
        PersistenceController.shared.saveContext()
    }
  ```

## End Part 1

# Part 2 - Multiple Lists
- Wouldn't it be cool if we had not just one list but as many as the user wanted to make??
Lets build it!
- Part 2 there won't be as much hand holding. You'll need to infer more based on the instructions and look some stuff up

## Model
- The first change will be with the model. Instead of just one Entity of `Item` we'll need a new entity to represent a list that will have a relationship with its Items 😘. A realy steamy relationship 😏
- Go to model and add a new entity and lets call it `ToDoList`
  - Give the new entity a couple of its very own properties:
    - `id: String`
    - `title: String`
    - `createdAt: Date`
    - `modifiedAt: Date`
  - Now create a relationship with `Item`. We've done this a few times already so make sure to give it all the love it deserves
  - Add a new Swift file called `ToDoList`
  - Create an extension of the Core Data entity you just made `extension ToDoList {`
  - Create a property (`itemsArray`) that converts the `items` from its native type (`NSSet`) to a swift Array
  
## UI
- Lets build the UI
- Go to the storyboard and add a new view controller for the list of lists 😏. (The table that shows all your `ToDoList` entities)
- Embed it in a NavigationController
- (Make sure the `ItemsViewController` is not also in a navigation controller. 2 navigation controllers is a no-no)
- Make sure to implement the tableview Datasource (Doesn't have to be a Diffable one)
- Feel free to use a standard UITableViewCell. You don't need to do a custom cell here
- The cell should display the `title` of the `ToDoList` and the subtitle should show the count of items in that list
- Add a plus button to the trailing nav bar button
- It should display a UIAlertController that contains a UITextField for entering the title of the new list
- Give it a cancel and save button. The save button will call a new function to create a `ToDoList` that you will write, right now
  
## List CRUD
- You'll need all the same functions for creating, retrieving, updating, and deleting a `ToDoList` from Core Data. Add those now
  - Put them in the ItemController
  - They'll look very similar to the other crud functions we wrote for `Item`s
  - You won't need 2 different fetch requests for `ToDoList`s. Just the one sorted by `modifiedAt` that returns all the user's to-do lists
  
## Push it!
- When a user taps on a list we want to push on the `ItemsViewController` to show them the items of that list they seleted
- Set up a segue from the list cell to push on the `ItemsViewController` onto the stack
- Change `ItemsViewController` so that it can be initialized with a `ToDoList`
  - Check out [this article](https://cocoacasts.com/initializer-injection-with-view-controllers-storyboards-and-segues) for some help
- Set up your segue and connect it to the code file with an `@IBSegueAction` 
- In the SegueAction, initialize the `ItemsViewController` with the new initializer that accepts a `ToDoList`

## Update Items CRUD
### Create
- When we create an item, we need to associate it with the list to setup the relationship
- Inside `createNewItem` pass in a `ToDoList`
- Assign the `newItem.toDoList` to that list. Then the relationship is established (both ways)
### Retrieve
- We need to change how we fetch items now because there's a better way to do it. Through the relationship. 
- Now you actually don't even need a fetch request to get the items of a list. A `ToDoList` has an array of its `items` built in to the relationship
- That's the beauty of Core Data relationship, if you have the parent entity (`ToDoList`) you can just use the relationshipto get all of its child entities (`[Item]`)
- Should look like this: `toDoList.itemsArray`
- That gives you all the items, then filter them based on their completed status, and sort them by `sortDate`
- That's it! that's all the instructions for today. (we TOLD you it would be less hand holding)
### Updating
- Updating is the same
  
## Final thoughts/hints
- YOU CAN DO THIS! Don't give up
- Your FIRST source should be the working code you already have. 
- Your SECOND source should be Google (favor apple docs, stack overflow, hacking with swift, other blogs, etc.)
- Your THIRD source should be a neighbor to collaborate and brainstorm together
- Your FOURTH source should be the instructor
- Try not to look at the answer branch too early. There's learning in the struggle
- But also if you're struggling for more than ~17 minutes on the same thing, ask for help. Aint nobody got time for that! Class is only 3 hours
- There's a lot of power in a well-worded Google search
  - `iOS Swift how to add a Core Data relationship`
  - `iOS Swfit Core Data how to write a compound predicate`
  - `iOS swift initializer injection with storyboard segues`
  - etc.
  
# ToDoIst
