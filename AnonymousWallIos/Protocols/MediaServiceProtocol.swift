//
//  MediaServiceProtocol.swift
//  AnonymousWallIos
//
//  Created by Ziyi Huang on 3/14/26.
//

import UIKit

protocol MediaServiceProtocol {
    func presign(filename: String, folder: String, token: String) async throws -> PresignResponse
    func uploadDirect(to uploadUrl: String, jpeg: Data) async throws
    func uploadImage(_ image: UIImage, folder: String, token: String) async throws -> String
    func uploadImages(_ images: [UIImage], folder: String, token: String) async throws -> [String]
}
