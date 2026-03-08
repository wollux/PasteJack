cask "pastejack" do
  version "0.9.10"
  sha256 "7bdf135bae2273053975cf7c00e402cbc6dafc68ad9b3d2484b5ed3e5ec11332"

  url "https://pastejack.app/downloads/PasteJack-#{version}.dmg"
  name "PasteJack"
  desc "Paste clipboard contents as simulated keystrokes — bypass paste-blocking"
  homepage "https://pastejack.app"

  livecheck do
    url "https://pastejack.app/appcast.xml"
    strategy :sparkle
  end

  depends_on macos: ">= :sonoma"

  app "PasteJack.app"

  zap trash: [
    "~/Library/Preferences/com.pastejack.app.plist",
    "~/Library/Application Support/PasteJack",
  ]

  caveats <<~EOS
    PasteJack requires Accessibility permission to simulate keystrokes.

    After installation, go to:
      System Settings > Privacy & Security > Accessibility
    and enable PasteJack.

    Default hotkey: Ctrl+Shift+V
  EOS
end
