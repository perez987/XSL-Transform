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
    
    let transformer = XSLTransformer()
    
    init() {
        // Set default output path to Desktop
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
            
            // Transform Button
            Button(action: performTransformation) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                            .padding(.trailing, 5)
                    }
                    Text(isProcessing ? NSLocalizedString("button.transforming", comment: "") : NSLocalizedString("button.transform", comment: ""))
                        .fontWeight(.semibold)
                }
                .frame(minWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(xmlFilePath.isEmpty || xslFilePath.isEmpty || outputFilePath.isEmpty || isProcessing)
            
            // Status Message
            if !transformationStatus.isEmpty {
                Text(transformationStatus)
                    .foregroundColor(transformationSucceeded ? .green : .primary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .frame(
            minWidth: 600,
            idealWidth: 600,
            maxWidth: 600,
            minHeight: 500,
            idealHeight: 500,
            maxHeight: 500
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
        
        // Set directory to Desktop by default
        if let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            panel.directoryURL = desktopURL
        }
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                outputFilePath = url.path(percentEncoded: false)
                transformationStatus = NSLocalizedString("status.output.selected", comment: "")
                transformationSucceeded = false
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
                    
                    // Open the generated HTML file
                    NSWorkspace.shared.open(URL(fileURLWithPath: outputFilePath))
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
