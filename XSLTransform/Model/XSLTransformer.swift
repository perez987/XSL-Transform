import Foundation

class XSLTransformer {
    enum TransformError: LocalizedError {
        case invalidXMLFile
        case invalidXSLFile
        case transformationFailed
        case fileWriteFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidXMLFile:
                return NSLocalizedString("error.invalid.xml", comment: "")
            case .invalidXSLFile:
                return NSLocalizedString("error.invalid.xsl", comment: "")
            case .transformationFailed:
                return NSLocalizedString("error.transformation.failed", comment: "")
            case .fileWriteFailed:
                return NSLocalizedString("error.file.write.failed", comment: "")
            }
        }
    }
    
    func transform(xmlPath: String, xslPath: String, outputPath: String) throws {
        // Load XML document
        let xmlData: Data
        let xmlDoc: XMLDocument
        
        do {
            xmlData = try Data(contentsOf: URL(fileURLWithPath: xmlPath))
            // Use .documentTidyXML option for better XSLT compatibility
            xmlDoc = try XMLDocument(data: xmlData, options: [.documentTidyXML])
        } catch {
            throw TransformError.invalidXMLFile
        }
        
        // Load XSL stylesheet
        let xslData: Data
        let xslDoc: XMLDocument
        
        do {
            xslData = try Data(contentsOf: URL(fileURLWithPath: xslPath))
            xslDoc = try XMLDocument(data: xslData, options: [])
        } catch {
            throw TransformError.invalidXSLFile
        }
        
        // Validate XSL document has content
        guard xslDoc.rootElement() != nil else {
            throw TransformError.invalidXSLFile
        }
        
        // Perform transformation with explicit error handling
        let resultData: Any
        do {
            resultData = try xmlDoc.object(byApplyingXSLT: xslData, arguments: nil)
        } catch let error as NSError {
            // Log the actual error for debugging
            print("XSLT transformation error: \(error.localizedDescription)")
            throw TransformError.transformationFailed
        }
        
        // Convert result to string with proper HTML handling
        let htmlString: String
        if let resultXMLDoc = resultData as? XMLDocument {
            // Use xmlString(options:) with proper HTML output options
            htmlString = resultXMLDoc.xmlString(options: [.nodeCompactEmptyElement])
        } else if let resultString = resultData as? String {
            htmlString = resultString
        } else if let resultDataObj = resultData as? Data {
            guard let decodedString = String(data: resultDataObj, encoding: .utf8) else {
                throw TransformError.transformationFailed
            }
            htmlString = decodedString
        } else {
            throw TransformError.transformationFailed
        }
        
        // Write to output file
        do {
            try htmlString.write(toFile: outputPath, atomically: true, encoding: .utf8)
        } catch {
            throw TransformError.fileWriteFailed
        }
    }
}
