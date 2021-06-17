import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var selectedImage: UIImage
    @Binding var selectedVideo: String
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .any(of: [.images,.videos])
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        private var parent: PhotoPicker
        
        init(_ parent: PhotoPicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false
            
            if let itemProvided = results.first?.itemProvider, itemProvided.canLoadObject(ofClass: UIImage.self) {
                itemProvided.loadObject(ofClass: UIImage.self) {[weak self] uiImage, error in
                    DispatchQueue.main.async {
                        guard let self = self, let uiImage = uiImage as? UIImage else {return}
                        self.parent.selectedImage = uiImage
                        self.parent.selectedVideo = ""
                    }
                }
            }
            
//            Video
            if let videoProvided = results.first?.itemProvider {
                videoProvided.loadItem(forTypeIdentifier: UTType.movie.identifier, options: [:]) { [self] (url, error) in
                    DispatchQueue.main.async {
                        guard let videoUrl = url as! URL? else {return}
                        self.parent.selectedVideo = videoUrl.path
                        self.parent.selectedImage = UIImage()
                    }
               }
            }
        }
    }
}
