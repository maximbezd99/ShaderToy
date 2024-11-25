//
//  ContentView.swift
//  ShaderToy
//
//  Created by Maxim Bezdenezhnykh on 17/11/2024.
//

import SwiftUI
import Metal

struct ContentView: View {
    
    @StateObject
    private var manager = ShaderManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0, content: {
                Group {
                    switch manager.shaderLoadingState {
                    case .loading:
                        ProgressView()
                    case .error(let text):
                        Text(text)
                    case .loaded:
                        MetalShaderView()
                    }
                }
                .frame(width: GlobalLayout.shaderSize, height: GlobalLayout.shaderSize)
                .cornerRadius(8)
                .padding([.leading, .vertical], GlobalLayout.panelInset)
                .padding([.trailing], GlobalLayout.panelInset / 2)
                
                ScrollView([.vertical]) {
                    ShaderTextEditor(text: $manager.shaderCode)
                }
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.placeholderTextColor), lineWidth: 2)
                }
                .cornerRadius(8)
                .padding([.trailing, .vertical], GlobalLayout.panelInset)
                .padding([.leading], GlobalLayout.panelInset / 2)
            })
            
            HStack(spacing: 0) {
                HStack(spacing: 8) {
                    Button(
                        action: {
                            manager.play(!manager.isPlaying)
                        },
                        label: {
                            Image(systemName: manager.isPlaying ? "pause.fill" : "play.fill")
                        }
                    )
                    
                    Text(String(format: "%.2f", SpeedMapper().mapTime(speed: manager.timeSpeed)))
                        .font(.system(.headline, design: .monospaced))
                    
                    Slider(
                        value: $manager.timeSpeed,
                        in: SpeedMapper().range,
                        step: 1
                    )
                    
                    
                    
                    Spacer()
                }
                .frame(width: GlobalLayout.shaderSize)
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(
                        action: {
                            manager.reset()
                        },
                        label: {
                            Text("Reset")
                        }
                    )
                    
                    Button(
                        action: {
                            manager.recompile()
                        },
                        label: {
                            Text("Recompile")
                        }
                    )
                }
            }
            .padding(.horizontal, 10)
            .frame(height: GlobalLayout.bottomPanelHeight)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .task {
            manager.recompile()
        }
    }
}

#Preview {
    ContentView()
}
