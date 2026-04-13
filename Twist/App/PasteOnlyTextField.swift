import SwiftUI
import UIKit

/// A text field that suppresses the keyboard (inputView = empty UIView)
/// but still shows the standard "Paste" context menu on tap/long-press.
struct PasteOnlyTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.inputView          = UIView()   // hides keyboard
        tf.inputAccessoryView = UIView()   // hides toolbar
        tf.placeholder        = placeholder
        tf.borderStyle        = .roundedRect
        tf.autocorrectionType = .no
        tf.delegate           = context.coordinator
        // Fixed size — never expand with content
        tf.setContentHuggingPriority(.defaultLow, for: .horizontal)
        tf.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tf.addTarget(context.coordinator,
                     action: #selector(Coordinator.textChanged(_:)),
                     for: .editingChanged)
        return tf
    }

    func updateUIView(_ tf: UITextField, context: Context) {
        if tf.text != text { tf.text = text }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: PasteOnlyTextField

        init(_ parent: PasteOnlyTextField) { self.parent = parent }

        @objc func textChanged(_ tf: UITextField) {
            parent.text = tf.text ?? ""
        }

        // Become first responder on tap so the paste menu appears
        func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool { true }
    }
}
