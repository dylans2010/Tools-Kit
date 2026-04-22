import SwiftUI
import UIKit
import MetalKit
import CoreMotion
import simd

struct MailAILoadingView: View {
    let isActive: Bool
    let title: String
    let subtitle: String

    @State private var showOverlay = false
    @State private var revealAnimation = false

    var body: some View {
        Group {
            if showOverlay || isActive {
                loadingScene
                    .ignoresSafeArea()
                    .scaleEffect(revealAnimation ? 1.04 : 1.0)
                    .opacity(revealAnimation ? 0 : 1)
                    .blur(radius: revealAnimation ? 10 : 0)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear { updateOverlayState(isActive) }
        .onChange(of: isActive) { updateOverlayState($0) }
    }

    private var loadingScene: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.05, blue: 0.09), Color(red: 0.08, green: 0.10, blue: 0.18), Color(red: 0.13, green: 0.07, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            TimelineView(.animation) { timeline in
                let phase = timeline.date.timeIntervalSinceReferenceDate

                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.18))
                        .frame(width: 240, height: 240)
                        .blur(radius: 30)
                        .offset(x: CGFloat(sin(phase * 0.5)) * 110, y: CGFloat(cos(phase * 0.42)) * 80)

                    Circle()
                        .fill(Color.purple.opacity(0.16))
                        .frame(width: 180, height: 180)
                        .blur(radius: 25)
                        .offset(x: CGFloat(cos(phase * 0.35)) * -95, y: CGFloat(sin(phase * 0.48)) * 70)

                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 360, height: 360)
                        .blur(radius: 45)
                        .scaleEffect(1 + CGFloat(sin(phase * 0.7)) * 0.06)
                }
            }

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 100, height: 100)
                    Circle()
                        .strokeBorder(
                            AngularGradient(
                                colors: [.cyan, .blue, .purple, .pink, .cyan],
                                center: .center
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(revealAnimation ? 360 : 0))
                        .animation(.linear(duration: 2.8).repeatForever(autoreverses: false), value: revealAnimation)

                    Image(systemName: "apple.intelligence")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 6) {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }

                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { index in
                        Capsule()
                            .fill(Color.white.opacity(0.75 - Double(index) * 0.12))
                            .frame(width: 18, height: 6)
                            .scaleEffect(revealAnimation ? 1.0 : 0.82)
                            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true).delay(Double(index) * 0.14), value: revealAnimation)
                    }
                }
            }
            .padding(28)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(.white.opacity(0.14), lineWidth: 1))
            .shadow(color: .black.opacity(0.3), radius: 30, y: 16)
            .padding(.horizontal, 28)
        }
    }

    private func updateOverlayState(_ active: Bool) {
        if active {
            revealAnimation = false
            withAnimation(.easeInOut(duration: 0.24)) {
                showOverlay = true
            }
            return
        }

        guard showOverlay else { return }
        withAnimation(.timingCurve(0.4, 0.0, 0.2, 1.0, duration: 0.45)) {
            revealAnimation = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.48) {
            revealAnimation = false
            showOverlay = false
        }
    }
}

private struct MailAIMetalLoadingContainer: UIViewRepresentable {
    let title: String
    let subtitle: String
    let symbol: String

    func makeUIView(context: Context) -> MailAILoadingRootView {
        let view = MailAILoadingRootView()
        view.apply(title: title, subtitle: subtitle, symbol: symbol, animated: false)
        return view
    }

    func updateUIView(_ uiView: MailAILoadingRootView, context: Context) {
        uiView.apply(title: title, subtitle: subtitle, symbol: symbol, animated: true)
    }
}

private final class MailAILoadingRootView: UIView {
    private let metalView: MTKView
    private let contentOverlay = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let symbolView = UIImageView()
    private let renderer: MailAILoadingRenderer

    init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let renderer = MailAILoadingRenderer(device: device) else {
            fatalError("Metal is required for MailAILoadingView")
        }

        self.renderer = renderer
        metalView = MTKView(frame: .zero, device: device)
        super.init(frame: .zero)
        isOpaque = true
        backgroundColor = .black

        metalView.translatesAutoresizingMaskIntoConstraints = false
        metalView.framebufferOnly = false
        metalView.enableSetNeedsDisplay = false
        metalView.preferredFramesPerSecond = 120
        metalView.isPaused = false
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.depthStencilPixelFormat = .invalid
        metalView.clearColor = MTLClearColorMake(0, 0, 0, 1)
        metalView.delegate = renderer

        renderer.hostView = self

        configureOverlay()
        layoutUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            renderer.setActive(false)
        } else {
            renderer.setActive(true)
            renderer.resize(to: bounds.size, scale: window?.screen.scale ?? UIScreen.main.scale)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        renderer.resize(to: bounds.size, scale: window?.screen.scale ?? UIScreen.main.scale)
    }

    func apply(title: String, subtitle: String, symbol: String, animated: Bool) {
        let updates = {
            self.titleLabel.text = title
            self.subtitleLabel.text = subtitle
            self.symbolView.image = UIImage(systemName: symbol)
        }

        guard animated else {
            updates()
            return
        }

        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseInOut]) {
            self.titleLabel.alpha = 0
            self.subtitleLabel.alpha = 0
            self.titleLabel.transform = CGAffineTransform(translationX: 0, y: 6)
            self.subtitleLabel.transform = CGAffineTransform(translationX: 0, y: 6)
        } completion: { _ in
            updates()
            UIView.animate(
                withDuration: 0.36,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState]
            ) {
                self.titleLabel.alpha = 1
                self.subtitleLabel.alpha = 1
                self.titleLabel.transform = .identity
                self.subtitleLabel.transform = .identity
            }
        }
    }

    func updateForeground(phase: Float, tilt: SIMD2<Float>) {
        let driftX = CGFloat(tilt.x) * 18
        let driftY = CGFloat(tilt.y) * 14

        contentOverlay.transform = CGAffineTransform(translationX: driftX, y: -driftY)
        let bob = sin(CGFloat(phase) * 1.1) * 4
        titleLabel.transform = CGAffineTransform(translationX: 0, y: bob)
        subtitleLabel.transform = CGAffineTransform(translationX: 0, y: bob + 3)
    }

    private func configureOverlay() {
        addSubview(metalView)
        addSubview(contentOverlay)

        contentOverlay.translatesAutoresizingMaskIntoConstraints = false
        contentOverlay.backgroundColor = .clear

        symbolView.tintColor = UIColor.white.withAlphaComponent(0.95)
        symbolView.contentMode = .scaleAspectFit
        symbolView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.textColor = UIColor.white.withAlphaComponent(0.95)
        titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        subtitleLabel.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentOverlay.addSubview(symbolView)
        contentOverlay.addSubview(titleLabel)
        contentOverlay.addSubview(subtitleLabel)

        renderer.attachForeground(to: contentOverlay)
    }

    private func layoutUI() {
        NSLayoutConstraint.activate([
            metalView.leadingAnchor.constraint(equalTo: leadingAnchor),
            metalView.trailingAnchor.constraint(equalTo: trailingAnchor),
            metalView.topAnchor.constraint(equalTo: topAnchor),
            metalView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentOverlay.topAnchor.constraint(equalTo: topAnchor),
            contentOverlay.bottomAnchor.constraint(equalTo: bottomAnchor),

            symbolView.centerXAnchor.constraint(equalTo: contentOverlay.centerXAnchor),
            symbolView.centerYAnchor.constraint(equalTo: contentOverlay.centerYAnchor, constant: -30),
            symbolView.widthAnchor.constraint(equalToConstant: 34),
            symbolView.heightAnchor.constraint(equalToConstant: 34),

            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentOverlay.leadingAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentOverlay.trailingAnchor, constant: -28),
            titleLabel.centerXAnchor.constraint(equalTo: contentOverlay.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: symbolView.bottomAnchor, constant: 24),

            subtitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentOverlay.leadingAnchor, constant: 38),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentOverlay.trailingAnchor, constant: -38),
            subtitleLabel.centerXAnchor.constraint(equalTo: contentOverlay.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10)
        ])
    }
}

private struct MailParticle {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var baseAlpha: Float
    var size: Float
    var life: Float
}

private struct GPUParticle {
    var position: SIMD2<Float>
    var size: Float
    var alpha: Float
}

private struct SceneUniforms {
    var resolution: SIMD2<Float>
    var time: Float
    var tilt: SIMD2<Float>
    var glowBias: Float
}

private final class MailAILoadingRenderer: NSObject, MTKViewDelegate {
    weak var hostView: MailAILoadingRootView?

    private let device: MTLDevice
    private let queue: MTLCommandQueue
    private let gradientPipeline: MTLRenderPipelineState
    private let particlePipeline: MTLRenderPipelineState
    private let motion = CMMotionManager()

    private var particles: [MailParticle] = []
    private var gpuParticles: [GPUParticle] = []
    private var particleBuffer: MTLBuffer
    private var uniformsBuffer: MTLBuffer

    private var startTime = CACurrentMediaTime()
    private var lastFrameTime = CACurrentMediaTime()
    private var currentTime: Float = 0
    private var drawableSize = CGSize(width: 1, height: 1)

    private var targetTilt = SIMD2<Float>(0, 0)
    private var smoothedTilt = SIMD2<Float>(0, 0)
    private var active = true

    private let ringLayer = CAShapeLayer()
    private let pulseLayer = CAShapeLayer()
    private let networkLayer = CAShapeLayer()

    init?(device: MTLDevice) {
        self.device = device
        guard let queue = device.makeCommandQueue() else { return nil }
        self.queue = queue

        let shaderSource = Self.makeShaderSource()
        let library: MTLLibrary
        do {
            library = try device.makeLibrary(source: shaderSource, options: nil)
        } catch {
            return nil
        }

        guard
            let gradientVertex = library.makeFunction(name: "gradientVertex"),
            let gradientFragment = library.makeFunction(name: "gradientFragment"),
            let particleVertex = library.makeFunction(name: "particleVertex"),
            let particleFragment = library.makeFunction(name: "particleFragment")
        else { return nil }

        let gradientDescriptor = MTLRenderPipelineDescriptor()
        gradientDescriptor.vertexFunction = gradientVertex
        gradientDescriptor.fragmentFunction = gradientFragment
        gradientDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        let particleDescriptor = MTLRenderPipelineDescriptor()
        particleDescriptor.vertexFunction = particleVertex
        particleDescriptor.fragmentFunction = particleFragment
        particleDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        particleDescriptor.inputPrimitiveTopology = .point
        particleDescriptor.colorAttachments[0].isBlendingEnabled = true
        particleDescriptor.colorAttachments[0].rgbBlendOperation = .add
        particleDescriptor.colorAttachments[0].alphaBlendOperation = .add
        particleDescriptor.colorAttachments[0].sourceRGBBlendFactor = .one
        particleDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
        particleDescriptor.colorAttachments[0].destinationRGBBlendFactor = .one
        particleDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .one

        do {
            gradientPipeline = try device.makeRenderPipelineState(descriptor: gradientDescriptor)
            particlePipeline = try device.makeRenderPipelineState(descriptor: particleDescriptor)
        } catch {
            return nil
        }

        let maxParticles = 900
        particles = (0..<maxParticles).map { _ in
            MailParticle(
                position: SIMD2<Float>(Float.random(in: 0...1), Float.random(in: 0...1)),
                velocity: SIMD2<Float>(Float.random(in: -0.03...0.03), Float.random(in: -0.02...0.03)),
                baseAlpha: Float.random(in: 0.3...0.9),
                size: Float.random(in: 1.8...4.6),
                life: Float.random(in: 0...1)
            )
        }
        gpuParticles = Array(repeating: GPUParticle(position: .zero, size: 2, alpha: 0.4), count: maxParticles)

        guard let particleBuffer = device.makeBuffer(length: MemoryLayout<GPUParticle>.stride * maxParticles),
              let uniformsBuffer = device.makeBuffer(length: MemoryLayout<SceneUniforms>.stride)
        else { return nil }

        self.particleBuffer = particleBuffer
        self.uniformsBuffer = uniformsBuffer

        super.init()
        startMotion()
        configureForegroundLayers()
    }

    deinit {
        motion.stopDeviceMotionUpdates()
    }

    func attachForeground(to view: UIView) {
        [pulseLayer, ringLayer, networkLayer].forEach {
            view.layer.addSublayer($0)
        }
    }

    func setActive(_ isActive: Bool) {
        active = isActive
    }

    func resize(to size: CGSize, scale: CGFloat) {
        drawableSize = size
        let center = CGPoint(x: size.width * 0.5, y: size.height * 0.42)
        let radius = min(size.width, size.height) * 0.15

        ringLayer.frame = CGRect(origin: .zero, size: size)
        pulseLayer.frame = ringLayer.frame
        networkLayer.frame = ringLayer.frame

        ringLayer.path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        ).cgPath

        let networkPath = UIBezierPath()
        let nodes = 8
        for idx in 0..<nodes {
            let angle = CGFloat(idx) / CGFloat(nodes) * .pi * 2
            let node = CGPoint(x: center.x + cos(angle) * radius * 0.9, y: center.y + sin(angle) * radius * 0.9)
            networkPath.move(to: center)
            networkPath.addLine(to: node)
            networkPath.append(UIBezierPath(arcCenter: node, radius: 2.2, startAngle: 0, endAngle: .pi * 2, clockwise: true))
        }
        networkLayer.path = networkPath.cgPath

        let pulsePath = UIBezierPath(
            arcCenter: center,
            radius: radius * 0.7,
            startAngle: 0,
            endAngle: .pi * 2,
            clockwise: true
        )
        pulseLayer.path = pulsePath.cgPath

        ringLayer.contentsScale = scale
        pulseLayer.contentsScale = scale
        networkLayer.contentsScale = scale
    }

    func draw(in view: MTKView) {
        guard active,
              let descriptor = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        let now = CACurrentMediaTime()
        let delta = min(max(now - lastFrameTime, 1.0 / 240.0), 1.0 / 20.0)
        lastFrameTime = now
        currentTime = Float(now - startTime)

        smoothedTilt += (targetTilt - smoothedTilt) * 0.08
        updateParticles(delta: Float(delta), time: currentTime)
        updateUniforms(view: view)

        encoder.setRenderPipelineState(gradientPipeline)
        encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)

        encoder.setRenderPipelineState(particlePipeline)
        encoder.setVertexBuffer(particleBuffer, offset: 0, index: 0)
        encoder.setVertexBuffer(uniformsBuffer, offset: 0, index: 1)
        encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)
        encoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: particles.count)

        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()

        DispatchQueue.main.async {
            self.animateForeground(time: self.currentTime)
            self.hostView?.updateForeground(phase: self.currentTime, tilt: self.smoothedTilt)
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        drawableSize = size
    }

    private func updateParticles(delta: Float, time: Float) {
        for idx in particles.indices {
            var p = particles[idx]
            let noise = sin((p.position.x * 10 + time * 0.7) + cos(p.position.y * 8 - time * 0.9))
            let swirl = SIMD2<Float>(
                cos(noise * 3 + time * 0.8),
                sin(noise * 3 - time * 0.7)
            ) * 0.012

            let tiltForce = SIMD2<Float>(smoothedTilt.x * 0.03, -smoothedTilt.y * 0.03)
            p.velocity += (swirl + tiltForce) * delta * 60
            p.velocity *= 0.985
            p.position += p.velocity * delta * 60

            if p.position.x < -0.05 { p.position.x = 1.05 }
            if p.position.x > 1.05 { p.position.x = -0.05 }
            if p.position.y < -0.05 { p.position.y = 1.05 }
            if p.position.y > 1.05 { p.position.y = -0.05 }

            p.life += delta * (0.35 + p.baseAlpha * 0.25)
            if p.life > 1 { p.life -= 1 }

            particles[idx] = p
            let pulse = 0.5 + 0.5 * sin(time * 2.8 + p.life * .pi * 2)
            gpuParticles[idx] = GPUParticle(
                position: p.position,
                size: p.size,
                alpha: p.baseAlpha * (0.35 + 0.65 * pulse)
            )
        }

        gpuParticles.withUnsafeBytes { bytes in
            particleBuffer.contents().copyMemory(from: bytes.baseAddress!, byteCount: bytes.count)
        }
    }

    private func updateUniforms(view: MTKView) {
        var uniforms = SceneUniforms(
            resolution: SIMD2<Float>(Float(view.drawableSize.width), Float(view.drawableSize.height)),
            time: currentTime,
            tilt: smoothedTilt,
            glowBias: 0.7 + 0.3 * sin(currentTime * 0.6)
        )
        withUnsafeBytes(of: &uniforms) { bytes in
            uniformsBuffer.contents().copyMemory(from: bytes.baseAddress!, byteCount: bytes.count)
        }
    }

    private func configureForegroundLayers() {
        ringLayer.strokeColor = UIColor.white.withAlphaComponent(0.82).cgColor
        ringLayer.fillColor = UIColor.clear.cgColor
        ringLayer.lineWidth = 2.3

        pulseLayer.strokeColor = UIColor.cyan.withAlphaComponent(0.45).cgColor
        pulseLayer.fillColor = UIColor.clear.cgColor
        pulseLayer.lineWidth = 2

        networkLayer.strokeColor = UIColor.white.withAlphaComponent(0.42).cgColor
        networkLayer.fillColor = UIColor.white.withAlphaComponent(0.24).cgColor
        networkLayer.lineWidth = 1
        networkLayer.lineCap = .round

        let timing = CAMediaTimingFunction(controlPoints: 0.4, 0.0, 0.2, 1.0)

        let ringBreath = CABasicAnimation(keyPath: "transform.scale")
        ringBreath.fromValue = 0.92
        ringBreath.toValue = 1.08
        ringBreath.duration = 2.2
        ringBreath.autoreverses = true
        ringBreath.repeatCount = .infinity
        ringBreath.timingFunction = timing
        ringLayer.add(ringBreath, forKey: "ringBreath")

        let pulse = CAKeyframeAnimation(keyPath: "transform.scale")
        pulse.values = [0.8, 1.0, 1.45]
        pulse.keyTimes = [0.0, 0.45, 1.0]
        pulse.duration = 1.8
        pulse.repeatCount = .infinity
        pulse.timingFunction = timing
        pulseLayer.add(pulse, forKey: "pulse")

        let opacityPulse = CAKeyframeAnimation(keyPath: "opacity")
        opacityPulse.values = [0.0, 0.7, 0.0]
        opacityPulse.duration = 1.8
        opacityPulse.repeatCount = .infinity
        opacityPulse.timingFunction = timing
        pulseLayer.add(opacityPulse, forKey: "pulseOpacity")

        let networkOpacity = CABasicAnimation(keyPath: "opacity")
        networkOpacity.fromValue = 0.32
        networkOpacity.toValue = 0.9
        networkOpacity.duration = 1.4
        networkOpacity.autoreverses = true
        networkOpacity.repeatCount = .infinity
        networkOpacity.timingFunction = timing
        networkLayer.add(networkOpacity, forKey: "networkOpacity")
    }

    private func animateForeground(time: Float) {
        let shimmer = CGFloat(0.6 + 0.4 * sin(time * 1.7))
        ringLayer.shadowColor = UIColor.cyan.cgColor
        ringLayer.shadowRadius = 16 * shimmer
        ringLayer.shadowOpacity = Float(0.42 + 0.32 * shimmer)

        networkLayer.transform = CATransform3DMakeRotation(CGFloat(time * 0.25), 0, 0, 1)
    }

    private func startMotion() {
        guard motion.isDeviceMotionAvailable else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 60.0
        motion.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let self, let attitude = data?.attitude else { return }
            let x = Float(max(min(attitude.roll, 0.7), -0.7)) / 0.7
            let y = Float(max(min(attitude.pitch, 0.7), -0.7)) / 0.7
            self.targetTilt = SIMD2<Float>(x, y)
        }
    }

    private static func makeShaderSource() -> String {
        """
        #include <metal_stdlib>
        using namespace metal;

        struct SceneUniforms {
            float2 resolution;
            float time;
            float2 tilt;
            float glowBias;
        };

        struct RasterOut {
            float4 position [[position]];
            float2 uv;
        };

        struct GPUParticle {
            float2 position;
            float size;
            float alpha;
        };

        vertex RasterOut gradientVertex(uint vid [[vertex_id]]) {
            float2 p = float2((vid == 2) ? 3.0 : -1.0, (vid == 1) ? 3.0 : -1.0);
            RasterOut out;
            out.position = float4(p, 0.0, 1.0);
            out.uv = (p + 1.0) * 0.5;
            return out;
        }

        fragment float4 gradientFragment(RasterOut in [[stage_in]], constant SceneUniforms &u [[buffer(0)]]) {
            float2 uv = in.uv;
            float2 centered = uv - 0.5;
            float t = u.time;

            float flow = sin((uv.x * 4.5 + t * 0.23) + cos(uv.y * 3.8 - t * 0.18));
            float wave = sin((uv.y + uv.x) * 6.2 + t * 0.35 + u.tilt.x * 2.0);
            float depth = smoothstep(0.8, 0.02, length(centered + u.tilt * 0.12));

            float3 cyan = float3(0.08, 0.75, 1.0);
            float3 deep = float3(0.02, 0.16, 0.60);
            float3 neon = float3(0.38, 0.95, 1.0);
            float3 indigo = float3(0.09, 0.12, 0.42);

            float blendA = 0.5 + 0.5 * flow;
            float blendB = 0.5 + 0.5 * wave;

            float3 color = mix(deep, cyan, blendA);
            color = mix(color, indigo, 0.28 + 0.22 * sin(t * 0.21 + uv.x * 2.4));
            color += neon * (0.12 + 0.18 * blendB) * depth * (0.9 + u.glowBias * 0.3);

            float lightSweep = exp(-pow(length(centered - float2(u.tilt.x * 0.18, -u.tilt.y * 0.12)), 2.0) * 11.0);
            color += neon * lightSweep * 0.25;
            return float4(color, 1.0);
        }

        struct ParticleOut {
            float4 position [[position]];
            float pointSize [[point_size]];
            float alpha;
        };

        vertex ParticleOut particleVertex(
            const device GPUParticle *particles [[buffer(0)]],
            constant SceneUniforms &u [[buffer(1)]],
            uint vid [[vertex_id]]
        ) {
            GPUParticle p = particles[vid];
            float2 clip = p.position * 2.0 - 1.0;

            ParticleOut out;
            out.position = float4(clip, 0.0, 1.0);
            out.pointSize = p.size * (1.0 + 0.15 * sin(u.time * 2.2 + p.position.x * 12.0));
            out.alpha = p.alpha;
            return out;
        }

        fragment float4 particleFragment(ParticleOut in [[stage_in]], float2 pointCoord [[point_coord]], constant SceneUniforms &u [[buffer(0)]]) {
            float2 d = pointCoord - 0.5;
            float dist = length(d);
            float core = smoothstep(0.44, 0.0, dist);
            float glow = smoothstep(0.8, 0.0, dist);
            float flicker = 0.85 + 0.15 * sin(u.time * 3.2 + dist * 11.0);
            float alpha = (core + glow * 0.65) * in.alpha * flicker;
            float3 color = float3(0.45, 0.9, 1.0) * (0.4 + glow * 0.9);
            return float4(color * alpha, alpha);
        }
        """
    }
}
