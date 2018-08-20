//
//  MapVC.swift
//  Photoworthy
//
//  Created by Theodore Tsivranidis on 5/30/18.
//  Copyright © 2018 Teo Tsivranidis. All rights reserved.
//

import UIKit
import GoogleMaps
import Firebase

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

class MapVC: UIViewController, CLLocationManagerDelegate {
    
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
    
    var locationManager = CLLocationManager();
    lazy var mapView = GMSMapView();
    
    var userLon: String = "";
    var userLat: String = "";
    
    var poi = [Place: Statistic]();
    var explored = [Place: Statistic]();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GMSServices.provideAPIKey("AIzaSyA6w_RPEv-nybaE9QPdNeYvDJWxBSNkXrY")
        
        // User Location
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        self.update()
    }
    
    func update(){
        // try to find solutions to delays.. we essentially want 2 seconds for getPointsFromApi and want updateMap to get called as soon as getPointsFromApi is done.
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            self.updatePoi()
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3), execute: {
            self.updateExplored()
            self.updateMap()
        })
    }
    
    func updateExplored() {
        // check for exploration.
        for (place, stat) in self.poi {
            let poiLoc: CLLocation = CLLocation(latitude: place.coordinates.latitude, longitude: place.coordinates.longitude)
            let userLoc: CLLocation = CLLocation(latitude: Double(self.userLat)!, longitude: Double(self.userLon)!)
            
            if poiLoc.distance(from: userLoc) <= 1200 {
                // TO-DO: send notification
                
                self.poi.removeValue(forKey: place)
                self.explored[place] = stat
                
                // increment points and num places
                let ref: DatabaseReference = Database.database().reference()
                let user: User = Auth.auth().currentUser!
                
                ref.child("users").child(user.uid).setValue(["numpoi" : 0, "numpoints" : 0])
                
                ref.child("users").child(user.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    
                    let value = snapshot.value as? NSDictionary
                    
                    let numPoi: Int = value?["numpoi"] as! Int + 1
                    let numPoints: Int = value?["numpoints"] as! Int + stat.getGrade()
                    
                    var explored = [Place: Statistic]()
                    explored[place] = stat
                    // need to save explored on firebase so that pin stays on map.
                    
                    ref.child("users").child(user.uid).setValue(["numpoi" : numPoi, "numpoints" : numPoints])
                }) { (error) in
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func updateMap() {
        
        for (place, stat) in self.explored {
            let marker = GMSMarker(position: place.coordinates)
            
            marker.title = place.name + " (EXPLORED)"
            marker.snippet = "Total: " + "\n# Of Photos: " + String(stat.numPhotos) + "\n# Of Likes: " + String(stat.likeCount) + "\nGrade: " + String(stat.getGrade());
            marker.icon = UIImage(named: "explored-pin");
            
            marker.map = self.mapView
        }
        
        var topPoiGrade: Int = 0;
        
        for (_, stat) in self.poi {
            if (topPoiGrade < stat.getGrade()) {
                topPoiGrade = stat.getGrade()
            }
        }
        // looping through points of interest
        for (place, stat) in self.poi {
            let marker = GMSMarker(position: place.coordinates)

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
    
    
    func updatePoi() {
        let jsonUrl: String = "https://api.instagram.com/v1/media/search?access_token=271596368.7bcf37d.b24aac850aea4064acf83328a059d0d9&lat=" + userLat + "&lng=" + userLon + "&distance=5000"
        guard let url = URL(string: jsonUrl) else { return }
    
        URLSession.shared.dataTask(with: url) { (data, response, err) in
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(ResponseData.self, from: data)
                
                for image in response.data! {
                    let place = Place(coordinates: CLLocationCoordinate2D(latitude: (image.location?.latitude)!, longitude: (image.location?.longitude)!), name: (image.location?.name)!);
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
        
        let place = Place(coordinates: CLLocationCoordinate2D(latitude: 40.6, longitude: 23), name: "place")
        self.poi[place] = Statistic(likeCount: 80);
        self.poi[place]?.numPhotos += 251
        
        let place2 = Place(coordinates: CLLocationCoordinate2D(latitude: 40.59, longitude: 23.03), name: "place 2")
        self.poi[place2] = Statistic(likeCount: 500);
        
        let place3 = Place(coordinates: CLLocationCoordinate2D(latitude: 40.56, longitude: 22.99), name: "place 3")
        self.poi[place3] = Statistic(likeCount: 200);
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let bounds = UIScreen.main.bounds
        let mapWidth = bounds.size.width
        let mapHeight = 13 * bounds.size.height / 16
        
        let userLocation = locations.last
        
        userLat = String(userLocation!.coordinate.latitude)
        userLon = String(userLocation!.coordinate.longitude)
        
        let camera = GMSCameraPosition.camera(withLatitude: userLocation!.coordinate.latitude,
                                              longitude: userLocation!.coordinate.longitude, zoom: 13.0)
        mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: 60, width: mapWidth, height: mapHeight), camera: camera)
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
    
}

