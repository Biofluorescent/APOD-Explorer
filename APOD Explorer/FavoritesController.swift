//
//  FavoritesController.swift
//  APOD Explorer
//
//  Created by Tanner Quesenberry on 9/7/20.
//  Copyright © 2020 Tanner Quesenberry. All rights reserved.
//

import UIKit
import CoreData

//MARK: Table View Cell
class AstronomyTableViewCell: UITableViewCell {
    
    @IBOutlet weak var astronomyImageView: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var astronomyObject: Astronomy!
}

//MARK: Table View Controller
class FavoritesController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var fetchController: NSFetchedResultsController<Astronomy>!
    let months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]


    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //Get the managed context to retrieve from
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Astronomy> = Astronomy.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        
        fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchController.delegate = self
        
        do {
            try fetchController.performFetch()
        }catch {
            fatalError("Failed to fetch entities: \(error)")
        }
        
    }
    
    //MARK: NSFetchedResultsControllerDelegate Methods
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
     
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        }
    }
     
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
     
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if let frc = fetchController {
            return frc.sections!.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = self.fetchController?.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Favorite", for: indexPath) as! AstronomyTableViewCell

        guard let star = self.fetchController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        
        let dates = star.date.components(separatedBy: "-")
        if let month = Int(dates[1]) {
            cell.dateLabel?.text = "\(months[month - 1]) \(dates[2]), \(dates[0])"
        }
        
        //cell.dateLabel?.text = star.date
        cell.titleLabel?.text = star.title
        cell.astronomyObject = star
        
        //Load image or placeholder for videos
        if let image = loadImageFromDocumentDirectory(nameOfImage: star.date + ".png") {
            cell.astronomyImageView.image = image
        }else {
            cell.astronomyImageView.image = UIImage(named: "video")
        }
        
        //Shrink text if title too big for label
        cell.dateLabel.adjustsFontSizeToFitWidth = true
        cell.dateLabel.minimumScaleFactor = 0.5
        cell.titleLabel.adjustsFontSizeToFitWidth = true
        cell.titleLabel.minimumScaleFactor = 0.5
        cell.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        return cell
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //Get container
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let managedContext = appDelegate.persistentContainer.viewContext
            
            //Get object to delete from table view and delete it
            let astronomy = fetchController.object(at: indexPath)
            managedContext.delete(astronomy)

            //Save the changes
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Check segue
        if segue.identifier == "PresentFavorite" {
            // Get the new view controller using segue.destination.
            let destinationVC = segue.destination as! PresentationViewController
            //Get info for selected row
            if let indexPath = tableView.indexPathForSelectedRow {
                guard let star = self.fetchController?.object(at: indexPath) else {
                    fatalError("Unable to get managed object")
                }
                //Pass cell data
                destinationVC.data = star
            }
        }
    }
    
    //MARK: Loading images
    func loadImageFromDocumentDirectory(nameOfImage : String) -> UIImage? {
        let documentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let userDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(documentDirectory, userDomainMask, true)
        if let dirPath = paths.first{
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(nameOfImage)
            let image = UIImage(contentsOfFile: imageURL.path)
            return image
        }
        return nil
    }

}
