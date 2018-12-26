//
//  MapViewController.swift
//  LocaleRoutingMadeEasy
//
//  Created by Sudeepta Das on 12/25/18.
//  Copyright © 2018 Sudeepta Das. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    var strCategory: String!
    var localSearch : MKLocalSearch!
    var locationManager: CLLocationManager!
    var userCoordinate: CLLocationCoordinate2D!
    var coordinate: CLLocationCoordinate2D!
    let authorizationStatus = CLLocationManager.authorizationStatus()
    var places: [MKMapItem] = []
    var mapItemList: [MKMapItem] = []
    var boundingRegion : MKCoordinateRegion = MKCoordinateRegion()
    var currentPlacemark : CLPlacemark?
    @IBOutlet weak var mapView: MKMapView!
    
    var steps = [MKRoute.Step]()
    let speechSynthesizer = AVSpeechSynthesizer()
    var stepCounter = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = strCategory
        self.locationManager = CLLocationManager()
        self.mapView.delegate=self
        self.mapView.showsUserLocation=true
        self.mapView.showsScale=true
        self.mapView.showsTraffic=true
        self.mapView.showsCompass=true
        if(authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways) {
            locationManager.startUpdatingLocation()
        }
        else
        {
            locationManager.requestWhenInUseAuthorization()
        }
        var region = MKCoordinateRegion()
        region.span = MKCoordinateSpan(latitudeDelta: 0.7, longitudeDelta: 0.7); //Zoom distance
        let coordinate = CLLocationCoordinate2D(latitude: locationManager.location!.coordinate.latitude, longitude:  locationManager.location!.coordinate.longitude)
        region.center = coordinate
        mapView.setRegion(region, animated: true)
        locationManager.startUpdatingHeading()
    }
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        self.locationManager.stopUpdatingLocation()
        self.findLocations(strCategory)
    }
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }else{
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "annotationView") ?? MKAnnotationView()
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "annotationView")
            pinView.pinTintColor = UIColor.blue
            pinView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            pinView.canShowCallout = true
            annotationView = pinView
            return annotationView
        }
    }
    
    func findLocations(_ searchString: String?){
        if(self.localSearch?.isSearching ?? false){
            self.localSearch!.cancel()
        }
        var geoRegion = MKCoordinateRegion()
        let userLocation = locationManager.location?.coordinate
        geoRegion.center.latitude = userLocation!.latitude
        geoRegion.center.longitude = userLocation!.longitude
        
        geoRegion.span.latitudeDelta = 0.2000000
        geoRegion.span.longitudeDelta = 0.2000000
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchString
        request.region = geoRegion
        
        let completionHandler: MKLocalSearch.CompletionHandler = {response, error in
            if let actualError = error{
                let alert = UIAlertController(title: "Could not find places", message: actualError.localizedDescription, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                alert.addAction(defaultAction)
                self.present(alert, animated: true, completion: nil)
            }
            else{
                self.places = response!.mapItems
                self.mapItemList = self.places
                let placeMarks: NSMutableArray = NSMutableArray()
                
                for item in self.mapItemList{
                    let annotation = PlaceAnno()
                    annotation.coordinate = item.placemark.location!.coordinate
                    annotation.title = item.name
                    annotation.url = item.url
                    annotation.detailAddress = item.placemark.title
                    self.mapView.addAnnotation(annotation)
                    placeMarks.add(item)
                }
                self.boundingRegion = response!.boundingRegion
            }
             UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        self.localSearch = MKLocalSearch(request: request)
        self.localSearch!.start(completionHandler: completionHandler)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let overlays = mapView.overlays
        mapView.removeOverlays(overlays)
        if let location = view.annotation as? PlaceAnno{
            self.currentPlacemark = MKPlacemark(coordinate: location.coordinate)
        }
        
        let sourceCoordinates = locationManager.location?.coordinate
        let destinationCoordinates = view.annotation?.coordinate
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinates!)
        let destPlacemark = MKPlacemark(coordinate: destinationCoordinates!)
        
        let sourceItem = MKMapItem(placemark : sourcePlacemark)
        let destinationItem = MKMapItem(placemark : destPlacemark)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceItem
        directionRequest.destination = destinationItem
        directionRequest.transportType = .automobile
        directionRequest.requestsAlternateRoutes = true
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate { [unowned self] response, error in
            guard let unwrappedResponse = response else { return }
            var bestRoute = unwrappedResponse.routes[0]
            for route in response!.routes{
                print(route.distance)
                if route.distance <= bestRoute.distance{
                    bestRoute = route
                }
            }
            self.mapView.addOverlay(bestRoute.polyline)
            self.mapView.setVisibleMapRect(bestRoute.polyline.boundingMapRect, animated: true)
            self.locationManager.monitoredRegions.forEach({self.locationManager.stopMonitoring(for: $0)})
            self.steps = bestRoute.steps
            for i in 0 ..< bestRoute.steps.count{
                let step = bestRoute.steps[i]
                let region = CLCircularRegion(center: step.polyline.coordinate, radius: 20, identifier: "\(i)")
                self.locationManager.stopMonitoring(for: region)
                let circle = MKCircle(center: region.center, radius: region.radius)
                self.mapView.addOverlay(circle)
            }
            
            let initialMessage = "In \(self.steps[0].distance) meters, \(self.steps[0].instructions) then in \(self.steps[1].distance) meters, \(self.steps[1].instructions)."
            //self.directionsLabel.text = initialMessage
            let speechUtterance = AVSpeechUtterance(string: initialMessage)
            self.speechSynthesizer.speak(speechUtterance)
            self.stepCounter += 1
        }
            return
        }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay.isKind(of: MKPolyline.self) {
            // draw the track
            let polyLine = overlay
            let polyLineRenderer = MKPolylineRenderer(overlay: polyLine)
            polyLineRenderer.strokeColor = UIColor.magenta
            polyLineRenderer.lineWidth = 2.0
            return polyLineRenderer
        }
        else if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.strokeColor = .green
            renderer.fillColor = .green
            renderer.alpha = 0.5
            return renderer
        }
        return MKOverlayRenderer()
    }

}

