// swift-tools-version: 5.9
//
//  Package.swift
//
//
//  Created by mc-public on 2023/12/27.
//
import PackageDescription

let package = Package(
    name: "TextStorage",
    platforms: [.iOS("13.0")],
    products: [
        .library(
            name: "TextStorage",
            targets: ["TextStorage"])
    ],
    targets: [
        .target(name: "TextStorage", dependencies: ["PieceTree"]),
        .target(name: "PieceTree", sources: ["./tree-sitter/src/lib.c", "./fredbuf/fredbuf.cpp", "./fredbuf/PieceTreeStorage.mm", "./fredbuf/fredbuf-tree-sitter.mm", "./tree-sitter/c-parser/c-parser.c"], cSettings: [.headerSearchPath("./tree-sitter/include/")]),
        .testTarget(
            name: "TextStorageTests",
            dependencies: ["TextStorage"],
            path: "Tests/TextStorageTests",
            resources: [.copy("sqlite3.txt")]
        )
    ],
    cxxLanguageStandard: .cxx20
)
