import SwiftUI
import RealityKit
import UIKit
import QuickLookThumbnailing


//
// Main UI section. This contains the AR View and the dock for selecting different models
//
struct ContentView : View {
    let modelNames = ["monkey", "GV-statue", "GV-logo", "pancakes"]
    @State private var selectedIndex: Int = 0
    
    var body: some View {
        ZStack {
            ARViewContainer(selectedIndex: $selectedIndex).edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(modelNames.indices, id: \.self) { index in
                            let modelName = modelNames[index]
                            let isSelected = selectedIndex == index
                            let thumbnail = generateThumbnail(for: modelName)
                            
                            ZStack {
                                if let thumbnail = thumbnail {
                                    Image(uiImage: thumbnail)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: isSelected ? 90 : 75, height: isSelected ? 90 : 75)
                                        .cornerRadius(10)
                                        .padding(.horizontal, 5)
                                        .onTapGesture {
                                            selectedIndex = index
                                            print("Selected Index: \(selectedIndex)")
                                        }
                                } else {
                                    Text("Thumbnail generation failed for \(modelName)")
                                        .padding()
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.white.opacity(0.6))
                .cornerRadius(12)
                .padding(EdgeInsets(top: 0, leading: 10, bottom: 20, trailing: 10))
            }
        }
    }
    
    // Function that uses the QuickLookThumbnailing framework provided by apple generate preview images of models
    func generateThumbnail(for filename: String) -> UIImage? {
        guard let url = Bundle.main.url(forResource: filename, withExtension: "usdz") else {
            return nil
        }
        
        let generator = QLThumbnailGenerator()
        let request = QLThumbnailGenerator.Request(fileAt: url, size: CGSize(width: 200, height: 200), scale: UIScreen.main.scale, representationTypes: .thumbnail)
        
        var thumbnail: UIImage?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        generator.generateBestRepresentation(for: request) { (thumbnailRep, error) in
            if let thumbnailRep = thumbnailRep {
                thumbnail = thumbnailRep.uiImage
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        
        return thumbnail
    }
}


//
// Main Logic of the Augmented Reality App
// This ARViewContainer handles all of our models and keeps track of their points in our AR Scene
//
struct ARViewContainer: UIViewRepresentable {
    @Binding var selectedIndex: Int
    
    // Allows for recognition of gestures made by the user
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        // Add pinch gesture recognizer
        let pinchGesture = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinchGesture(_:)))
        arView.addGestureRecognizer(pinchGesture)
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTapGesture(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        // Add pan gesture recognizer
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePanGesture(_:)))
        arView.addGestureRecognizer(panGesture)
                
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.updateModelEntity(forIndex: selectedIndex, inARView: uiView)
    }
    
    // Coordinator allows us to interact with our models to resize/place/rotate
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var modelEntity: Entity?
        var lastPanPosition: CGPoint = .zero
        
        var parent: ARViewContainer
                
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func updateModelEntity(forIndex index: Int, inARView arView: ARView) {
            let modelName: String
            switch index {
            case 1:
                modelName = "GV-statue"
            case 2:
                modelName = "GV-logo"
            case 3:
                modelName = "pancakes"
            default:
                modelName = "monkey"
            }
            
            guard let currentEntity = try? Entity.load(named: modelName) else {
                fatalError("Failed to load model file.")
            }
            
            modelEntity = currentEntity
        }
        
        // Logic to handle the placement of models into our scene
        @objc func handleTapGesture(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView,
                  let modelEntity = modelEntity else { return }
            
            let tapLocation = gesture.location(in: arView)
            
            // Convert tap location to a 3D point in the AR world
            let tapLocation3D = arView.convert(tapLocation, to: nil)
            guard let raycastQuery = arView.makeRaycastQuery(from: tapLocation3D, allowing: .estimatedPlane, alignment: .horizontal) else {
                print("Failed to create raycast query.")
                return
            }
                        
            // Perform a hit-test to find where the user tapped in the AR scene
            if let hitTestResult = arView.session.raycast(raycastQuery).first {
                let anchorTransform = Transform(matrix: hitTestResult.worldTransform)
                
                // Create anchor entity for the content
                let anchor = AnchorEntity()
                anchor.transform = anchorTransform
                anchor.addChild(modelEntity)
                
                // Add the anchor to the scene
                arView.scene.addAnchor(anchor)
            }
            else {
                print("No plane detected at tapped location.")
            }
        }
        
        
        // Logic to handle the resizing of models
        @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            
            if gesture.state == .changed {
                let scale = gesture.scale
                // Get the selected entity
                if let selectedEntity = arView.scene.anchors.first?.children.first {
                    // Scale the selected entity
                    selectedEntity.transform.scale *= SIMD3<Float>(Float(scale), Float(scale), Float(scale))
                    gesture.scale = 1
                }
            }
        }
        
        // Logic to handle rotating the models
        @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
            guard let arView = gesture.view as? ARView,
                  let modelEntity = modelEntity else { return }
                        
            switch gesture.state {
            case .began:
                lastPanPosition = gesture.location(in: arView)
            case .changed:
                let currentPosition = gesture.location(in: arView)
                let deltaX = currentPosition.x - lastPanPosition.x
                
                // Calculate rotation angle based on horizontal movement
                let rotationAngle = Float(deltaX) * .pi / 180.0 // Convert to radians
                
                // Apply rotation to the selected entity around the z-axis
                modelEntity.transform.rotation *= simd_quatf(angle: rotationAngle, axis: [0, 0, 1])
                
                lastPanPosition = currentPosition
            default:
                break
            }
        }
    }
}

#Preview {
    ContentView()
}
