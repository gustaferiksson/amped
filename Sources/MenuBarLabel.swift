import SwiftUI

/// The menu bar icon itself. An SF Symbol that reflects the current state:
/// `pill` (sleep allowed) → `pill.fill` (awake) → `pills.fill` (awake, lid-closed OK).
struct MenuBarLabel: View {
    @ObservedObject var controller: SleepController

    var body: some View {
        Image(systemName: controller.menuBarSymbolName)
    }
}
