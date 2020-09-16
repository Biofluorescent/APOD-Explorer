//
//  AstronomyJSON.swift
//  APOD Explorer
//
//  Created by Tanner Quesenberry on 9/16/20.
//  Copyright © 2020 Tanner Quesenberry. All rights reserved.
//

import Foundation

struct AstronomyJSON: Codable {
    var date: String
    var explanation: String
    var media_type: String
    var title: String
    var url: String
    var copyright: String?
}
