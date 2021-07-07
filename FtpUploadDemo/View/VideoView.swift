//
//  VideoView.swift
//  FtpUploadDemo
//
//  Created by Kinh Thu on 7/7/21.
//

import SwiftUI
import AVFoundation
import AVKit
import Photos

struct VideoView: View {
    @State var text: String = ""
    @State var isShowingImagePicker = false
    @State var isShowLoading = false
    @State var savedUrl: URL?
    @State var timing: Double = 0
    @State var savedText = ""
    @State var isSaving = false
    @ObservedObject var mediaItems = PickedMediaItems()
    private let editor = VideoEditor()
    
    func clear() {
        timing = 0
        savedUrl = nil
        savedText = ""
    }
    
    private func saveVideoToPhotos() {
        savedText = "Saving ..."
        
        let start = DispatchTime.now()
      PHPhotoLibrary.shared().performChanges( {
        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: savedUrl!)
      }) {(isSaved, error) in
        if isSaved {
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanoTime)
            let duration = timeInterval/1000000000
            
            savedText = "Saved file takes \(duration)s"
        } else {
            savedText = "Cannot save video."
          print(error ?? "unknown error")
        }
      }
    }
    
    func startEdit() {
        isShowLoading.toggle()
        let start = DispatchTime.now()
        editor.editVideo(fromVideoAt: mediaItems.items[0].url!, forText: text) { exportedURL in
            isShowLoading.toggle()
            guard let exportedURL = exportedURL else {
              return
            }
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanoTime)
            self.timing = timeInterval/1000000000
            
            self.savedUrl = exportedURL
          }
    }
    
    var body: some View {
        VStack{
            if mediaItems.items.count > 0 && mediaItems.items[0].mediaType == .video {
                if let url = mediaItems.items[0].url {
                    VideoPlayer(player: AVPlayer(url: url))
                        .frame(minHeight: 200)
                } else { EmptyView() }
            }
                
            TextField("Caption", text: $text)
                .padding()
                .border(/*@START_MENU_TOKEN@*/Color.black/*@END_MENU_TOKEN@*/)
                .foregroundColor(.black)
                .background(Color.white)
            
            if isShowLoading {
                Text("Redering...")
            }
            
            if !isShowLoading && timing > 0 {
                Text("Render time: \(timing)s")
            }
            
            Button(action: {
                isShowingImagePicker.toggle()
                clear()
            }, label: {
                Text("Browse")
            })
            .padding()
            
            if mediaItems.items.count > 0 && !isShowLoading {
                Button(action: {
                    startEdit()
                }, label: {
                    Text("Start")
                })
            }
            
            if savedUrl != nil {
                VStack{
                    HStack{
                        Text("Rendered Video")
                        Button(action: {
                            saveVideoToPhotos()
                        }, label: {
                            Text("Save")
                        })
                        .padding()
                    }
                    Text(savedText)
                    VideoPlayer(player: AVPlayer(url: savedUrl!))
                        .frame(minHeight: 200)
                }
            }
        }
        .padding()
        .sheet(isPresented: $isShowingImagePicker, content: {
            PhotoPicker(isOnlyVideo: true, mediaItems: mediaItems) { didSelectItem in
                // Handle didSelectItems value here...
                self.isShowingImagePicker = false
            }
        })
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}
