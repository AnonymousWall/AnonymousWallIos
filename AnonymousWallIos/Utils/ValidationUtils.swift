//
//  ValidationUtils.swift
//  AnonymousWallIos
//
//  Email validation utility
//

import Foundation

struct ValidationUtils {
    /// Validates if the provided string is a valid email format
    /// - Parameter email: The email string to validate
    /// - Returns: True if the email is valid, false otherwise
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
