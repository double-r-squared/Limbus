//
//  CalibrationMTKViewController.swift
//  Metal Camera
//
//  Created by Nate  on 8/2/25.
//  Copyright © 2025 Old Yellow Bricks. All rights reserved.
//

import UIKit
import Metal

#if arch(i386) || arch(x86_64)
#else
    import MetalKit
#endif

/**
 * A `UIViewController` that allows quick and easy rendering of Metal textures. Currently only supports textures from single-plane pixel buffers, e.g. it can only render a single RGB texture and won't be able to render multiple YCbCr textures. Although this functionality can be added by overriding `MTKViewController`'s `willRenderTexture` method.
 */
open class CalibarationMTKViewController: UIViewController {
    // MARK: - Public interface
    
    /// Metal texture to be drawn whenever the view controller is asked to render its view. Please note that if you set this `var` too frequently some of the textures may not being drawn, as setting a texture does not force the view controller's view to render its content.

    open var texture: MTLTexture?
    
    // MARK: Capture Variables
    public var onFrameCaptured: ((MTLTexture, Float) -> Void)?
    
    private var lastCaptureTime: Date = .distantPast
    
    /**
     This method is called prior rendering view's content. Use `inout` `texture` parameter to update the texture that is about to be drawn.
     
     - parameter texture:       Texture to be drawn
     - parameter commandBuffer: Command buffer that will be used for drawing
     - parameter device:        Metal device
     */
    open func willRenderTexture(_ texture: inout MTLTexture, withCommandBuffer commandBuffer: MTLCommandBuffer, device: MTLDevice) {
        /**
         * Override if neccessary
         */
        self.compute(texture: texture, withcommandBuffer: commandBuffer, device: device)
    }
    
    /**
     This method is called after rendering view's content.
     
     - parameter texture:       Texture that was drawn
     - parameter commandBuffer: Command buffer we used for drawing
     - parameter device:        Metal device
     */
    open func didRenderTexture(_ texture: MTLTexture, withCommandBuffer commandBuffer: MTLCommandBuffer, device: MTLDevice) {
        /**
         * Override if neccessary
         */
    }

    // MARK: - Public overrides
    
    override open func loadView() {
        super.loadView()
#if arch(i386) || arch(x86_64)
        NSLog("Failed creating a default system Metal device, since Metal is not available on iOS Simulator.")
#else
        assert(device != nil, "Failed creating a default system Metal device. Please, make sure Metal is available on your hardware.")
#endif
        initializeMetalView()
        initializeRenderPipelineState()
        initializeComputePipelineState()
    }

    
    // MARK: - Private Metal-related properties and methods
    
    /**
     initializes and configures the `MTKView` we use as `UIViewController`'s view.
     
     */
    fileprivate func initializeMetalView() {
#if arch(i386) || arch(x86_64)
#else
        metalView = MTKView(frame: view.bounds, device: device)
        metalView.delegate = self
        metalView.framebufferOnly = true
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.contentScaleFactor = UIScreen.main.scale
        metalView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(metalView, at: 0)

#endif
    }

#if arch(i386) || arch(x86_64)
#else
    
    /// `UIViewController`'s view
    internal var metalView: MTKView!
    
#endif

    /// Metal device
    internal var device = MTLCreateSystemDefaultDevice()

    /// Metal device command queue
    lazy internal var commandQueue: MTLCommandQueue? = {
        return device?.makeCommandQueue()
    }()

    /// Metal pipeline state we use for rendering
    internal var renderPipelineState: MTLRenderPipelineState?
    
    /// Metal pipeline state we use for computing
    internal var computePipelineState: MTLComputePipelineState?

    /// Buffer to store analysis result from compute shader
    internal var analysisBuffer: MTLBuffer!
    
    //to be updated
    internal var score: Float = 0.0

    /// A semaphore we use to syncronize drawing code.
    fileprivate let semaphore = DispatchSemaphore(value: 1)
    
    /**
     initializes render pipeline state with a default vertex function mapping texture to the view's frame and a simple fragment function returning texture pixel's value.
     */
    fileprivate func initializeRenderPipelineState() {
        guard
            let device = device,
            let library = device.makeDefaultLibrary()
        else { return }
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.sampleCount = 1
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .invalid
        
        /**
         *  Vertex function to map the texture to the view controller's view
         */
        pipelineDescriptor.vertexFunction = library.makeFunction(name: "mapTexture")
        /**
         *  Fragment function to display texture's pixels in the area bounded by vertices of `mapTexture` shader
         */
        pipelineDescriptor.fragmentFunction = library.makeFunction(name: "displayTexture")

        do {
            try renderPipelineState = device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        }
        catch {
            assertionFailure("Failed creating a render state pipeline. Can't render the texture without one.")
            return
        }
    }
    
    fileprivate func initializeComputePipelineState() {
        guard
            let device = device,
            let library = device.makeDefaultLibrary(),
            let kernel = library.makeFunction(name: "analyzeCenterRegion") else { return }
                
        /**
         *  kernel function to average 100x100 grid at the center of the texture generated by `kernel` shader
         */
        do {
            computePipelineState = try device.makeComputePipelineState(function: kernel)
        }
        catch {
            assertionFailure("Fuck you Pal")
            return
        }

        // Allocate result buffer (1 float)
        analysisBuffer = device.makeBuffer(length: MemoryLayout<Float>.stride, options: [])
    }
}

#if arch(i386) || arch(x86_64)
#else

// MARK: - MTKViewDelegate and rendering
extension CalibarationMTKViewController: MTKViewDelegate {
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        NSLog("MTKView drawable size will change to \(size)")
    }
    
    public func draw(in view: MTKView) {
        _ = semaphore.wait(timeout: .distantFuture)

        autoreleasepool {
            guard let device = device,
                  let commandBuffer = commandQueue?.makeCommandBuffer() else {
                _ = semaphore.signal()
                return
            }

            // If no texture is available, clear the view
            if texture == nil {
                guard let currentDrawable = metalView.currentDrawable else {
                    _ = semaphore.signal()
                    return
                }
                let renderPassDescriptor = MTLRenderPassDescriptor()
                renderPassDescriptor.colorAttachments[0].texture = currentDrawable.texture
                renderPassDescriptor.colorAttachments[0].loadAction = .clear
                renderPassDescriptor.colorAttachments[0].storeAction = .store
                renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1) // Black background
                if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                    renderEncoder.endEncoding()
                }
                commandBuffer.present(currentDrawable)
                commandBuffer.commit()
                _ = semaphore.signal()
                return
            }

            var textureToRender = texture!
            willRenderTexture(&textureToRender, withCommandBuffer: commandBuffer, device: device)
            render(texture: textureToRender, withCommandBuffer: commandBuffer, device: device)
        }
    }
    
    /**
     Renders texture into the `UIViewController`'s view.
     
     - parameter texture:       Texture to be rendered
     - parameter commandBuffer: Command buffer we will use for drawing
     */
    private func render(texture: MTLTexture, withCommandBuffer commandBuffer: MTLCommandBuffer, device: MTLDevice) {
        guard
            let currentRenderPassDescriptor = metalView.currentRenderPassDescriptor,
            let currentDrawable = metalView.currentDrawable,
            let renderPipelineState = renderPipelineState,
            let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: currentRenderPassDescriptor)
        else {
            semaphore.signal()
            return
        }
        var threshold: Float = 0.5 // Middle gray
        var currentScore = score
        encoder.setFragmentBytes(&currentScore, length: MemoryLayout<Float>.size, index: 2)

        encoder.setFragmentBytes(&threshold, length: MemoryLayout<Float>.size, index: 1)
        encoder.pushDebugGroup("RenderFrame")
        encoder.setRenderPipelineState(renderPipelineState)
        encoder.setFragmentTexture(texture, index: 0)
        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4, instanceCount: 1)
        encoder.popDebugGroup()
        encoder.endEncoding()
        
        commandBuffer.addScheduledHandler { [weak self] (buffer) in
            guard let unwrappedSelf = self else { return }
            
            unwrappedSelf.didRenderTexture(texture, withCommandBuffer: buffer, device: device)
            unwrappedSelf.semaphore.signal()
        }
        commandBuffer.present(currentDrawable)
        commandBuffer.commit()
    }
    
    
    
    
    
    
    
    
    
    /**
     Computes portion of texture and returns float into the `UIViewController`'s view.
    
     - parameter texture:       Texture to be computed
     - parameter commandBuffer: Command buffer we will use for computing
     */
    private func compute(texture: MTLTexture, withcommandBuffer commandBuffer: MTLCommandBuffer, device: MTLDevice) {
        guard let computePipelineState = computePipelineState else { return }
        guard let analysisBuffer = analysisBuffer else {
            print("❌ analysisBuffer is nil!")
            return
        }
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            semaphore.signal()
            return
        }

        computeEncoder.setComputePipelineState(computePipelineState)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setBuffer(analysisBuffer, offset: 0, index: 0)

        let threadsPerGrid = MTLSize(width: 1, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: 1, height: 1, depth: 1)

        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()

        commandBuffer.addCompletedHandler { [weak self] _ in
            guard let self = self else { return }
            
            let score = self.analysisBuffer.contents()
                              .assumingMemoryBound(to: Float.self)[0]
            
            DispatchQueue.main.async {
                self.score = score
                
                // Simple capture logic (brightness between 0.4-0.6)
                if 0.15 > score,
                   Date().timeIntervalSince(self.lastCaptureTime) > 1.0,
                   let texture = self.texture {
                    
                    self.lastCaptureTime = Date()
                    self.onFrameCaptured?(texture, score)
                }
            }
        }
    }
}

#endif
