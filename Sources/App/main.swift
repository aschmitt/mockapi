import Vapor
import TLS
import HTTP
import Foundation

let drop = Droplet()

drop.get("*") { req in
    
    let filePathBase = "./Resources/JSON/GET/"
    var filePath = ""
    var fileName: String = "Default.json"
    var contents: String = ""
    let fileNameIndex: Int = 10
    let recordMode: Bool = false
    
    
    let requestURL = "\(req.uri)"
    
    /**
     Array: 0 -> http, 1 -> "", 2 -> apps.scout24.com, 3 -> acceskey, 4 - 9 -> mobilehub/as24/SERVICENAME/VERSION/COUNTRY/TYPE, 10 -> parameter
    */
    let urlArray: Array = requestURL.components(separatedBy: "/")
    
    for (index, element) in urlArray.enumerated() {
        if index >= 4 && index <= 9 {
            filePath += "\(element)/"
        }
    }
    
    if urlArray.indices.contains(fileNameIndex) && urlArray[fileNameIndex] != "" {
        //In order to avoid issues in the filesystem, replace & with %26
        fileName = urlArray[fileNameIndex].replacingOccurrences(of: "&", with: "%26")
    }
    
    do {
        //Read the file from the filesystem
        contents = try String(contentsOfFile: filePathBase+filePath+fileName, encoding: .utf8)
    }
    catch let error as Error {
        print("Ooops! Something went wrong: \(error)")
        
        if recordMode {
           //TODO: Find out how to bypass /etc/Host - maybe via IP and headers?
           let requestURLSSL = requestURL.replacingOccurrences(of: "http://", with: "https://secure.")
           let url = URL(string: requestURLSSL)
        
           let task = URLSession.shared.dataTask(with: url! as URL) { data, response, error in
               guard let data = data, error == nil else { return }
               print(NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? "N/A")
           }
           task.resume()
        }
    }
    
    let response = Response(status: .ok, body: contents)
    response.headers["Content-Type"] = "application/json"
    
    return response
}

let config = try TLS.Config(
    mode: .server,
    certificates: .files(
        certificateFile: "/Users/aschmitt/cert/servercert.pem",
        privateKeyFile: "/Users/aschmitt/cert/serverkey.pem",
        signature: .selfSigned
    ),
    verifyHost: true,
    verifyCertificates: true
)

drop.run(
    servers: [
        "plaintext": ("0.0.0.0", 80, .none),
        //"secure": ("0.0.0.0", 443, .tls(config)),
        ]
)
