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
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
    }

    /// Append a binary file field to a multipart body
    mutating func appendFileField(
        name: String,
        filename: String,
        mimeType: String,
        data fileData: Data,
        boundary: String
    ) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        append(fileData)
        append("\r\n".data(using: .utf8)!)
    }
}
