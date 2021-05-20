//
// Copyright (c) Vatsal Manot
//

import Foundation
import LinkPresentation
import NetworkKit
import Swallow

public struct MediumAPI: RESTfulHTTPInterface {
    public struct Resources {
        
    }
    
    public struct Requests {
        
    }
    
    public let host = URL(string: "https://api.medium.com/v1")!
    public let getUser = Endpoint(Requests.GetUser.self)
    public let getUserPublications = Endpoint(Requests.GetUserPublications.self)
    
    public var personalAccessToken: String?
    
    public var id: AnyHashable {
        personalAccessToken
    }
}

extension MediumAPI {
    public final class Endpoint<Input: HTTPRequestPopulator, Output: Decodable>: BaseHTTPEndpoint<MediumAPI, Input, Output, Void> {
        override public func buildRequestBase(
            from input: Input,
            context: BuildRequestContext
        ) throws -> HTTPRequest {
            try super
                .buildRequestBase(from: input, context: context)
                .header(.authorization(.bearer, try context.root.personalAccessToken.unwrap()))
                .header(.contentType(.json))
        }
        
        override public func decodeOutputBase(
            from response: HTTPResponse,
            context: DecodeOutputContext
        ) throws -> Output {
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
    public struct User: Codable, Identifiable {
        public let id: String
        public let username: String
        public let name: String
        public let url: URL
        public let imageURL: URL?
    }
    
    public struct Publication: Codable, Identifiable {
        public let id: String
        public let name: String
        public let description: String
        public let url: URL
        public let imageURL: URL?
        
        public var metadata: LPLinkMetadata {
            let result = LPLinkMetadata()
            
            result.originalURL = url
            result.title = name
            
            return result
        }
    }
}

extension MediumAPI.Requests {
    public struct GetUser: EndpointDescriptor {
        public struct Input: HTTPRequestPopulator, Initiable {
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
        public struct Input: HTTPRequestPopulator {
            public let userID: String
            
            public init(userID: String) {
                self.userID = userID
            }
            
            public init(from user: MediumAPI.Resources.User) throws {
                self.init(userID: user.id)
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
