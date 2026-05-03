import AppKit
import MusicDeckCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var webWindowController: WebWindowController?
    private var statusBarController: StatusBarController?
    private var remoteCommandController: RemoteCommandController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let windowController = WebWindowController()
        let settingsStore = SettingsStore()
        let loginItemController = LoginItemController(
            manager: MainAppLoginItemManager(),
            settingsStore: settingsStore
        )

        webWindowController = windowController
        statusBarController = StatusBarController(
            webWindowController: windowController,
            loginItemController: loginItemController
        )
        remoteCommandController = RemoteCommandController(playerController: windowController)
        remoteCommandController?.start()
        windowController.showAndLoad()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        webWindowController?.showAndLoad()
        return true
    }
}
