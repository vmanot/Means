//
// Copyright (c) Vatsal Manot
//

import API
import Network
import SwiftUIX

final class MediumRepository: HTTPRepository<MediumAPI> {
    @Resource(get: \.getUser)
    var user: MediumAPI.Resources.User?
    
    @Resource(get: \.getUserPublications, from: \.$user)
    var publications: [MediumAPI.Resources.Publication]?
    
    init() {
        super.init(interface: .init(), session: .init())
        
        self.user = nil
        self.publications = nil
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

struct ContentView: View {
    @EnvironmentObject var repository: MediumRepository
    
    var body: some View {
        NavigationView {
            VStack {
                if let result = Result(resource: repository.$user) {
                    switch result {
                        case .success(let user):
                            Text("Success")
                        case .failure:
                            Text("Failure")
                    }
                } else {
                    VStack {
                        ActivityIndicator()
                        
                        Button(action: repository.$user.refresh) {
                            Text("Refresh")
                        }
                    }
                }
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
                        text: $repository
                            .interface
                            .personalAccessToken
                            .withDefaultValue("")
                    )
                    .textContentType(.password)
                }
            }
            .navigationBarTitle("Settings", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    DismissPresentationButton {
                        Text("Done")
                    }
                }
            }
        }
    }
}
