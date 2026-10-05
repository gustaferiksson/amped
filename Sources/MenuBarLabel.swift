import SwiftUI

/// The menu bar icon itself. An SF Symbol that reflects the current state:
/// `pill` (sleep allowed) → `pill.fill` (awake) → `pills.fill` (runs while locked;
/// one pill dimmed unless Keep Awake is also on).
struct MenuBarLabel: View {
    @ObservedObject var controller: SleepController

    // MenuBarExtra drops .symbolRenderingMode; a hierarchical NSImage configuration survives.
    private static let dimmedPills = NSImage(systemSymbolName: "pills.fill", accessibilityDescription: nil)!
        .withSymbolConfiguration(.preferringHierarchical())!

    var body: some View {
        if controller.lidClosed && !controller.keepAwake {
            Image(nsImage: Self.dimmedPills)
        } else {
            Image(systemName: controller.menuBarSymbolName)
        }
    }
}
