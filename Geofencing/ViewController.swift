//
//  ViewController.swift
//  Geofencing For Noobs
//
//  Created by Hilton Pintor Bezerra Leite on 25/04/2018.
//  Copyright © 2018 Hilton Pintor Bezerra Leite. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController {
    
    let locationManager: CLLocationManager = {
        let manager =  CLLocationManager()
        
        return manager
    }()
    
    var monitoredRegions: [CLRegion] = [] {
        didSet {
            guard isViewLoaded, tableView != nil else { return }
            tableView.reloadData()
        }
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Managing locations to observe"
        
        locationManager.requestAlwaysAuthorization()
        
        // setup table view
        tableView.dataSource = self
        tableView.delegate = self
        updateVisibleData()
        
        // reload data
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(updateVisibleData))
        
        // add touch recognizer to map kit
        let longTapGesture = UILongPressGestureRecognizer(target: self, action: #selector(longpressGestureHandler))
        longTapGesture.minimumPressDuration = 1
        mapView.addGestureRecognizer(longTapGesture)
    }
    
    @objc private func longpressGestureHandler(_ gesture: UIGestureRecognizer) {
        if gesture.state == .began {
            let touchLocation = gesture.location(in: mapView)
            let locationCoordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            
            alertToAddNewPlace(coordinates: locationCoordinate)
        }
    }
    
    private func alertToAddNewPlace(coordinates: CLLocationCoordinate2D) {
        let alert = UIAlertController(title: "Add new place", message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: {
            $0.placeholder = "Enter place identifier"
        })
        
        alert.addAction(UIAlertAction.init(title: "Add", style: .default, handler: { [weak self] _ in
            guard let id = alert.textFields?.first?.text else { return }
            self?.addNewCoordinates(coordinates, id: id)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func addNewCoordinates(_ coordinates: CLLocationCoordinate2D, id: String) {
        let region = createRegionWithCoordinate(coordinates, id: id)
        
        region.notifyOnExit = true
        region.notifyOnEntry = true
        
        locationManager.startMonitoring(for: region)
        updateVisibleData()
    }
    
    private func createRegionWithCoordinate(_ coordinate: CLLocationCoordinate2D, id: String) -> CLCircularRegion {
        return CLCircularRegion(
            center: coordinate,
            radius: 25,
            identifier: id
        )
    }
    
    @objc private func updateVisibleData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.monitoredRegions = self.locationManager.monitoredRegions.map { $0 }
            self.updateAnnotations()
        }
    }
    
    private func updateAnnotations() {
        mapView.annotations.forEach { mapView.removeAnnotation($0) }
        
        for region in monitoredRegions {
            if let region = region as? CLCircularRegion {
                let annotation = MKPointAnnotation()
                annotation.coordinate = region.center
                annotation.title = region.identifier
                mapView.addAnnotation(annotation)
            }
        }
    }
    
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let region = monitoredRegions[indexPath.row] as? CLCircularRegion else { return }

        let mapRegion = MKCoordinateRegion(center: region.center, span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001))
        mapView.setRegion(mapRegion, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let action = UITableViewRowAction(style: .destructive, title: "Remove") { [weak self] (_, indexPath) in
            guard let weakSelf = self else { return }
            
            weakSelf.locationManager.stopMonitoring(for: weakSelf.monitoredRegions[indexPath.row])
            weakSelf.updateVisibleData()
        }
        
        return [action]
    }
    
}

extension ViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return monitoredRegions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let id = monitoredRegions[indexPath.row].identifier
        
        cell.textLabel?.text = "Place identifier \(id)"
        
        return cell
    }
    
    
}
