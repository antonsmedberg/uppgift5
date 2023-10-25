//
//  ImageModelAnimal.swift
//  uppgift5
//
//  Created by Anton Smedberg on 2023-10-24.
//

import Vision
import Foundation
import UIKit
import SwiftUI



// Konverterar en UIImage till en CVPixelBuffer
extension UIImage {
    func toCVPixelBuffer(width: Int, height: Int) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer? = nil
        let attributes = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attributes, &pixelBuffer)
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
        let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer!), width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: colorSpace, bitmapInfo: bitmapInfo.rawValue)

        context?.draw(self.cgImage!, in: CGRect(x: 0, y: 0, width: width, height: height))

        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

        return pixelBuffer
    }
}

extension ImageModel.ImageModelError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .modelInitializationFailed:
                return "Failed to initialize the Core ML model."
            case .imageLoadingFailed:
                return "Failed to load the image."
            case .imageConversionFailed:
                return "Failed to convert the image to a buffer."
            case .classificationFailed(let message):
                return "Classification failed: \(message)"
        }
    }
}

class ImageModel {
    enum ImageModelError: Error {
        case modelInitializationFailed
        case imageLoadingFailed
        case imageConversionFailed
        case classificationFailed(String)
    }



    // The synchronous function for classifying the image.
    func synchronousClassifyImage(image: UIImage) throws -> String {
        // Try to initialize the Core ML model
        let imageClassifierWrapper: AnimalAntonImageClassifier
        do {
            imageClassifierWrapper = try AnimalAntonImageClassifier(configuration: MLModelConfiguration())
        } catch {
            print("Error initializing model: \(error)")
            throw ImageModelError.modelInitializationFailed
        }

        // Convert the image to a buffer
        guard let theimageBuffer = buffer(from: image) else {
            print("Image Conversion Error")
            throw ImageModelError.imageConversionFailed
        }

        do {
            // Try to classify the image using the model
            let output = try imageClassifierWrapper.prediction(image: theimageBuffer)
            let confidencePercentage = Int((output.targetProbability[output.target]! * 100).rounded())
            let animalName = output.target.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? output.target

            return "\(animalName) (\(confidencePercentage)%)"
        } catch {
            throw ImageModelError.classificationFailed(error.localizedDescription)
        }
    }

    // This function utilizes the toCVPixelBuffer method directly on the UIImage instance
    private func buffer(from image: UIImage) -> CVPixelBuffer? {
        return image.toCVPixelBuffer(width: Int(image.size.width), height: Int(image.size.height))
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType
    var completionHandler: (UIImage?) -> Void

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(completionHandler)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var completionHandler: (UIImage?) -> Void

        init(_ completionHandler: @escaping (UIImage?) -> Void) {
            self.completionHandler = completionHandler
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                completionHandler(uiImage)
            } else {
                completionHandler(nil)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completionHandler(nil)
        }
    }
}
