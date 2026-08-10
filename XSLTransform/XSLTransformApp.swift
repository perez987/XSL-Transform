import SwiftUI

@main
struct XSLTransformApp: App {
    
    @State private var isLanguageSelectorPresented = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .sheet(isPresented: $isLanguageSelectorPresented) {
                    LanguageSelectorView()
                }
        }
                .windowStyle(.hiddenTitleBar)
                .windowResizability(.contentSize)
            
                .commands {
                    // Language menu
                    CommandGroup(replacing: .newItem) { }
                    CommandMenu(NSLocalizedString("menu_language", comment: "Language menu")) {
                        Button(NSLocalizedString("menu_select_language", comment: "Select Language menu item")) {
                            isLanguageSelectorPresented = true
                        }
                        .keyboardShortcut("l", modifiers: .command)
                    }
                }
        }
}
