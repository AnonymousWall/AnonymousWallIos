//
//  ImageSendConfirmationSheet.swift
//  AnonymousWallIos
//
//  Confirmation sheet shown before sending an image in chat.
//

import SwiftUI

struct ImageSendConfirmationSheet: View {
    let image: UIImage
    /// Called when the user confirms they want to send the image.
    let onSend: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Send Image?")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 300)
                .cornerRadius(12)
                .padding(.horizontal)
                .accessibilityLabel("Image preview")
                .accessibilityAddTraits(.isImage)

            HStack(spacing: 16) {
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                .accessibilityLabel("Cancel sending image")

                Button {
                    onSend()
                    dismiss()
                } label: {
                    Text("Send")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .accessibilityLabel("Confirm send image")
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}
