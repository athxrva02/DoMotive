//
//  Date+Extensions.swift
//  DoMotive
//
//  Created by Atharva Dagaonkar on 18/07/25.
//

// Date+Extensions.swift
import Foundation

extension Date {
    func formattedShort() -> String {
        formatted(date: .abbreviated, time: .shortened)
    }
}
