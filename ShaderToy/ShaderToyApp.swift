//
//  ShaderToyApp.swift
//  ShaderToy
//
//  Created by Maxim Bezdenezhnykh on 17/11/2024.
//

import SwiftUI

enum GlobalLayout {
    static let shaderSize: CGFloat = 500
    static let panelInset: CGFloat = 8
    static let windowHeight: CGFloat = shaderSize + bottomPanelHeight + 2 * panelInset
    static let windowWidth: CGFloat = NSScreen.main.map { $0.frame.size.width - 32 } ?? shaderSize * 2
    static let bottomPanelHeight: CGFloat = 40
}

@main
struct ShaderToyApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(
                    minWidth: GlobalLayout.windowWidth,
                    maxWidth: GlobalLayout.windowWidth,
                    minHeight: GlobalLayout.windowHeight,
                    maxHeight: GlobalLayout.windowHeight
                )
        }
        .windowResizability(.contentSize)
    }
}
