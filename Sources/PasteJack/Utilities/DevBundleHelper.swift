import AppKit

/// Ensures the app runs from a signed .app bundle for stable TCC permissions.
///
/// When built with `swift build` or an IDE, the output is a bare executable.
/// macOS TCC (Accessibility, Screen Recording) identifies bare executables by
/// their code hash, which changes on every recompile — losing all permissions.
///
/// This helper wraps the executable in an .app bundle with a stable
/// CFBundleIdentifier and ad-hoc signs it, so permissions persist across
/// recompiles. Call `ensureRunningFromBundle()` at the very start of
/// `applicationDidFinishLaunching`.
enum DevBundleHelper {

    /// If already running from a proper .app bundle, returns immediately.
    /// Otherwise, creates/updates the bundle wrapper, launches it, and exits
    /// the current (bare) process.
    static func ensureRunningFromBundle() {
        // Already in a proper app bundle — nothing to do
        guard Bundle.main.bundleIdentifier != Constants.bundleIdentifier else {
            return
        }

        let execPath = URL(fileURLWithPath: ProcessInfo.processInfo.arguments[0])
            .resolvingSymlinksInPath()
        let buildDir = execPath.deletingLastPathComponent()
        let appBundle = buildDir.appendingPathComponent("\(Constants.appName).app")
        let macosDir = appBundle.appendingPathComponent("Contents/MacOS")
        let targetBinary = macosDir.appendingPathComponent(Constants.appName)
        let infoPlist = appBundle.appendingPathComponent("Contents/Info.plist")

        let fm = FileManager.default

        // Create bundle directory structure
        try? fm.createDirectory(at: macosDir, withIntermediateDirectories: true)

        // Copy the freshly compiled binary into the bundle
        try? fm.removeItem(at: targetBinary)
        guard (try? fm.copyItem(at: execPath, to: targetBinary)) != nil else {
            // Can't create bundle — proceed as bare executable (permissions will reset)
            return
        }

        // Write Info.plist with a stable bundle identifier
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" \
        "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleIdentifier</key>
            <string>\(Constants.bundleIdentifier)</string>
            <key>CFBundleName</key>
            <string>\(Constants.appName)</string>
            <key>CFBundleExecutable</key>
            <string>\(Constants.appName)</string>
            <key>CFBundlePackageType</key>
            <string>APPL</string>
            <key>LSUIElement</key>
            <true/>
        </dict>
        </plist>
        """
        try? plist.write(to: infoPlist, atomically: true, encoding: .utf8)

        // Ad-hoc sign with stable designated requirement (identifier only, no CDHash)
        // This ensures TCC permissions persist across recompiles
        let codesign = Process()
        codesign.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
        codesign.arguments = [
            "--force", "--sign", "-",
            "-r=designated => identifier \"\(Constants.bundleIdentifier)\"",
            appBundle.path,
        ]
        codesign.standardOutput = FileHandle.nullDevice
        codesign.standardError = FileHandle.nullDevice
        try? codesign.run()
        codesign.waitUntilExit()

        // Terminate any existing instance running from this bundle
        let running = NSRunningApplication.runningApplications(
            withBundleIdentifier: Constants.bundleIdentifier
        )
        for app in running {
            app.terminate()
        }
        if !running.isEmpty {
            Thread.sleep(forTimeInterval: 0.5)
        }

        // Launch from the signed .app bundle
        NSWorkspace.shared.open(appBundle)

        // Exit the bare executable — the .app instance takes over
        exit(0)
    }
}
