//
//  KeyboardDismisser.swift
//  Since
//

import UIKit

extension UIApplication: UIGestureRecognizerDelegate {
    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    @objc private func resignFirstResponderIfNeeded() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    /// Dismisses the keyboard on any tap anywhere in the app, without blocking that tap from
    /// also reaching whatever control is underneath — `cancelsTouchesInView = false` is what
    /// makes that possible; SwiftUI's `.simultaneousGesture(TapGesture())` doesn't reliably
    /// give the same guarantee on a `List`/`Form`, which is UICollectionView-backed.
    func addTapGestureRecognizerToDismissKeyboard() {
        guard let window = connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
        else { return }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(resignFirstResponderIfNeeded))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        window.addGestureRecognizer(tapGesture)
    }
}
