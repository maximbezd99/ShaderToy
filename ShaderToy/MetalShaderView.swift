//
//  MetalShaderView.swift
//  ShaderToy
//
//  Created by Maxim Bezdenezhnykh on 17/11/2024.
//

import SwiftUI
import AppKit
import MetalKit
import Metal

enum ShaderLoadingState {
    case loading
    case error(String)
    case loaded
}

private struct ShaderEnv {
    var time: Float
    var width: Float
    var height: Float
}

private let defaultShaderCode = """
fragment half4 fragment_main(
    float4 position [[position]],
    constant Env& env [[buffer(0)]]
) {
    float2 uv = float2(position.x / env.width - 1, position.y / env.height - 1);
    float time = env.time;
    float2 center = float2(0.0, 0.0);
    
    float2 diff = uv - center;
    float radius = length(diff);
    float angle = atan2(diff.y, diff.x);

    float color = sin((radius * 10.0 - time * 5.0) + angle * 5.0);
    color = step(0.5, color);
    return half4(color, color, color, 1);
}
"""

@MainActor
final class ShaderManager: ObservableObject {
    fileprivate let device = MTLCreateSystemDefaultDevice()!
    
    fileprivate private(set) var commandQueue: MTLCommandQueue?
    fileprivate private(set) var pipelineState: MTLRenderPipelineState?
    fileprivate private(set) var uniformBuffer: MTLBuffer?
    
    @Published
    private(set) var shaderLoadingState: ShaderLoadingState = .loading
    
    @Published
    var shaderCode: String = defaultShaderCode
    
    @Published
    var timeSpeed: Float = SpeedMapper().defaultValue
    
    @Published
    var isPlaying: Bool = true
    
    static let shared = ShaderManager()
    
    private init() {
        commandQueue = device.makeCommandQueue()
        uniformBuffer = device.makeBuffer(length: MemoryLayout<ShaderEnv>.size, options: [])
    }
    
    func play(_ flag: Bool) {
        isPlaying = flag
    }
    
    func reset() {
        shaderCode = defaultShaderCode
        recompile()
    }
    
    func recompile() {
        shaderLoadingState = .loading
        
        let library: MTLLibrary
        do {
            library = try device.makeLibrary(source: fullShaderCode(), options: nil)
        } catch {
            shaderLoadingState = .error("Can not compile a library:\n\(error.localizedDescription)")
            return
        }
        
        guard let vertextFunc = library.makeFunction(name: "vertex_main") else {
            shaderLoadingState = .error("Unexpected. Missing autogenerated vertex_main func.")
            return
        }
        
        guard let fragmentFunc = library.makeFunction(name: "fragment_main") else {
            shaderLoadingState = .error("Missing fragment_main func.")
            return
        }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertextFunc
        pipelineDescriptor.fragmentFunction = fragmentFunc
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
//        pipelineDescriptor.rasterSampleCount = 4
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            shaderLoadingState = .loaded
        } catch {
            shaderLoadingState = .error("Failed to create pipeline: \(error.localizedDescription)")
        }
    }
    
    fileprivate func fullShaderCode() -> String {
        """
        using namespace metal;
        
        struct Env {
            float time;
            float width;
            float height;
        };
        
        vertex float4 vertex_main(const device float4* vertexArray [[buffer(0)]], uint vertexID [[vertex_id]]) {
            return vertexArray[vertexID];
        }

        \(shaderCode)
        """
    }
}

@MainActor
struct MetalShaderView: NSViewRepresentable {
    private let manager = ShaderManager.shared
    
    func makeNSView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.manager.device)
        view.delegate = context.coordinator
        view.preferredFramesPerSecond = 60
        view.clearColor = MTLClearColor(red: 1, green: 1, blue: 1, alpha: 0)
//        view.sampleCount = 4
        return view
    }
    
    func updateNSView(_ uiView: MTKView, context: Context) {
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MTKViewDelegate {
        
        @MainActor
        let manager = ShaderManager.shared
        
        @MainActor
        private var uniforms = ShaderEnv(time: 0, width: Float(GlobalLayout.shaderSize), height: Float(GlobalLayout.shaderSize))
        
        private let mapper = SpeedMapper()
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {}
        
        func draw(in view: MTKView) {
            Task { @MainActor in
                guard let drawable = view.currentDrawable,
                      let descriptor = view.currentRenderPassDescriptor,
                      let pipelineState = manager.pipelineState,
                      let commandQueue = manager.commandQueue else { return }
                

                uniforms.time += manager.isPlaying ? (mapper.mapTime(speed: manager.timeSpeed) / Float(view.preferredFramesPerSecond)) : 0
                
                let bufferPointer = manager.uniformBuffer?.contents()
                memcpy(bufferPointer, &uniforms, MemoryLayout<ShaderEnv>.size)
                
                let commandBuffer = commandQueue.makeCommandBuffer()
                let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
                encoder?.setRenderPipelineState(pipelineState)
                
                // Draw triangle
                let vertices: [Float] = [
                    -1.0,  1.0, 0.0, 1.0,  // Top Left
                    -1.0, -1.0, 0.0, 1.0,  // Bottom Left
                    1.0,  1.0, 0.0, 1.0,  // Top Right
                    -1.0, -1.0, 0.0, 1.0,  // Bottom Left
                    1.0,  1.0, 0.0, 1.0,  // Top Right
                    1.0, -1.0, 0.0, 1.0   // Bottom Right
                ]
                encoder?.setVertexBytes(vertices, length: vertices.count * MemoryLayout<Float>.size, index: 0)
                encoder?.setFragmentBuffer(manager.uniformBuffer, offset: 0, index: 0)
                encoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
                
                encoder?.endEncoding()
                commandBuffer?.present(drawable)
                commandBuffer?.commit()
            }
        }
    }
}
