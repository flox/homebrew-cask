cask "flox" do
  arch arm: "aarch64", intel: "x86_64"

  version "1.0.7"
  sha256 arm:   "edf19cd669c9a38e3e021dece3a8aaffb2049149fabca16a55fc401e98b48974",
         intel: "e6111d522ab692be463a83e0e377c9035b1a5d02d6ac9f73a56c525c6e54ba0f"

  url "https://downloads.flox.dev/by-env/stable/osx/flox-#{version}.#{arch}-darwin.pkg"
  name "flox"
  desc "Manages environments across the software lifecycle"
  homepage "https://flox.dev/"

  livecheck do
    url "https://downloads.flox.dev/by-env/stable/LATEST_VERSION"
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  auto_updates true
  depends_on macos: ">= :catalina"

  pkg "flox-#{version}.#{arch}-darwin.pkg"

  # NOTE: Remove early_script once 1.1.0 is released.
  uninstall early_script: {
              executable:   "/usr/bin/killall",
              args:         ["-9", "pkgdb"],
              sudo:         true,
              must_succeed: false,
            },
            launchctl:    [
              "org.nixos.darwin-store",
              "org.nixos.nix-daemon",
            ],
            quit:         [
              "org.nixos.darwin-store",
              "org.nixos.nix-daemon",
            ],
            script:       {
              executable: "/usr/local/share/flox/scripts/uninstall",
              sudo:       true,
            },
            pkgutil:      "com.floxdev.flox",
            delete:       "/usr/local/share/flox"

  # Remove and uninstall Flox's Nix Store regardless of the current state.
  # Script is inline'd to support zap independent of an uninstall because
  # uninstall will remove the uninstall script itself.
  zap script: {
        executable: "/bin/sh",
        args:       ["-c", '
/usr/sbin/diskutil unmount /nix || /usr/sbin/lsof /nix
/usr/sbin/diskutil apfs deleteVolume "Nix Store"
/usr/bin/dscl . delete /Groups/nixbld || true
for i in $(seq 1 32); do /usr/bin/dscl . -delete "/Users/_nixbld$i" || true ; done
/usr/bin/sed -i -e "/^nix$/d" /etc/synthetic.conf || true
/usr/bin/sed -i -e "/ \\/nix apfs rw,noauto,nobrowse,suid,owners$/d" /etc/fstab || true
EDITOR=cat vifs > /dev/null
'],
        sudo:       true,
      },
      trash:  [
        "/etc/flox-version.update",
        "/etc/nix/nix.conf.bak",
        "~/.cache/flox",
        "~/.config/flox",
      ]
end
