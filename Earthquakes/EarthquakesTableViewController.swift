/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The code in this file loads the data store, updates the model, and displays data in the UI.
*/

import UIKit
import CoreData
import CloudKit

class EarthquakesTableViewController: UITableViewController {
    // MARK: Properties

    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?

    let operationQueue = EarthquakeOperationQueue()

    // MARK: View Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        let operation = LoadModelOperation { context in
            // Now that we have a context, build our `FetchedResultsController`.
            DispatchQueue.main.async {
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: Earthquake.entityName)

                request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]

                request.fetchLimit = 100

                let controller = NSFetchedResultsController<NSFetchRequestResult>(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)

                self.fetchedResultsController = controller

                self.updateUI()
            }
        }

        operationQueue.addOperation(operation)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController?.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = fetchedResultsController?.sections?[section]

        return section?.numberOfObjects ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "earthquakeCell", for: indexPath as IndexPath) as! EarthquakeTableViewCell

        if let earthquake = fetchedResultsController?.object(at: indexPath) as? Earthquake {
            cell.configure(earthquake: earthquake)
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /*
            Instead of performing the segue directly, we can wrap it in a
            `EarthquakeBlockOperation`. This allows us to attach conditions to the
            operation. For example, you could make it so that you could only perform
            the segue if the network is reachable and you have access to the user's
            Photos library.

            If you decide to use this pattern in your apps, choose conditions that
            are sensible and do not place onerous requirements on the user.

            It's also worth noting that the Observer attached to the
            `EarthquakeBlockOperation` will cause the tableview row to be deselected
            automatically if the `EarthquakeOperation` fails.

            You may choose to add your own observer to introspect the errors reported
            as the operation finishes. Doing so would allow you to present a message
            to the user about why you were unable to perform the requested action.
        */

        let operation = EarthquakeBlockOperation {
            self.performSegue(withIdentifier: "showEarthquake", sender: nil)
        }

        operation.addCondition(condition: MutuallyExclusive<UIViewController>())

        let blockObserver = BlockObserver(finishHandler:  { _, errors in
            /*
             If the operation errored (ex: a condition failed) then the segue
             isn't going to happen. We shouldn't leave the row selected.
             */
            if !errors.isEmpty {
                DispatchQueue.main.async {
                    tableView.deselectRow(at: indexPath as IndexPath, animated: true)
                }
            }
        })

        operation.addObserver(observer: blockObserver)

        operationQueue.addOperation(operation)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let navigationVC = segue.destination as? UINavigationController,
              let detailVC = navigationVC.viewControllers.first as? EarthquakeTableViewController else {
            return
        }
        detailVC.queue = operationQueue

        if let indexPath = tableView.indexPathForSelectedRow {
            detailVC.earthquake = fetchedResultsController?.object(at: indexPath) as? Earthquake
        }
    }

    @IBAction func startRefreshing(sender: UIRefreshControl) {
        getEarthquakes()
    }

    private func getEarthquakes(userInitiated: Bool = true) {
        if let context = fetchedResultsController?.managedObjectContext {
            let getEarthquakesOperation = GetEarthquakesOperation(context: context) {
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                    self.updateUI()
                }
            }

            getEarthquakesOperation.userInitiated = userInitiated
            operationQueue.addOperation(getEarthquakesOperation)
        }
        else {
            /*
                We don't have a context to operate on, so wait a bit and just make
                the refresh control end.
            */
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(300)) {
                self.refreshControl?.endRefreshing()
            }
        }
    }

    private func updateUI() {
        do {
            try fetchedResultsController?.performFetch()
        }
        catch {
            print("Error in the fetched results controller: \(error).")
        }

        tableView.reloadData()
    }

}
