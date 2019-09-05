//
//  ResturantTableViewController.swift
//  FiExample
//
//  Created by Michael Gray on 9/4/19.
//  Copyright © 2019 Michael Gray. All rights reserved.
//

import UIKit
import MapKit

class ResturantTableViewController: UITableViewController {

    var annotation: Annotation? {
        didSet {
            self.updateView()
        }
    }
    var restaurant: Restaurant? {
        self.annotation?.resturant
    }

    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var cuisine: UILabel!
    @IBOutlet weak var mapPreview: UIImageView!

    var inspections: [Inspection] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateView()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    func updateView() {

        name?.text = restaurant?.name

        address?.text = restaurant.flatMap {
            """
            \($0.address.building) \($0.address.street)
            \($0.borough.rawValue) \($0.address.zipcode)
            """
        }

        cuisine?.text = restaurant.flatMap { $0.cuisine.rawValue.capitalized
        }

        self.inspections = restaurant?.grades.sorted { (lhs, rhs) -> Bool in
            lhs.date.date > rhs.date.date
        } ?? []

        self.view.setNeedsLayout()
    }

    private func drawPin(point: CGPoint, annotation: MKAnnotation) {
        let annotationView = ResturantView(annotation: annotation, reuseIdentifier: "test")
        annotationView.contentMode = .scaleAspectFit
        annotationView.bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
        annotationView.drawHierarchy(in: CGRect(
            x: point.x - annotationView.bounds.size.width / 2.0,
            y: point.y - annotationView.bounds.size.height,
            width: annotationView.bounds.width,
            height: annotationView.bounds.height),
                                     afterScreenUpdates: true)
    }

    func drawMap() {
        guard let annotation = annotation else {
            return
        }

        let options = MKMapSnapshotter.Options()
        let region = MKCoordinateRegion(center: annotation.coordinate,
                                        latitudinalMeters: 100,
                                        longitudinalMeters: 100)
        options.region = region
        options.size = self.mapPreview.frame.size
        options.scale = UIScreen.main.scale

        let snapshotter = MKMapSnapshotter(options: options)
        snapshotter.start { [weak self] (snapshot, error) -> Void in
            guard let `self` = self,
                error == nil,
                let snapshot = snapshot else { return }

            UIGraphicsBeginImageContextWithOptions(snapshot.image.size, true, snapshot.image.scale)
            snapshot.image.draw(at: CGPoint.zero)

            let point: CGPoint = snapshot.point(for: annotation.coordinate)
            self.drawPin(point: point, annotation: annotation)
            let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
            self.mapPreview?.image = compositeImage
        }

    }

    override func viewDidLayoutSubviews() {
        self.drawMap()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return restaurant?.grades.count ?? 0
    }

    let dateFormatter: DateFormatter = {
        var formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .medium
        return formatter
    }()

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let restaurant = restaurant else {
            fatalError("resturant is unexpected nil value")
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "Grade", for: indexPath)

        let review = restaurant.grades[indexPath.row]
        cell.textLabel?.text = dateFormatter.string(from: review.date.date)
        let grade = review.grade.rawValue.capitalized
        let scoreString = review.score.flatMap {"\($0)" } ?? "??"
        cell.detailTextLabel?.text = "Grade:\(grade) Score:\(scoreString)"

        // Configure the cell...

        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
