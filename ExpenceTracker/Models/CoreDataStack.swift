//
//  CoreDataStack.swift
//  ExpenseTracker
//
//  Created by Developer on 21/06/2025.
//

import CoreData
import Foundation

// MARK: - Core Data Stack
class CoreDataStack {
    static let shared = CoreDataStack()
    
    private init() {}
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ExpenseTracker")
        
        // Настройки для производительности
        let description = container.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = true
        description?.shouldMigrateStoreAutomatically = true
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ CoreData Error: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("✅ CoreData: Store loaded successfully")
            }
        }
        
        // Настройки контекста
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    // MARK: - Contexts
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
    
    // MARK: - Save Context
    func save() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ CoreData: Context saved successfully")
            } catch {
                print("❌ CoreData Save Error: \(error)")
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func saveInBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let backgroundContext = self.backgroundContext
        
        backgroundContext.perform {
            block(backgroundContext)
            
            if backgroundContext.hasChanges {
                do {
                    try backgroundContext.save()
                    print("✅ CoreData: Background context saved")
                    
                    // Уведомляем main context об изменениях
                    DispatchQueue.main.async {
                        self.viewContext.refreshAllObjects()
                    }
                } catch {
                    print("❌ CoreData Background Save Error: \(error)")
                }
            }
        }
    }
    
    // MARK: - Batch Operations
    func batchDelete<T: NSManagedObject>(fetchRequest: NSFetchRequest<T>) throws {
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest as! NSFetchRequest<NSFetchRequestResult>)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try viewContext.execute(deleteRequest) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID]
        let changes = [NSDeletedObjectsKey: objectIDArray ?? []]
        
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
    }
    
    // MARK: - Development Helpers
    #if DEBUG
    func deleteAllData() {
        let entities = persistentContainer.managedObjectModel.entities
        
        for entity in entities {
            if let entityName = entity.name {
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try viewContext.execute(deleteRequest)
                    print("🗑️ Deleted all \(entityName) objects")
                } catch {
                    print("❌ Failed to delete \(entityName): \(error)")
                }
            }
        }
        
        save()
    }
    
    func printDatabaseStats() {
        let categoryRequest: NSFetchRequest<Category> = Category.fetchRequest()
        let expenseRequest: NSFetchRequest<Expense> = Expense.fetchRequest()
        
        do {
            let categoryCount = try viewContext.count(for: categoryRequest)
            let expenseCount = try viewContext.count(for: expenseRequest)
            
            print("📊 Database Stats:")
            print("   Categories: \(categoryCount)")
            print("   Expenses: \(expenseCount)")
        } catch {
            print("❌ Failed to get database stats: \(error)")
        }
    }
    #endif
}
