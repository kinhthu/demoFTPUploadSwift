//
//  ContentView.swift
//  FtpUploadDemo
//
//  Created by Kinh Thu on 6/16/21.
//

import SwiftUI
import AMSMB2

class SMBClient {
    
    let serverURL = URL(string: "smb://192.168.1.53")!
    let credential = URLCredential(user: "aaa", password: "abc", persistence: URLCredential.Persistence.forSession)
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
    
    var body: some View {
        TabView {
            UploadView(smbClient: self.$smbClient)
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
