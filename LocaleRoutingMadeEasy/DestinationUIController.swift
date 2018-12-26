//
//  DestinationUIController.swift
//  LocaleRoutingMadeEasy
//
//  Created by Sudeepta Das on 12/25/18.
//  Copyright © 2018 Sudeepta Das. All rights reserved.
//

import UIKit

class DestinationUIController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    var differentInterests: NSMutableArray!
    var places = [Location]()
    var searchPoints = [Location]()
    
    @IBOutlet weak var tableShow: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.getListOfPlaces()
        // Do any additional setup after loading the view.
    }
    
    func getListOfPlaces(){
        if let path = Bundle.main.path(forResource: "categories", ofType: "json"){
            do{
                let jsonData = try NSData(contentsOfFile: path, options: NSData.ReadingOptions.mappedIfSafe)
                do{
                    if let json = try JSONSerialization.jsonObject(with: jsonData as Data, options: .allowFragments) as? [String:AnyObject]{
                        let header = json["DESTINATIONS"] as? [String]
                        
                        for category in header!{
                            let place = Location()
                            place.title = category
                            self.places.append(place)
                        }
                        self.searchPoints = self.places
                        self.tableShow.reloadData()
                    }
                    
                }
                catch{
                    print("Error in JSONSerialization")
                }
            }
            catch{}
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.searchPoints.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath) as! CustomCell
        let place = self.searchPoints[indexPath.row]
        cell.labelTitle.text = place.title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let mapView = self.storyboard?.instantiateViewController(withIdentifier: "mapView") as! MapViewController
        let place = self.searchPoints[indexPath.row]
        mapView.strCategory = place.title
        self.navigationController?.pushViewController(mapView, animated: true)
        
    }

}
extension DestinationUIController: UISearchBarDelegate
{
    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        
        if searchBar.text == "" {
            self.searchPoints = self.places
            tableShow.reloadData()
        }else{
            
            return
        }
    }
    
    public func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        return true
    }
    
    public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
        if searchBar.text == "" {
            
            self.searchPoints = self.places
            tableShow.reloadData()
        }else {
            return
        }
    }
    
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText == "" {
            self.searchPoints = self.places
        }else {
            
            self.searchPoints = []
            
            for string in self.places {
                
                if string.title.lowercased().hasPrefix(searchText.lowercased()) {
                    self.searchPoints.append(string)
                }
            }
        }
        tableShow.reloadData()
        
    }
    public func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool{
        return true
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.text = ""
        searchBar.resignFirstResponder()
        self.searchPoints = self.places
        
        tableShow.reloadData()
    }
    
}
