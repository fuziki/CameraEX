//
//  GameViewController.swift
//  GameApp
//  
//  Created by fuziki on 2023/05/07
//  
//

import GameAppLib
import Metal
import MetalKit
import QuartzCore
import SceneKit

class GameViewController: NSViewController {

    let viewModel = GameViewModel()

    override func viewDidLoad() {
        super.viewDidLoad()

        CAMetalLayer.setupLastNextDrawableTexture()

        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!

        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)

        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)

        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)

        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = NSColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)

        // retrieve the ship node
        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!

        // animate the 3d object
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))

        // retrieve the SCNView
        let scnView = self.view as! SCNView

        // set the scene to the view
        scnView.scene = scene

        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true

        // show statistics such as fps and timing information
        scnView.showsStatistics = true

        // configure the view
        scnView.backgroundColor = NSColor.black

        // Add a click gesture recognizer
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        var gestureRecognizers = scnView.gestureRecognizers
        gestureRecognizers.insert(clickGesture, at: 0)
        scnView.gestureRecognizers = gestureRecognizers

        scnView.delegate = self
        scnView.preferredFramesPerSecond = 60

        let layer = scnView.layer as! CAMetalLayer
        layer.framebufferOnly = false
    }

    @objc
    func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView

        // check what nodes are clicked
        let p = gestureRecognizer.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]

            // get its material
            let material = result.node.geometry!.firstMaterial!

            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5

            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5

                material.emission.contents = NSColor.black

                SCNTransaction.commit()
            }

            material.emission.contents = NSColor.red

            SCNTransaction.commit()
        }
    }
}

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        DispatchQueue.main.async { [weak self] in
            let layer = self!.view.layer as! CAMetalLayer
            self!.viewModel.onRender(texture: layer.lastNextDrawableTexture!)
        }
    }
}

extension CAMetalLayer: LastNextDrawableTextureGettable {

}

public protocol LastNextDrawableTextureGettable {
    static func setupLastNextDrawableTexture()
    var lastNextDrawableTexture: MTLTexture? { get }
}

extension LastNextDrawableTextureGettable where Self: CAMetalLayer {
    public static func setupLastNextDrawableTexture() {
        Self.swizzling()
    }
    public var lastNextDrawableTexture: MTLTexture? {
        return cachedLastNextDrawableTexture
    }
}

extension CAMetalLayer {
    private struct AssociatedObjectKeyList {
        static var lastNextDrawableTextureKey = "lastNextDrawableTextureKey"
    }

    fileprivate static func swizzling() {
        _ = runSwizzling
    }

    fileprivate var cachedLastNextDrawableTexture: MTLTexture? {
        get {
            return objc_getAssociatedObject(self, &AssociatedObjectKeyList.lastNextDrawableTextureKey) as? MTLTexture
        }
        set {
            objc_setAssociatedObject(self, &AssociatedObjectKeyList.lastNextDrawableTextureKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }

    // avoid multiple calls
    private static var runSwizzling: Void = {
        let cls = CAMetalLayer.self
        let original = class_getInstanceMethod(cls, #selector(nextDrawable))!
        let swizzling = class_getInstanceMethod(cls, #selector(swizzled_nextDrawable))!
        method_exchangeImplementations(original, swizzling)
    }()

    @objc private func swizzled_nextDrawable() -> CAMetalDrawable? {
        let swizzled = swizzled_nextDrawable()
        cachedLastNextDrawableTexture = swizzled?.texture
        return swizzled
    }
}
