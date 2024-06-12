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

  uninstall_postflight do
    _, * = system_command "/bin/mv", args: ["/etc/flox-version.update", "/etc/flox-version"], sudo: true
  end

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
              executable: "/bin/sh",
              args:       ["-c", "
      /usr/local/bin/nix profile install /usr/local/bin/nix \
          --profile /nix/var/nix/profiles/default \
          --experimental-features nix-command || true
      /bin/rm -rf /nix/var/nix/daemon-socket || true
      /bin/cp /etc/flox-version /etc/flox-version.update || true
    "],
              sudo:       true,
            },
            pkgutil:      "com.floxdev.flox"

  zap script: {
        executable: "/bin/sh",
        args:       ["-c", '
/usr/sbin/diskutil unmount /nix
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
        "~/.cache/flox",
        "~/.config/flox",
      ]
end
