//
//  ContentView.swift
//  uppgift5
//
//  Created by Anton Smedberg on 2023-10-24.
//

import SwiftUI
import CoreML
import Vision


struct ContentView: View {
    @State private var image: Image? = nil
    @State private var predictionLabel = ""

    // Create an instance of the ImageModel
    private var imageModel = ImageModel()

    // List of image names in your asset catalog
    let animalImages = ["gorilla", "elephant", "panda", "kangaroo"]

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(animalImages, id: \.self) { imageName in
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .onTapGesture {
                                self.image = Image(imageName)
                                if let uiImage = UIImage(named: imageName) {
                                    predictAnimalType(uiImage: uiImage)
                                }
                            }
                            .padding()
                    }
                }
            }
            image?
                .resizable()
                .scaledToFit()

            Text(predictionLabel)
        }
    }

    func predictAnimalType(uiImage: UIImage) {
        do {
            // Use the ImageModel's classification method
            let prediction = try imageModel.synchronousClassifyImage(image: uiImage)
            predictionLabel = prediction
        } catch {
            // Handle errors
            if let error = error as? ImageModel.ImageModelError {
                predictionLabel = error.errorDescription ?? "Unknown error"
            } else {
                predictionLabel = "Error predicting image: \(error)"
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
