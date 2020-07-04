//
//  Bundle-decoding.swift
//  SpaceShooter
//
//  Created by Akshat Gupta on 04/07/20.
//  Copyright © 2020 coded. All rights reserved.
//

import Foundation

extension Bundle {
    func decode<T : Decodable> (_ type : T.Type, from file :String) -> T {
        guard let url = self.url(forResource: file, withExtension: nil) else {
            fatalError("failed to locate \(file) in  bundle .")
        }
        
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failed tp load \(file) from bundle. ")
        }
         
        let decoder = JSONDecoder()
        guard let loaded = try? decoder.decode(T.self, from: data) else {
            fatalError("Failed to decode \(file) from bundle .")
        }
        return loaded
        
    }
}
