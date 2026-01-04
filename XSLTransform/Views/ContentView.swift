import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @State private var xmlFilePath: String = ""
    @State private var xslFilePath: String = ""
    @State private var outputFilePath: String = ""
    @State private var transformationStatus: String = ""
    @State private var isProcessing: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var transformationSucceeded: Bool = false
    @AppStorage("replaceExistingHTML") private var replaceExistingHTML: Bool = false
    @AppStorage("useDesktopAsDefault") private var useDesktopAsDefault: Bool = false
    @AppStorage("openAfterCreation") private var openAfterCreation: Bool = true
    
    let transformer = XSLTransformer()
    
    init() {
        // Load saved output path if "Replace existing HTML file" is enabled
        if UserDefaults.standard.bool(forKey: "replaceExistingHTML") {
            if let savedOutputPath = UserDefaults.standard.string(forKey: "savedOutputPath"),
               !savedOutputPath.isEmpty {
                _outputFilePath = State(initialValue: savedOutputPath)
                return
            }
        }
        
        // Otherwise, set default output path to Desktop
        if let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            let defaultOutputURL = desktopURL.appendingPathComponent("Empresas.html")
            _outputFilePath = State(initialValue: defaultOutputURL.path(percentEncoded: false))
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(NSLocalizedString("app.title", comment: ""))
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text(NSLocalizedString("app.subtitle", comment: ""))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
            
            // XML File Selection
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("xml.label", comment: ""))
                    .fontWeight(.semibold)
                HStack {
                    Text(xmlFilePath.isEmpty ? NSLocalizedString("no.file.selected", comment: "") : URL(fileURLWithPath: xmlFilePath).lastPathComponent)
                        .foregroundColor(xmlFilePath.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                    
                    Button(NSLocalizedString("button.browse", comment: "")) {
                        selectFile(type: .xml)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(NSLocalizedString("button.use.sample", comment: "")) {
                        useDefaultXML()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)
            
            // XSL File Selection
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("xsl.label", comment: ""))
                    .fontWeight(.semibold)
                HStack {
                    Text(xslFilePath.isEmpty ? NSLocalizedString("no.file.selected", comment: "") : URL(fileURLWithPath: xslFilePath).lastPathComponent)
                        .foregroundColor(xslFilePath.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                    
                    Button(NSLocalizedString("button.browse", comment: "")) {
                        selectFile(type: .xsl)
                    }
                    .buttonStyle(.bordered)
                    
                    Button(NSLocalizedString("button.use.sample", comment: "")) {
                        useDefaultXSL()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)
            
            // Output File Selection
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("output.label", comment: ""))
                    .fontWeight(.semibold)
                HStack {
                    Text(outputFilePath.isEmpty ? NSLocalizedString("no.file.selected", comment: "") : URL(fileURLWithPath: outputFilePath).lastPathComponent)
                        .foregroundColor(outputFilePath.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(5)
                    
                    Button(NSLocalizedString("button.save.as", comment: "")) {
                        selectOutputFile()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal)
            
            Divider()
            
            /// Transform button
            
            // Transform Button option 1: hidden ProgressView, swapping text Transform / Transforming
//            Button(action: performTransformation) {
//                HStack(spacing: 5) {
//                    // Always reserve space for ProgressView to prevent layout shifts
//                    ProgressView()
//                        .scaleEffect(0.8)
//                        .opacity(isProcessing ? 1 : 0)
//                        .accessibilityHidden(!isProcessing)
//                    Text(isProcessing ? NSLocalizedString("button.transforming", comment: "") : NSLocalizedString("button.transform", comment: ""))
//                        .fontWeight(.semibold)
//                }
//                .frame(minWidth: 200)
//            }
//            .buttonStyle(.borderedProminent)
//            .controlSize(.large)
//            .disabled(xmlFilePath.isEmpty || xslFilePath.isEmpty || outputFilePath.isEmpty || isProcessing)
//            .animation(.none, value: isProcessing)

            // Transform Button option 2: no ProgressView, simple button with text and action
            Button(action: performTransformation) {
                Text(NSLocalizedString("button.transform", comment: ""))
                    .frame(width: 120, height: 28)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(xmlFilePath.isEmpty || xslFilePath.isEmpty || outputFilePath.isEmpty)
            .frame(minWidth: 200)
            
            // Status Message
            ZStack {
                Color.gray.opacity(0.1)
                Text(transformationStatus)
                    .foregroundColor(transformationSucceeded ? .green : .primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .cornerRadius(8)
            .padding(.horizontal)
            .animation(.none, value: transformationStatus)
            .animation(.none, value: transformationSucceeded)
                        
            // Footer with settings
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Toggle(NSLocalizedString("settings.replace.html", comment: ""), isOn: $replaceExistingHTML)
                    .onChange(of: replaceExistingHTML) { oldValue, newValue in
                        if newValue && !outputFilePath.isEmpty {
                            // Save current output path when enabling
                            UserDefaults.standard.set(outputFilePath, forKey: "savedOutputPath")
                        } else {
                            // Clear saved output path when disabling
                            UserDefaults.standard.removeObject(forKey: "savedOutputPath")
                        }
                    }
                
                Toggle(NSLocalizedString("settings.desktop.default", comment: ""), isOn: $useDesktopAsDefault)
                
                Toggle(NSLocalizedString("settings.open.after.creation", comment: ""), isOn: $openAfterCreation)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
        .frame(
            minWidth: 600,
            idealWidth: 600,
            maxWidth: 600,
            minHeight: 600,
            idealHeight: 600,
            maxHeight: 600
        )
        .padding()
        .alert(NSLocalizedString("error.title", comment: ""), isPresented: $showError) {
            Button(NSLocalizedString("button.ok", comment: ""), role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    func useDefaultXML() {
        if let resourcePath = Bundle.main.path(forResource: "Empresas", ofType: "xml") {
            xmlFilePath = resourcePath
            transformationStatus = NSLocalizedString("status.sample.xml.loaded", comment: "")
            transformationSucceeded = false
        } else {
            errorMessage = NSLocalizedString("error.sample.xml.not.found", comment: "")
            showError = true
        }
    }
    
    func useDefaultXSL() {
        if let resourcePath = Bundle.main.path(forResource: "Empresas", ofType: "xsl") {
            xslFilePath = resourcePath
            transformationStatus = NSLocalizedString("status.sample.xsl.loaded", comment: "")
            transformationSucceeded = false
        } else {
            errorMessage = NSLocalizedString("error.sample.xsl.not.found", comment: "")
            showError = true
        }
    }
    
    func selectFile(type: FileType) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        switch type {
        case .xml:
            panel.allowedContentTypes = [UTType.xml]
            panel.message = NSLocalizedString("dialog.select.xml", comment: "")
        case .xsl:
            panel.allowedContentTypes = [UTType(filenameExtension: "xsl")!]
            panel.message = NSLocalizedString("dialog.select.xsl", comment: "")
        }
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                switch type {
                case .xml:
                    xmlFilePath = url.path(percentEncoded: false)
                    transformationStatus = NSLocalizedString("status.xml.selected", comment: "")
                case .xsl:
                    xslFilePath = url.path(percentEncoded: false)
                    transformationStatus = NSLocalizedString("status.xsl.selected", comment: "")
                }
                transformationSucceeded = false
            }
        }
    }
    
    func selectOutputFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.html]
        panel.nameFieldStringValue = "Empresas.html"
        panel.message = NSLocalizedString("dialog.save.html", comment: "")
        
        // Set directory to Desktop by default if the option is enabled
        if useDesktopAsDefault {
            if let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
                panel.directoryURL = desktopURL
            }
        }
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                outputFilePath = url.path(percentEncoded: false)
                transformationStatus = NSLocalizedString("status.output.selected", comment: "")
                transformationSucceeded = false
                
                // Save the output path if "Replace existing HTML file" is enabled
                if replaceExistingHTML {
                    UserDefaults.standard.set(outputFilePath, forKey: "savedOutputPath")
                }
            }
        }
    }
    
    func performTransformation() {
        isProcessing = true
        transformationStatus = NSLocalizedString("status.transforming", comment: "")
        transformationSucceeded = false
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try transformer.transform(
                    xmlPath: xmlFilePath,
                    xslPath: xslFilePath,
                    outputPath: outputFilePath
                )
                
                DispatchQueue.main.async {
                    isProcessing = false
                    transformationStatus = String(format: NSLocalizedString("status.success", comment: ""), outputFilePath)
                    transformationSucceeded = true
                    
                    // Open the generated HTML file only if the setting is enabled
                    if openAfterCreation {
                        NSWorkspace.shared.open(URL(fileURLWithPath: outputFilePath))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    isProcessing = false
                    errorMessage = error.localizedDescription
                    showError = true
                    transformationStatus = NSLocalizedString("status.failed", comment: "")
                    transformationSucceeded = false
                }
            }
        }
    }
    
    enum FileType {
        case xml
        case xsl
    }
}

#Preview {
    ContentView()
}
