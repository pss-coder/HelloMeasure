//
//  MeasureARView.swift
//  HelloMeasure
//
//  Created by Pawandeep Singh Sekhon on 26/8/24.
//

import SwiftUI
import RealityKit
import ARKit

struct MeasureARView: UIViewRepresentable {
    
    // Binding Objects
    @Binding var distance: Float
    
    @Binding var coordinator: Coordinator
    
    @Binding var arView: ARView
    
    var onPlaneFoundStatus: (_ planeFoundStatus: Bool) -> Void
    
    
    var onMeasured: (_ distance: Float?) -> Void
    
    func makeCoordinator() -> Coordinator {
        return coordinator
    }
    
    
    func makeUIView(context: Context) -> ARView {
        
        arView.session.delegate = context.coordinator
        
        
        context.coordinator.view = arView
        context.coordinator.onPlaneFoundStatus = onPlaneFoundStatus // register handler
        context.coordinator.onMeasured = onMeasured
        
       
        
        // configurations
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        arView.session.run(config)
        

        // create tap gesture recogniser
        //let tapGestureRecogniser = UITapGestureRecognizer(target: context.coordinator,
                                                          //action: #selector(Coordinator.handleTap))
        //arView.addGestureRecognizer(tapGestureRecogniser)
        return arView
        
    }
    
    // Helper function to create the 2D center dot
        func createCenterDot() -> UIView {
            let dotView = UIView()
            dotView.backgroundColor = .black
            dotView.layer.cornerRadius = 5 // Half of width/height for a circle
            dotView.layer.masksToBounds = true
            return dotView
        }
    

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.view = uiView
        //context.coordinator.startMeasurement()
    }
}

class Coordinator: NSObject, ARSessionDelegate {
    
    
    var view: ARView?
    
    //TODO: DISTANCE Tracking
    var startAnchor: AnchorEntity?
    var endAnchor: AnchorEntity?
    
    
    var onPlaneFoundStatus: ((_ planeFoundStatus: Bool) -> Void)? = nil
    
    var onMeasured: ((_ distance: Float?) -> Void)? = nil
    
    // Tap gestures
    @objc
    func handleTap(_ recogniser: UITapGestureRecognizer) {
        
        // Check if there is a view to work with
        guard let view = self.view else { return }
        
        //Tap Location
        let tapLocation = recogniser.location(in: view)
        
        let results = view.raycast(from: tapLocation, allowing: .estimatedPlane, alignment: .any)
        
        if let firstResults = results.first {
            
            //3d points (x,y,z)
            let worldPos = simd_make_float3(firstResults.worldTransform.columns.3)
            
            // create dot
            let dot = createDotEntity(at: worldPos)
            
            // anchor dot on view
            let anchor = AnchorEntity(world: worldPos)
            anchor.children.append(dot)
            view.scene.anchors.append(anchor)
        }
    }
    
    func calculateDistanceBetween(start: AnchorEntity, end: AnchorEntity) -> Float {
        
        // get point distance
        let startPoint = start.position(relativeTo: nil)
        let endPoint = end.position(relativeTo: nil)
        
        // get distance between the two points
        let distance = simd_distance(startPoint, endPoint)
        return distance
    }
    
    func startMeasurement() {
        // Check if there is a view to work with
        guard let view = self.view else { return }
        
        let center = view.center // center point
        
        let results = view.raycast(from: center, allowing: .estimatedPlane, alignment: .any)
        
        if let firstResult = results.first {
            
            //start with first pointer
            if startAnchor == nil {
                
                //initialise startAnchor with pointer to view
                startAnchor = anchor(model: createPoint(), at: firstResult)
                
                guard let startAnchor = startAnchor else {return}
                
                // add anchor to view
                view.scene.addAnchor(startAnchor)
                
                
            } else if endAnchor == nil {
                //second pointer
                endAnchor = anchor(model: createPoint(), at: firstResult)
                
                guard let endAnchor = endAnchor,
                        let startAnchor = startAnchor else {return}
                
                // add anchor to view
                view.scene.addAnchor(endAnchor)
                
                //get distance between 2 points
                let distance = calculateDistanceBetween(start: startAnchor, end: endAnchor)
                
                
                // draw line between the 2 points
                
                let rectangle = ModelEntity(mesh: .generateBox(width: 0.003, height: 0.003, depth: distance), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
                
                // Middle point of the two points
                // get point distance
                let startPoint = startAnchor.position(relativeTo: nil)
                let endPoint = endAnchor.position(relativeTo: nil)
                
                let middlePoint : simd_float3 = simd_float3((startPoint.x + endPoint.x)/2, (startPoint.y + endPoint.y)/2, (startPoint.z + endPoint.z)/2)
                        
                let lineAnchor = AnchorEntity()
                lineAnchor.position = middlePoint
                lineAnchor.look(at: startPoint, from: middlePoint, relativeTo: nil)
                lineAnchor.addChild(rectangle)
                view.scene.addAnchor(lineAnchor)
                
                // pass distance
                print(distance)
                
                // Update UI
                //measurementButton.setTitle(String(format: "%.2f m", distance), for: .normal)
                if let onMeasured = onMeasured {
                    onMeasured(distance)
                }
                
                
            }
        }
        
        
    }
    
    func anchor(model: ModelEntity, at location:ARRaycastResult) -> AnchorEntity {
        
        //Anchor
        let anchor = AnchorEntity(raycastResult: location)
        
        // Tie model to anchor
        anchor.addChild(model)
        return anchor
    }
    
    func clear() {
        
        guard let view = self.view else { return }
        
        print("clear")
        startAnchor = nil
        endAnchor = nil
        
        view.scene.anchors.removeAll()
        
        if let onMeasured = onMeasured {
            onMeasured(0)
        }
    }
    
    
    
    func addPoint() {
        // Check if there is a view to work with
        guard let view = self.view else { return }
        
        let center = view.center // center point
        
        let results = view.raycast(from: center, allowing: .estimatedPlane, alignment: .any)
        
        if let firstResults = results.first {
            
            if let onPlaneFoundStatus = onPlaneFoundStatus {
                onPlaneFoundStatus(true)
            }
            
            //3d points (x,y,z)
            let worldPos = simd_make_float3(firstResults.worldTransform.columns.3)
            
            // create dot
            let dot = createDotEntity(at: worldPos)
            
            // anchor dot on view
            let anchor = AnchorEntity(world: worldPos)
            anchor.children.append(dot)
            view.scene.anchors.append(anchor)
        } else {
            // pass message
            //print("can't detect plane")
            // find a nearby surface to measure
            if let onPlaneFoundStatus = onPlaneFoundStatus {
                onPlaneFoundStatus(false)
            }
            
            
        }
        
    }
    
    func createPoint() -> ModelEntity {
        let ball = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.01), materials: [SimpleMaterial(color: .black,isMetallic: false)])
        
        return ball
    }
    
    func createDotEntity(at position: SIMD3<Float>) -> ModelEntity {
        let dotMesh = MeshResource.generateSphere(radius: 0.03)
                let material = SimpleMaterial(color: .red, roughness: 0, isMetallic: false)
                let dotEntity = ModelEntity(mesh: dotMesh, materials: [material])
                dotEntity.position = position
                return dotEntity
            }
    
}
