//
//  PanoramicImageView.swift
//
//  Created by Keith Hunter on 6/2/17.
//  Copyright © 2017 Keith Hunter. All rights reserved.
//

import CoreMotion
import SceneKit

/// Image view that displays panoramic images with built in pan gesture. Option to add device motion for extra control.
public class PanoramicImageView: SCNView {

    /// A panoramic image.
    public var image: UIImage? {
        get { return sphereNode.geometry?.firstMaterial?.diffuse.contents as? UIImage }
        set {
            // Since we are drawing the image on the back of the sphere, the image will show up
            // reversed. We need to mirror the image for it to appear correct.
            sphereNode.geometry?.firstMaterial?.diffuse.contents = newValue?.horizontallyMirrored()
        }
    }

    /// To update the view of the image based on the device's camera motion, create a 
    /// `CMMotionManager` and set this property with any device motion updates.
    public var deviceMotion: CMDeviceMotion? {
        didSet { updateCameraOrientation() }
    }

    private var previousTranslation = CGPoint.zero
    private var currentTranslationDelta = CGPoint.zero
    private var cumulativeRotationOffset = CGPoint.zero


    // MARK: - Init

    convenience public init() {
        self.init(frame: .zero)
    }

    override public init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        let panoramicScene = SCNScene()
        panoramicScene.rootNode.addChildNode(sphereNode)
        panoramicScene.rootNode.addChildNode(cameraNode)
        scene = panoramicScene

        addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handle(panGesture:))))
    }


    // MARK: - Updating the Camera

    @objc private func handle(panGesture: UIPanGestureRecognizer) {
        switch panGesture.state {
        case .began: previousTranslation = .zero
        case .changed:
            let currentTranslation = panGesture.translation(in: self)
            currentTranslationDelta = CGPoint(x: currentTranslation.x - previousTranslation.x, y: currentTranslation.y - previousTranslation.y)
            previousTranslation = currentTranslation
        default:
            previousTranslation = .zero
            currentTranslationDelta = .zero
        }

        updateCameraOrientation()
    }

    private func updateCameraOrientation() {
        let y = (currentTranslationDelta.x / bounds.size.width) * CGFloat.pi * 2
        let x = (currentTranslationDelta.y / bounds.size.height) * CGFloat.pi

        // Reset the delta. If we don't do this, the camera will continue to rotate if the user leaves their finger on the screen.
        currentTranslationDelta = .zero

        // If we are using core motion, combine the device motion data with the pan gesture data. 
        // Else, just use the pan gesture data.
        if let motion = deviceMotion {
            cumulativeRotationOffset.x += x
            cumulativeRotationOffset.y += y
            cameraNode.orientation = rotate(motion.gaze(at: UIApplication.shared.statusBarOrientation), by: cumulativeRotationOffset)
        } else {
            cameraNode.orientation = rotate(cameraNode.orientation, by: CGPoint(x: x, y: y))
        }
    }

    // Quaternion math from: https://github.com/alfiehanssen/ThreeSixtyPlayer
    private func rotate(_ orientation: SCNQuaternion, by rotationOffset: CGPoint) -> SCNQuaternion {
        // Represent the orientation as a GLKQuaternion
        var glQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)

        // Perform up and down rotations around *CAMERA* X axis (note the order of multiplication)
        let xMultiplier = GLKQuaternionMakeWithAngleAndAxis(Float(rotationOffset.x), 1, 0, 0)
        glQuaternion = GLKQuaternionMultiply(glQuaternion, xMultiplier)

        // Perform side to side rotations around *WORLD* Y axis (note the order of multiplication, different from above)
        let yMultiplier = GLKQuaternionMakeWithAngleAndAxis(Float(rotationOffset.y), 0, 1, 0)
        glQuaternion = GLKQuaternionMultiply(yMultiplier, glQuaternion)

        return SCNQuaternion(x: glQuaternion.x, y: glQuaternion.y, z: glQuaternion.z, w: glQuaternion.w)
    }


    // MARK: - Nodes

    // Mapping panoramic image inside sphere idea from: http://iosdeveloperzone.com/2016/05/02/using-scenekit-and-coremotion-in-swift/
    private let sphereNode: SCNNode = {
        let material = SCNMaterial()

        // The default cull is `.back`, which means the object will not render back facing surfaces.
        // For our sphere, the back is considered the inside of the sphere. The camera is placed inside
        // the sphere, so switch the cull to render the back; not the front (outside) of the sphere.
        material.cullMode = .front

        let sphere = SCNSphere(radius: 50)  // 50 was arbitrarily chosen.
        sphere.firstMaterial = material

        // The segment count must be sufficiently high so that the image doesn't get any distortion.
        sphere.segmentCount = 50

        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.position = SCNVector3Make(0, 0, 0)
        return sphereNode
    }()

    private let cameraNode: SCNNode = {
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()

        // Since we placed the sphere around the point (0, 0, 0), the camera should also be at this point.
        // This makes the camera perspective look like it is from the center of the image.
        cameraNode.position = SCNVector3Make(0, 0, 0)

        return cameraNode
    }()

}


// Extension from: https://gist.github.com/travisnewby/96ee1ac2bc2002f1d480
private extension CMDeviceMotion {

    func gaze(at orientation: UIInterfaceOrientation) -> SCNVector4 {
        let attitude = self.attitude.quaternion
        let aq = GLKQuaternionMake(Float(attitude.x), Float(attitude.y), Float(attitude.z), Float(attitude.w))
        let final: SCNVector4

        switch UIApplication.shared.statusBarOrientation {
        case .landscapeRight:
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float.pi / 2, 0, 1, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            final = SCNVector4(x: -q.y, y: q.x, z: q.z, w: q.w)

        case .landscapeLeft:
            let cq = GLKQuaternionMakeWithAngleAndAxis(-Float.pi / 2, 0, 1, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            final = SCNVector4(x: q.y, y: -q.x, z: q.z, w: q.w)

        case .portraitUpsideDown:
            let cq = GLKQuaternionMakeWithAngleAndAxis(Float.pi / 2, 1, 0, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            final = SCNVector4(x: -q.x, y: -q.y, z: q.z, w: q.w)

        case .unknown:
            fallthrough

        case .portrait:
            let cq = GLKQuaternionMakeWithAngleAndAxis(-Float.pi / 2, 1, 0, 0)
            let q = GLKQuaternionMultiply(cq, aq)
            final = SCNVector4(x: q.x, y: q.y, z: q.z, w: q.w)
        }

        return final
    }

}


private extension UIImage {

    func horizontallyMirrored() -> UIImage? {
        guard let cgImage = cgImage else { return nil }

        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Flip the image then translate it back into the context.
        context.scaleBy(x: -1.0, y: -1.0)
        context.translateBy(x: -size.width, y: -size.height)
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return image
    }

}

