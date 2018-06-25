//
//  StatisticViewController.swift
//  Photoworthy
//
//  Created by Theodore Tsivranidis on 6/18/18.
//  Copyright © 2018 Teo Tsivranidis. All rights reserved.
//

import UIKit

class Statistic {

    var likeCount: Int
    var numPhotos: Int
    
    init(likeCount: Int) {
        self.likeCount = likeCount;
        self.numPhotos = 1;
    }
    
    func getGrade() -> Int {
        return (numPhotos * numPhotos) + likeCount
    }
}
