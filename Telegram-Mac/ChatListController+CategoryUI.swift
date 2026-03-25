import Foundation
import AppKit

extension ChatListController {
    /// Updates the list header title for the active Focus strip category.
    /// Must use direct property access — KVC `setValue(_:forKey:)` on `genericView` can trap at runtime.
    func updateCategoryUI(for categoryTitle: String?) {
        self.genericView.focusCategoryOverride = categoryTitle
    }
}
