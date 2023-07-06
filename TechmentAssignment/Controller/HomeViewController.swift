//
//  HomeViewController.swift
//  TechmentAssignment
//
//  Created by NayomeDevapriyaAnga on 03/07/23.
//  Copyright © 2023 NayomeDevapriyaAnga. All rights reserved.
//

import UIKit
import CoreData

class HomeViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    private var homeViewModel: HomeViewModel! //reference to the view model
    private var items: [ItemDetail] = []
    
    lazy var fetchedhResultController: NSFetchedResultsController<NSFetchRequestResult> = {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Languages.self))
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "itemId", ascending: true)]
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.sharedInstance.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        frc.delegate = self
        return frc
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    func callAPIToUpdateUI(withSearchText: String) {
        self.homeViewModel = HomeViewModel(searchString: withSearchText)
        self.homeViewModel.bindProgViewModelToController = {
            self.updateDataSource(withText: withSearchText)
        }
    }
    
    func updateDataSource(withText: String) {
        if let itemList = self.homeViewModel.apiData {
            self.items = itemList

            self.saveInCoreDataWith(array: self.items)
            do {
                self.fetchedhResultController.fetchRequest.predicate = NSPredicate(format: "language = %@", withText.lowercased())


                try self.fetchedhResultController.performFetch()
                print("COUNT FETCHED FIRST: \(String(describing: self.fetchedhResultController.sections?[0].numberOfObjects))")
            } catch let error  {
                print("ERROR: \(error)")
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppUtility.lockOrientation(.portrait)
        // Or to rotate and lock
        // AppUtility.lockOrientation(.portrait, andRotateTo: .portrait)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Don't forget to reset when view is being removed
        AppUtility.lockOrientation(.all)
    }
    
    private func createLanguageEntityFrom(receivedItem: ItemDetail) -> NSManagedObject? {
        let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
        if let languageEntity = NSEntityDescription.insertNewObject(forEntityName: "Languages", into: context) as? Languages {
            languageEntity.itemId = Int32(receivedItem.itemId)
            if let fullName = receivedItem.fullName {
                languageEntity.fullName = fullName
            }
            languageEntity.owner = receivedItem.owner.login
            languageEntity.langDescription = receivedItem.description
            languageEntity.language = receivedItem.language?.lowercased()
            return languageEntity
        }
        return nil
    }
    
    private func saveInCoreDataWith(array: [ItemDetail]) {
        _ = array.map{self.createLanguageEntityFrom(receivedItem: $0)}
        do {
            try CoreDataStack.sharedInstance.persistentContainer.viewContext.save()
        } catch let error {
            print(error)
        }
    }
    
    private func clearData() {
        do {
            
            let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: Languages.self))
            do {
                let objects  = try context.fetch(fetchRequest) as? [NSManagedObject]
                _ = objects.map{$0.map{context.delete($0)}}
                CoreDataStack.sharedInstance.saveContext()
            } catch let error {
                print("ERROR DELETING : \(error)")
            }
        }
    }
    
    
}


extension HomeViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchText = self.searchBar.text {
            print(searchText)
            callAPIToUpdateUI(withSearchText: searchText)
        }
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let count = fetchedhResultController.sections?.first?.numberOfObjects {
            return count
        }
        return 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomTableViewCell") as! CustomTableViewCell
        
        let fetchData = fetchedhResultController.object(at: indexPath) as? Languages
        
        cell.fullNameLabel.text = fetchData?.fullName
        cell.ownerLabel.text = fetchData?.owner
        cell.descLabel.text = fetchData?.langDescription
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedData = fetchedhResultController.object(at: indexPath) as! Languages
        print("selected row is \(String(describing: selectedData))")
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "DetailVC") as! DetailViewController
        vc.cellVM = DetailsModel(id: Int(selectedData.itemId), full_name: selectedData.fullName ?? "", description: selectedData.langDescription, owner: selectedData.owner, language: self.searchBar.text)
        vc.delegate = self
        
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
}


extension HomeViewController: dataUpdatingDelegate {
    func onUpdate(updatedData: DetailsModel) {
        print(updatedData)
        if let selectedRow = tableView.indexPathForSelectedRow?.row {
            let  selectedData = fetchedhResultController.object(at: self.tableView.indexPathForSelectedRow!) as! Languages
            selectedData.langDescription = updatedData.description
            selectedData.fullName = updatedData.full_name
            selectedData.owner = updatedData.owner
            do {
                try CoreDataStack.sharedInstance.persistentContainer.viewContext.save()
            } catch let error {
                print(error)
            }
            
            let indexPath = IndexPath(row: selectedRow, section: 0);
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
        }
    }
}

extension HomeViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
        case .insert:
            self.tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            self.tableView.deleteRows(at: [indexPath!], with: .automatic)
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
}


