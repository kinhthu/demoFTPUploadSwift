import SwiftUI
import AVFoundation
import AVKit

struct UploadView: View {
    @Binding var smbClient: SMBClient
    @Binding var blobContainer: AZSCloudBlobContainer?
    
    @State var isShowingImagePicker = false
    @State var selectedImage = UIImage()
    @State var selectedVideoUrl = ""
    @State var uploading = false
    @State var updateSuccess = false
    @State var error = ""
    @State var uploadTime: Double = 0
    @State var progress = ""
    
    @ObservedObject var mediaItems = PickedMediaItems()
    
    var isHeicSupported: Bool {
        (CGImageDestinationCopyTypeIdentifiers() as! [String]).contains("public.heic")
    }
    
    func clearFile() {
        self.selectedImage = UIImage()
        self.selectedVideoUrl = ""
        self.uploadTime = 0
        self.uploading = false
    }
    
    func getThumbnailImage(forUrl url: URL) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)

        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60) , actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            print(error)
        }

        return nil
    }
    
    func getPreviewImage() -> UIImage {
        if(self.selectedVideoUrl != "") {
            let url = URL(fileURLWithPath: self.selectedVideoUrl)
            return getThumbnailImage(forUrl: url)!
        }
        return self.selectedImage
    }
    
    func uploadFile() {
        self.updateSuccess = false
        self.uploadTime = 0
        let item = mediaItems.items[0]
        
        do {
            print("upload video: \(item.url!)")
            let start = DispatchTime.now()
            self.uploading.toggle()
                let mediaData = try Data(contentsOf: item.url!, options: .alwaysMapped)
                let theFileName = (item.url!.path as NSString).lastPathComponent
                
                smbClient.client.uploadItem(at: item.url!, toPath: "/\(theFileName)") { size in
                    progress = size == 0 ? "100%" : "\((Int(size)*100/mediaData.count))%"
                    return true
                } completionHandler: { _ in
                    print("Uploaded Successfully!")
                    clearFile()
                    self.updateSuccess = true

                    let end = DispatchTime.now()
                    let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                    let timeInterval = Double(nanoTime)
                    self.uploadTime = timeInterval/1000000000
                }
         } catch let error {
           print(error)
         }
    }
    
    func uploadFileToBlob() {
        self.updateSuccess = false
        self.uploadTime = 0
        let item = mediaItems.items[0]
        
        do {
            print("upload video: \(item.url!)")
            let start = DispatchTime.now()
            self.uploading.toggle()
                let mediaData = try Data(contentsOf: item.url!, options: .alwaysMapped)
                let theFileName = (item.url!.path as NSString).lastPathComponent
                
                let blob = blobContainer?.blockBlobReference(fromName: theFileName)
                blob?.uploadFromFile(with: item.url!, completionHandler: { _ in
                print("Uploaded Successfully!")
                clearFile()
                self.updateSuccess = true

                let end = DispatchTime.now()
                let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
                let timeInterval = Double(nanoTime)
                self.uploadTime = timeInterval/1000000000
            })
         } catch let error {
           print(error)
         }
    }
    
    var body: some View {
        VStack {
            List(mediaItems.items, id: \.id) { item in
                ZStack(alignment: .topLeading) {
                    if item.mediaType == .photo {
                        Image(uiImage: getImageData(url: item.url!))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } else if item.mediaType == .video {
                        if let url = item.url {
                            VideoPlayer(player: AVPlayer(url: url))
                                .frame(minHeight: 200)
                        } else { EmptyView() }
                    } else {
                        Image(uiImage: getImageData(url: item.url!))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }

                    Image(systemName: getMediaImageName(using: item))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .padding(4)
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                }
            }
            
            Button(action: {
                self.isShowingImagePicker.toggle()
            }, label: {
                Text("Select Photo")
            })
            .disabled(self.uploading)
            .sheet(isPresented: $isShowingImagePicker, content: {
//                ImagePickerView(isPresented: self.$isShowingImagePicker, selectedImage: self.$selectedImage, selectedVideo: self.$selectedVideoUrl)
//                PhotoPicker(isPresented: self.$isShowingImagePicker, selectedImage: self.$selectedImage, selectedVideo: self.$selectedVideoUrl)
                PhotoPicker(isOnlyVideo: false, mediaItems: mediaItems) { didSelectItem in
                    // Handle didSelectItems value here...
                    self.isShowingImagePicker = false
                }
            })
            
            Button(action: {
                if (!self.uploading) {
//                    uploadFile()
                    uploadFileToBlob()
                }

            }, label: {
                Text(self.uploading ? "Uploading \(progress)..." : "Upload")
            })
            .padding(.vertical)
            .disabled(mediaItems.items.count == 0)
            
            if(self.uploadTime > 0) {
                Text("Time upload: \(self.uploadTime) seconds")
            }
            
            Text(self.error)
                .foregroundColor(Color.red)
                .multilineTextAlignment(.center)
            if (self.updateSuccess == true && self.selectedImage.ciImage == nil && self.selectedImage.cgImage == nil) {
                Text("Uploaded successfully!")
            }
        }
    }
    
    fileprivate func getMediaImageName(using item: PhotoPickerModel) -> String {
        switch item.mediaType {
            case .photo: return "photo"
            case .video: return "video"
            case .livePhoto: return "livephoto"
        }
    }
    
    func getImageData(url: URL) -> UIImage {
        let data = try? Data(contentsOf: url)
        return UIImage(data: data!)!
    }
}
extension UIImage {
    var heic: Data? { heic() }
    func heic(compressionQuality: CGFloat = 1) -> Data? {
        guard
            let mutableData = CFDataCreateMutable(nil, 0),
            let destination = CGImageDestinationCreateWithData(mutableData, "public.heic" as CFString, 1, nil),
            let cgImage = cgImage
        else { return nil }
        CGImageDestinationAddImage(destination, cgImage, [kCGImageDestinationLossyCompressionQuality: compressionQuality, kCGImagePropertyOrientation: cgImageOrientation.rawValue] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}
extension CGImagePropertyOrientation {
    init(_ uiOrientation: UIImage.Orientation) {
        switch uiOrientation {
            case .up: self = .up
            case .upMirrored: self = .upMirrored
            case .down: self = .down
            case .downMirrored: self = .downMirrored
            case .left: self = .left
            case .leftMirrored: self = .leftMirrored
            case .right: self = .right
            case .rightMirrored: self = .rightMirrored
        @unknown default:
            fatalError()
        }
    }
}
extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation { .init(imageOrientation) }
}
