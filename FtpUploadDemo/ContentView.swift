//
//  ContentView.swift
//  FtpUploadDemo
//
//  Created by Kinh Thu on 6/16/21.
//

import SwiftUI
import AMSMB2

class SMBClient {
//    SMB sharing
    let serverURL = URL(string: "smb://192.168.1.53")!
    let credential = URLCredential(user: "kinhthu", password: "lamgico", persistence: URLCredential.Persistence.forSession)
    let shareDirectory = "FTP Sharing"
    
    lazy public var client = AMSMB2(url: self.serverURL, credential: self.credential)!
    
    func connect(handler: @escaping (Result<AMSMB2, Error>) -> Void) {
        // AMSMB2 can handle queueing connection requests
        client.connectShare(name: self.shareDirectory) { error in
            if let error = error {
                handler(.failure(error))
            } else {
                handler(.success(self.client))
            }
        }
    }
}

struct ContentView: View {
    @State private var smbClient = SMBClient()
    
//    azure blob storage
    private let containerName = "test1"
    private let connectionString = "DefaultEndpointsProtocol=http;AccountName=decedgeblob;AccountKey=M8iTCobWP4TtUZf8RcVlNEnecSU5tD7gKe2RjYMZlZMonGXF6THLpfyUyekD2yTXZH5owub1AbU2M5RMq9W6UA==;BlobEndpoint=http://edge-sample-iot-device.australiaeast.cloudapp.azure.com:11002/decedgeblob"
    
    @State var blobContainer: AZSCloudBlobContainer?
    
    func initBlobStorage() -> AZSCloudBlobContainer {
        var container:AZSCloudBlobContainer? = nil
        do {
            let account = try AZSCloudStorageAccount(fromConnectionString: self.connectionString)
            let blobClient = account.getBlobClient()
            container  = blobClient.containerReference(fromName: self.containerName)
        } catch {
            print(error)
        }
        return container!
    }
    
    init() {
        let container = initBlobStorage()
        _blobContainer = State(initialValue: container)
    }
    
    var body: some View {
        TabView {
            VideoView()
                .tabItem {
                    Label("Library", systemImage: "video.fill")
                }
            UploadView(smbClient: self.$smbClient, blobContainer: $blobContainer)
                .tabItem {
                Label("Upload", systemImage: "icloud.and.arrow.up.fill")
            }

            LibraryView(smbClient: self.$smbClient)
                .tabItem {
                    Label("Library", systemImage: "tray.2.fill")
                }
        }.onAppear(perform: {
            smbClient.connect { result in
                switch result {
                case .success(let _):
                    print("Connect successful")

                case .failure(let error):
                    print(error)
                }
            }
        })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
