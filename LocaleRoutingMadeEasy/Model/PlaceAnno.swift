//
//  PlaceAnno.swift
//  LocaleRoutingMadeEasy
//
//  Created by Sudeepta Das on 12/25/18.
//  Copyright © 2018 Sudeepta Das. All rights reserved.
//

import Foundation
import MapKit

class PlaceAnno: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    var title: String?
    var url: URL?
    var detailAddress: String?
    
}
