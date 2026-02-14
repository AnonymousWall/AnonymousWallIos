//
//  HTTPStatus.swift
//  AnonymousWallIos
//
//  HTTP status code constants
//

import Foundation

enum HTTPStatus {
    static let ok = 200
    static let created = 201
    static let successRange = 200...299
    static let unauthorized = 401
    static let forbidden = 403
    static let notFound = 404
    static let timeout = 408
    static let serverErrorRange = 500...599
}
