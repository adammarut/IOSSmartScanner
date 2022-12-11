//
//  StitchedImage.swift
//  Shop shelf scanner
//
//  Created by Adam Marut on 11/12/2022.
//

import Foundation

struct StitchedImage{
    var stitchedImage: UIImage
    var originalImages: NSMutableArray
    
    init(stitchedImage: UIImage, originals: NSMutableArray) {
        self.stitchedImage = stitchedImage
        self.originalImages = originals
    }
}
