//
//  KeyboardDismissButton.swift
//  ParkEzy
//
//  Floating round button that appears just above the keyboard on any screen
//  (including sheets) and closes the keyboard when tapped.
//

import UIKit

enum KeyboardDismissButton {
    private static let size: CGFloat = 48
    private static let margin: CGFloat = 16
    private static var button: UIButton?
    private static var observer: NSObjectProtocol?

    /// Call once at launch.
    static func install() {
        guard observer == nil else { return }
        observer = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification, object: nil, queue: .main
        ) { note in
            handle(note)
        }
    }

    private static func handle(_ note: Notification) {
        guard let end = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let window = keyWindow() else { return }
        let duration = (note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double) ?? 0.25
        let keyboardVisible = end.minY < window.bounds.height

        guard keyboardVisible else {
            guard let button else { return }
            UIView.animate(withDuration: duration, animations: { button.alpha = 0 }) { _ in
                if button.alpha == 0 { button.removeFromSuperview() }
            }
            return
        }

        let button = self.button ?? makeButton()
        self.button = button
        let target = CGRect(
            x: window.bounds.width - margin - size - window.safeAreaInsets.right,
            y: end.minY - margin - size,
            width: size, height: size
        )
        if button.superview == nil {
            button.frame = target
            button.alpha = 0
            window.addSubview(button)
        }
        window.bringSubviewToFront(button)
        UIView.animate(withDuration: duration) {
            button.frame = target
            button.alpha = 1
        }
    }

    private static func makeButton() -> UIButton {
        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.image = UIImage(systemName: "keyboard.chevron.compact.down",
                               withConfiguration: UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold))
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        let button = UIButton(configuration: config)
        button.accessibilityLabel = "Hide keyboard"
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.25
        button.layer.shadowRadius = 6
        button.layer.shadowOffset = CGSize(width: 0, height: 3)
        button.addAction(UIAction { _ in
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }, for: .touchUpInside)
        return button
    }

    private static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }
}
