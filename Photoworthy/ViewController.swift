//
//  ViewController.swift
//  Photoworthy
//
//  Created by Theodore Tsivranidis on 5/30/18.
//  Copyright © 2018 Teo Tsivranidis. All rights reserved.
//

import UIKit
import GoogleMaps

struct ResponseData: Decodable {
    let data: [ImageData]?
}

struct ImageData: Decodable {
    let location: LocationData?
    let likes: LikeData?
}

struct LocationData: Decodable {
    let latitude: Double?
    let longitude: Double?
    let name: String?
}

struct LikeData: Decodable {
    let count: Int?;
}

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    lazy var mapView = GMSMapView()
    var poi = [Place: Statistic]()
    var timer = Timer()
    
    let mapStyle = """
    [
    {
        "featureType": "administrative.land_parcel",
        "elementType": "labels",
        "stylers": [ { "visibility": "off" } ]
    },
    {
        "featureType": "poi",
        "elementType": "labels.text",
        "stylers": [ { "visibility": "off" } ]
    },
    {
        "featureType": "poi.business",
        "stylers": [ { "visibility": "off" } ]
    },
    {
        "featureType": "road",
        "elementType": "labels.icon",
        "stylers": [ { "visibility": "off" } ]
    },
    {
        "featureType": "road.local",
        "elementType": "labels",
        "stylers": [ { "visibility": "off" } ]
    },
    {
        "featureType": "transit",
        "stylers": [ { "visibility": "off" } ]
    }
    ]
    """
    
    var userLon: String = "";
    var userLat: String = "";
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GMSServices.provideAPIKey("AIzaSyA6w_RPEv-nybaE9QPdNeYvDJWxBSNkXrY")
        
        // User Location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
            self.getPointsFromApi()
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
            self.update()
        })
    }
    
    func update(){
        var topPoiGrade: Int = 0;
        
        for (_, stat) in self.poi {
            if (topPoiGrade < stat.getGrade()) {
                topPoiGrade = stat.getGrade()
            }
        }
        
        // looping through points of interest
        for (place, stat) in self.poi {
            let marker = GMSMarker(position: place.coordinates)
            // TO-DO:
            // if not explored, make title be ???
            // if explored make it be place.name
            marker.title = place.name
            marker.snippet = "Total: " + "\n# Of Photos: " + String(stat.numPhotos) + "\n# Of Likes: " + String(stat.likeCount) + "\nGrade: " + String(stat.getGrade());
            // Setting marker color according to grade.
            if (stat.getGrade() == topPoiGrade) {
                marker.icon = UIImage(named: "gold-pin");
            } else if (stat.getGrade() >= topPoiGrade / 2) {
                marker.icon = UIImage(named: "silver-pin");
            } else {
                marker.icon = UIImage(named: "bronze-pin");
            }
            marker.map = self.mapView
        }
    }
    
    
    func getPointsFromApi() {
        // replace this with current location instead of Brown
        print(userLon)
        print(userLat)
        // let jsonUrl: String = "https://api.instagram.com/v1/media/search?access_token=271596368.7bcf37d.b24aac850aea4064acf83328a059d0d9&lat=41.826766&lng=-71.400832&distance=5000"
        let jsonUrl: String = "https://api.instagram.com/v1/media/search?access_token=271596368.7bcf37d.b24aac850aea4064acf83328a059d0d9&lat=" + userLat + "&lng=" + userLon + "&distance=5000"
        guard let url = URL(string: jsonUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, err) in
            
            guard let data = data else { return }
            
            do {
                let response = try JSONDecoder().decode(ResponseData.self, from: data)
                
                for image in response.data! {
                    print("place being made.")
                    let place = Place(coordinates: CLLocationCoordinate2D(latitude: (image.location?.latitude)!, longitude: (image.location?.longitude)!), name: (image.location?.name)!);
                    // create statistic associated with the place
                    if self.poi[place] != nil {
                        self.poi[place]!.likeCount += (image.likes?.count)!;
                        self.poi[place]!.numPhotos += 1;
                    } else {
                        self.poi[place] = Statistic(likeCount: (image.likes?.count)!);
                    }
                }
            } catch let jsonErr {
                print("Error serializing json", jsonErr)
            }
        }.resume()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let bounds = UIScreen.main.bounds
        let mapWidth = bounds.size.width
        let mapHeight = 3 * bounds.size.height / 4
        
        let userLocation = locations.last
        
        userLat = String(userLocation!.coordinate.latitude)
        userLon = String(userLocation!.coordinate.longitude)
        
        let camera = GMSCameraPosition.camera(withLatitude: userLocation!.coordinate.latitude,
                                              longitude: userLocation!.coordinate.longitude, zoom: 13.0)
        mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: bounds.size.height / 8, width: mapWidth, height: mapHeight), camera: camera)
        
        do {
            // Setting the map style.
            mapView.mapStyle = try GMSMapStyle(jsonString: mapStyle)
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        mapView.isMyLocationEnabled = true
        self.view.addSubview(mapView)
        
        locationManager.stopUpdatingLocation()
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

