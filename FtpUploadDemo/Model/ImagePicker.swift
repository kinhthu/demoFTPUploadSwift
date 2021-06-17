import SwiftUI

struct ImagePickerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage
    @Binding var selectedVideo: String
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePickerView>) -> UIViewController {
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        controller.mediaTypes = ["public.image", "public.movie"]
        return controller
    }
    
    func makeCoordinator() -> ImagePickerView.Coordinator {
        return Coordinator(parent: self)
    }
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerView
        init(parent: ImagePickerView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            
            if let videoUrl = info[.mediaURL] {
                self.parent.selectedVideo = ( videoUrl as! NSURL).path!
                self.parent.selectedImage = UIImage()
            } else if let selectedImageFromPicker = info[.originalImage] as? UIImage {
                self.parent.selectedVideo = ""
                self.parent.selectedImage = selectedImageFromPicker
            }
            
            self.parent.isPresented = false
        }
    }
    
    func updateUIViewController(_ uiViewController: ImagePickerView.UIViewControllerType, context: UIViewControllerRepresentableContext<ImagePickerView>) {
        
    }
    
}
