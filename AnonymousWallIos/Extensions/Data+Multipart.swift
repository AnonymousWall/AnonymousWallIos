//
//  Data+Multipart.swift
//  AnonymousWallIos
//
//  Extension helpers for building multipart/form-data request bodies
//

import Foundation

extension Data {
    mutating func appendFormField(name: String, value: String, boundary: String) {
        guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
              let dispositionData = "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8),
              let valueData = "\(value)\r\n".data(using: .utf8) else { return }
        append(boundaryData)
        append(dispositionData)
        append(valueData)
    }

    mutating func appendFileField(
        name: String,
        filename: String,
        mimeType: String,
        data fileData: Data,
        boundary: String
    ) {
        guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
              let dispositionData = "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8),
              let contentTypeData = "Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8),
              let trailingData = "\r\n".data(using: .utf8) else { return }
        append(boundaryData)
        append(dispositionData)
        append(contentTypeData)
        append(fileData)
        append(trailingData)
    }
}
