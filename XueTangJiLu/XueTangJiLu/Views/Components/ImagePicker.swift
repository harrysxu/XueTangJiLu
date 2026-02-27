//
//  ImagePicker.swift
//  XueTangJiLu
//
//  Created by AI Assistant on 2026/2/26.
//

import SwiftUI
import UIKit

private extension UIImage {
    func resizedForStorage(maxDimension: CGFloat) -> UIImage {
        let longerSide = max(size.width, size.height)
        guard longerSide > maxDimension else { return self }
        let scale = maxDimension / longerSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}

/// 相机/相册图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    var sourceType: UIImagePickerController.SourceType
    @Binding var selectedImageData: Data?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // 不需要更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                let resized = image.resizedForStorage(maxDimension: 1024)
                parent.selectedImageData = resized.jpegData(compressionQuality: 0.7)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
