//
// Copyright (c) Vatsal Manot
//

import API
import Combine
import Merge
import Network
import Swallow
import SwiftUIX

public struct MediumAPI: RESTfulHTTPInterface {
    public struct Resources { }
    public struct Requests { }
    
    public let host = URL(string: "https://api.medium.com/v1")!
    public let getUser = Endpoint(Requests.GetUser.self)
    public let getUserPublications = Endpoint(Requests.GetUserPublications.self)
    
    public var personalAccessToken: String?
    
    public var id: AnyHashable {
        .init(personalAccessToken)
    }
}

extension MediumAPI {
    public final class Endpoint<Input: HTTPRequestDescriptor, Output: Decodable>: BaseHTTPEndpoint<Input, Output, MediumAPI> {
        override public func buildRequest(for root: Root, from input: Input) throws -> HTTPRequest {
            try super
                .buildRequest(for: root, from: input)
                .header(.authorization(.bearer, try root.personalAccessToken.unwrap()))
                .header(.contentType(.json))
        }
        
        override public func decodeOutput(from response: HTTPResponse) throws -> Output {
            try response.validate()
            
            return try JSONDecoder().decode(OutputWrapper.self, from: response.data).data
        }
    }
    
    /// Needed because Medium wraps all responses in a `{ data: ... }`.
    private struct OutputWrapper<Output: Decodable>: Decodable {
        var data: Output
    }
}

extension MediumAPI.Resources {
    public struct User: Identifiable, RESTfulResource {
        public let id: String
        public let username: String
        public let name: String
        public let url: URL
        public let imageURL: URL?
    }
    
    public struct Publication: Identifiable, RESTfulResource {
        public let id: String
        public let name: String
        public let description: String
        public let url: URL
        public let imageURL: URL?
    }
}

extension MediumAPI.Requests {
    public struct GetUser: EndpointDescriptor {
        public struct Input: HTTPRequestDescriptor, Initiable {
            public init() {
                
            }
            
            public func populate(_ request: HTTPRequest) -> HTTPRequest {
                request
                    .path("/me")
                    .method(.get)
            }
        }
        
        public typealias Output = MediumAPI.Resources.User
    }
    
    public struct GetUserPublications: EndpointDescriptor {
        public struct Input: HTTPRequestDescriptor, RESTfulResourceConstructible {
            public let userID: String
            
            public init(userID: String) {
                self.userID = userID
            }
            
            public init(from resource: MediumAPI.Resources.User) throws {
                self.init(userID: resource.id)
            }
            
            public func populate(_ request: HTTPRequest) -> HTTPRequest {
                request
                    .path("/users/\(userID)/publications")
                    .method(.get)
            }
        }
        
        public typealias Output = [MediumAPI.Resources.Publication]
    }
}
