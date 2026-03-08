cask "pastejack" do
  version "0.9.12"
  sha256 "624ca6863b62fa838aa9faa37943344411f2aed8d993f1bb97f4cb69095c49fb"

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
