//
//  SpeedMapper.swift
//  ShaderToy
//
//  Created by Maxim Bezdenezhnykh on 17/11/2024.
//

import Foundation

struct SpeedMapper {
    let minValue: Float = 1
    let maxValue: Float = 17
    var range: ClosedRange<Float> {
        minValue...maxValue
    }
    
    let defaultValue: Float = 5
    
    private static let map: [Float: Float] = [
        1: 0.1,
        2: 0.25,
        3: 0.3,
        4: 0.5,
        5: 0.75,
        6: 0.8,
        7: 0.9,
        8: 1.0,
        9: 1.1,
        10: 1.25,
        11: 1.5,
        12: 1.75,
        13: 2.0,
        14: 3.0,
        15: 5.0,
        16: 8.0,
        17: 10.0,
    ]
    
    func mapTime(speed: Float) -> Float {
        SpeedMapper.map[speed] ?? 1
    }
}
