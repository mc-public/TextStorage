//
//  TextStorageObservingProvider.swift
//
//
//  Created by mc-public on 2024/1/18.
//

import Foundation
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif


@available(iOS 13.0, macOS 12.0, *)
protocol TextStorageObservingProvider {
    var textStorage: TextStorage { get }
    
}



