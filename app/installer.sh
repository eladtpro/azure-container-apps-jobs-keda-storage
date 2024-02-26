# Download the installer script:
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
# Alternatively: wget --secure-protocol=TLSv1_2 --https-only https://get.opentofu.org/install-opentofu.sh -O install-opentofu.sh

# Grand execution permissions:
chmod +x install-opentofu.sh

# Please inspect the downloaded script at this point.

# Run the installer:
./install-opentofu.sh --install-method standalone

# Remove the installer:
rm install-opentofu.sh



# #!/bin/sh
# set -e
# TOFU_VERSION="1.6.0"
# OS="$(uname | tr '[:upper:]' '[:lower:]')"
# ARCH="$(uname -m | sed -e 's/aarch64/arm64/' -e 's/x86_64/amd64/')"
# TEMPDIR="$(mktemp -d)"
# pushd "${TEMPDIR}" >/dev/null
# wget "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/tofu_${TOFU_VERSION}_${OS}_${ARCH}.zip"
# unzip "tofu_${TOFU_VERSION}_${OS}_${ARCH}.zip"
# sudo mv tofu /usr/local/bin/tofu
# popd >/dev/null
# rm -rf "${TEMPDIR}"
# echo "OpenTofu is now available at /usr/local/bin/tofu."
