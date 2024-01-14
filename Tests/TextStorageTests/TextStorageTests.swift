import XCTest
@testable import TextStorage
#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

final class TextStorageTests: XCTestCase {
    
    private func printTime(_ prompt: String, closure: () -> ()) {
        let time1 = CFAbsoluteTimeGetCurrent()
        closure()
        let time2 = CFAbsoluteTimeGetCurrent()
        print(prompt, (time2 - time1) * 1000, "ms")
    }
    
    
    func testExample() throws {
        // XCTest Documentation
        // https://developer.apple.com/documentation/xctest

        // Defining Test Cases and Test Methods
        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
        
        let str = String(repeating: "🌍🌍✅🌍🌍🌍🌍🌍🌍🌍🌍🌍🌍HelloWorld你好世界\n", count: 5)
        let storage = TextStorage.init(str)
        storage.commitState()
        _ = try? storage.insert(text: "123", at: 0)
        _ = try? storage.delete(range: 0..<2)
        print(storage.string)
        _ = storage.undo()
        print(storage.string)
        print(try! storage.lineIndex(at: 1))
        printTime("Get All String") {
            _ = storage.string
        }
        printTime("Access First Line") {
            _ = try! storage.lineContent(at: 1)
        }
        printTime("Access Code Unit Length") {
            _ = storage.length
        }
    }
}
