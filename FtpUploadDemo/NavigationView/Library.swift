import SwiftUI
import AMSMB2

struct LibraryView: View {
    @Binding var smbClient: SMBClient
    
    var body: some View {
        VStack{
            
        }.onAppear(perform: {
            smbClient.client.contentsOfDirectory(atPath: "/") { result in
                switch result {
                case .success(let files):
                    for entry in files {
                        print("name:", entry[.nameKey] as! String,
                              ", path:", entry[.pathKey] as! String,
                              ", type:", entry[.fileResourceTypeKey] as! URLFileResourceType,
                              ", size:", entry[.fileSizeKey] as! Int64,
                              ", modified:", entry[.contentModificationDateKey] as! Date,
                              ", created:", entry[.creationDateKey] as! Date)
                    }
                    
                case .failure(let error):
                    print(error)
                }
            }
        })
    }
}
