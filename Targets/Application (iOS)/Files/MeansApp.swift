//
// Copyright (c) Vatsal Manot
//

import API
import FoundationX
import LinkPresentation
import NetworkKit
import ObjectiveC
import SwiftUIX
import Swallow

final class MediumRepository: HTTPRepository {
    public let session = HTTPSession()
     
    public var interface: MediumAPI {
        .init(personalAccessToken: personalAccessToken)
    }
    
    @UserDefault.Published("personalAccessToken")
    var personalAccessToken: String?
    
    @Resource(get: \.getUser)
    var user: MediumAPI.Resources.User?
    
    @Resource(get: \.getUserPublications, from: { try .init(from: $0.user.unwrap()) })
    var publications: [MediumAPI.Resources.Publication]?
    
    init() {
        user = nil
        publications = nil
    }
}

@main
struct MeansApp: App {
    @StateObject var repository = MediumRepository()
    
    @SceneBuilder
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(repository)
        }
    }
}

public struct LabeledText: View {
    public let label: Text
    public let content: Text
    
    public init(label: Text, content: Text) {
        self.label = label
        self.content = content
    }
    
    public var body: some View {
        HStack {
            label.fixedSize()
            
            Spacer()
            
            content.fixedSize()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var repository: MediumRepository
    
    var body: some View {
        TabView {
            PublicationsView().tabItem {
                Label("Publications", systemImage: "list.bullet.rectangle")
            }
            
            UserView().tabItem {
                Label("User", systemImage: .personFill)
            }
            
            SettingsView().tabItem {
                Label("Settings", systemImage: .gear)
            }
        }
    }
}

struct PublicationsView: View {
    @EnvironmentObject var repository: MediumRepository
    
    var body: some View {
        NavigationView {
            ZStack {
                ResourceView(repository.$publications) { publications in
                    List(publications) { publication in
                        VStack(alignment: .leading) {
                            Text(publication.name)
                                .font(.body, weight: .semibold)
                            
                            Text(publication.description)
                                .font(.body)
                            
                            LinkPresentationView(metadata: publication.metadata)
                                .disableMetadataFetch(true)
                        }
                    }
                } failure: { error in
                    Text("Error: \(error.localizedDescription)")
                } placeholder: {
                    ActivityIndicator()
                }
            }
            .navigationBarTitle("Publications")
            .onAppear {
                if repository.publications == nil {
                    repository.$publications.fetch()
                }
            }
        }
    }
}

struct UserView: View {
    @EnvironmentObject var repository: MediumRepository
    
    var body: some View {
        NavigationView {
            ZStack {
                ResourceView(repository.$user) { user in
                    Form {
                        Section(header: "Info") {
                            LabeledText(label: Text("Name"), content: Text(user.name))
                            LabeledText(label: Text("Username"), content: Text(user.username))
                        }
                    }
                } failure: { error in
                    Text("Error: \(error.localizedDescription)")
                } placeholder: {
                    ActivityIndicator()
                }
            }
            .navigationBarTitle("Me")
            .onAppear {
                repository.$user.fetch()
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var repository: MediumRepository
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Access Token")) {
                    SecureField(
                        "Enter your token here...",
                        text: $repository.personalAccessToken
                    )
                    .textContentType(.password)
                }
            }
            .navigationBarTitle("Settings")
        }
    }
}
