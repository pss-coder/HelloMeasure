//
//  ContentView.swift
//  HelloMeasure
//
//  Created by Pawandeep Singh Sekhon on 26/8/24.
//

import SwiftUI
import RealityKit

struct ContentView : View {
    
    @State private var distance: Float = 0
    
    @State private var arView = ARView(frame: .zero)
    

    @State private var planeFoundStatus: Bool = true
    
    @State private var coordinator: Coordinator = Coordinator()
    
    var body: some View {
        //ARViewContainer().edgesIgnoringSafeArea(.all)
        ZStack(content: {
            MeasureARView(distance: $distance, coordinator: $coordinator, arView: $arView, onPlaneFoundStatus: { planeFoundStatus in
                
                self.planeFoundStatus = planeFoundStatus
                    
            }, onMeasured: { distance in
                if let distance = distance {
                    self.distance = distance
                }
            })
                .ignoresSafeArea(.all)
            
            // 2D Center Dot
            Image(systemName: "scope")
                .frame(width: 10, height: 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            Circle()
                .frame(width: 5, height: 5)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            
            
            VStack {
                
                HStack(alignment: .center, content: {
                    Spacer()
                    
                    Button(action: {
                        //clear measurements
                        coordinator.clear()
                    }, label: {
                        Text("Clear")
                    })
                })
                .padding(.horizontal)
                            Spacer()
                            VStack {

//                                Text(planeFoundStatus ? "Distance: \(distance, specifier: "%.2f") meters" : "find a nearby surface to measure")
                                Text("Distance: \(distance, specifier: "%.2f") meters")
//                                    .padding()
                                Button(action: {
                                    //resetMeasurement()
                                    // add point here??
                                    //coordinator.addPoint() // add point in center
                                    //addDotToCenter()
                                    coordinator.startMeasurement()
                                }) {
                                    Image(systemName: "plus")
                                        .padding()
                                        .background(Color.blue)
                                        .clipShape(Circle())
                                        .foregroundColor(.white)
                                }
                                .padding()
                            }
                        }
            
        })
    }
    
}



#Preview {
    ContentView()
}
