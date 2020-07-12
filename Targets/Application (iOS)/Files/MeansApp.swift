//
// Copyright (c) Vatsal Manot
//

import API
import FoundationX
import LinkPresentation
import Network
import SwiftUIX

final class MediumRepository: HTTPRepository {
    public let session = HTTPSession()
    
    @UserDefault(key: "personalAccessToken")
    var personalAccessToken: String? {
        willSet {
            objectWillChange.send()
        }
    }
    
    public var interface: MediumAPI {
        .init(personalAccessToken: personalAccessToken)
    }
    
    @Resource(get: \.getUser)
    var user: MediumAPI.Resources.User?
    
    @Resource(get: \.getUserPublications, from: \.$user)
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
                if let result = Result(resource: repository.$publications) {
                    switch result {
                        case .success(let publications):
                            List(publications) { publication in
                                VStack(alignment: .leading) {
                                    Text(publication.name)
                                        .font(.body, weight: .semibold)
                                    
                                    Text(publication.description)
                                        .font(.body)
                                    
                                    LinkPresentationView(metadata: publication.metadata)
                                        .compact(true)
                                }
                            }
                        case .failure(let error):
                            Text("Error: \(error.localizedDescription)")
                    }
                } else {
                    ActivityIndicator()
                }
            }
            .navigationBarTitle("Publications")
            .onAppear {
                repository.$publications.fetchIfNecessary()
            }
        }
    }
}

struct UserView: View {
    @EnvironmentObject var repository: MediumRepository
    
    var body: some View {
        NavigationView {
            ZStack {
                if let result = Result(resource: repository.$user) {
                    switch result {
                        case .success(let user):
                            Form {
                                Section(header: "Info") {
                                    LabeledText(label: Text("Name"), content: Text(user.name))
                                    LabeledText(label: Text("Username"), content: Text(user.username))
                                }
                            }
                        case .failure(let error):
                            Text("Error: \(error.localizedDescription)")
                    }
                } else {
                    ActivityIndicator()
                }
            }
            .navigationBarTitle("Me")
            .onAppear {
                repository.$user.fetchIfNecessary()
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
