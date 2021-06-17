import SwiftUI
import AVFoundation

struct UploadView: View {
    @Binding var smbClient: SMBClient
    
    @State var isShowingImagePicker = false
    @State var selectedImage = UIImage()
    @State var selectedVideoUrl = ""
    @State var uploading = false
    @State var updateSuccess = false
    @State var error = ""
    @State var uploadTime: Double = 0
    @State var progress = ""
    
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
        
        if (self.selectedVideoUrl != "") {
            let url = URL(fileURLWithPath: self.selectedVideoUrl)

            do {
                let start = DispatchTime.now()
                self.uploading.toggle()
                let videoData = try Data(contentsOf: url, options: .alwaysMapped)
                let theFileName = (self.selectedVideoUrl as NSString).lastPathComponent
                smbClient.client.uploadItem(at: url, toPath: "/\(theFileName)") { size in
                    progress = "\(size)/\(videoData.count)"
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
        } else {
            if let imgData = self.selectedImage.pngData() as NSData? {
                self.uploading.toggle()

                let start = DispatchTime.now()
                
                let currentDate = Date()
                let fileName = String(currentDate.timeIntervalSinceReferenceDate) + ".jpg"
                
                smbClient.client.write(data: imgData, toPath: "/\(fileName)") { size in
                    progress = "\(size)/\(imgData.count)"
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
            }
        }
    }
    
    var body: some View {
        VStack{
            Image(uiImage: getPreviewImage())
                .resizable()
                .scaledToFill()
                .frame(width: .infinity, height: 400, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
                .clipped()
            
            Button(action: {
                self.isShowingImagePicker.toggle()
            }, label: {
                Text("Select Photo")
            })
            .disabled(self.uploading)
//            .padding(.vertical)
            .sheet(isPresented: $isShowingImagePicker, content: {
//                ImagePickerView(isPresented: self.$isShowingImagePicker, selectedImage: self.$selectedImage, selectedVideo: self.$selectedVideoUrl)
                PhotoPicker(isPresented: self.$isShowingImagePicker, selectedImage: self.$selectedImage, selectedVideo: self.$selectedVideoUrl)
            })
            
            Button(action: {
                if (!self.uploading) {
                    uploadFile()
                }

            }, label: {
                Text(self.uploading ? "Uploading \(progress)..." : "Upload")
            })
            .padding(.vertical)
            .disabled(self.selectedImage.ciImage == nil && self.selectedImage.cgImage == nil && self.selectedVideoUrl == "")
            
            Text(selectedVideoUrl)
            
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
}
