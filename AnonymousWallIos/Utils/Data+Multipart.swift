//
//  Data+Multipart.swift
//  AnonymousWallIos
//
//  Helpers for building multipart/form-data request bodies
//

import Foundation

extension Data {
    /// Append a plain-text form field to a multipart body
    mutating func appendFormField(name: String, value: String, boundary: String) {
        guard let boundary = "--\(boundary)\r\n".data(using: .utf8),
              let disposition = "Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8),
              let valueData = "\(value)\r\n".data(using: .utf8) else { return }
        append(boundary)
        append(disposition)
        append(valueData)
    }

    /// Append a binary file field to a multipart body
    mutating func appendFileField(
        name: String,
        filename: String,
        mimeType: String,
        data fileData: Data,
        boundary: String
    ) {
        guard let boundaryData = "--\(boundary)\r\n".data(using: .utf8),
              let disposition = "Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8),
              let contentType = "Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8),
              let crlf = "\r\n".data(using: .utf8) else { return }
        append(boundaryData)
        append(disposition)
        append(contentType)
        append(fileData)
        append(crlf)
    }
}
