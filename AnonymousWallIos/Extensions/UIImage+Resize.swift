//
//  UIImage+Resize.swift
//  AnonymousWallIos
//
//  Shared utility for resizing images before upload
//

import UIKit

extension UIImage {
    /// Returns a copy of the image scaled down so neither dimension exceeds `maxDimension`.
    /// If the image is already within the limit, the original is returned unchanged.
    func resized(maxDimension: CGFloat = 1024) -> UIImage {
        let size = self.size
        guard size.width > maxDimension || size.height > maxDimension else { return self }
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
