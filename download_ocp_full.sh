#!/bin/bash
set -e

# === Configuration ===
BIN_DIR="./bin"
mkdir -p "$BIN_DIR"

# === Function for visual steps ===
print_step() {
  echo -e "\n\033[1;34m[STEP]\033[0m $1"
}

# === Ask for version ===
read -rp "Enter OpenShift version (e.g., 4.16.6): " VERSION
if [[ -z "$VERSION" ]]; then
  echo "❌ Version cannot be empty."
  exit 1
fi

print_step "Downloading OpenShift ${VERSION} components to ${BIN_DIR} ..."

cd "$BIN_DIR"

# === Download and extract OpenShift binaries ===
curl -s "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${VERSION}/openshift-install-linux-${VERSION}.tar.gz" \
  | tar zxvf - openshift-install

curl -s "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${VERSION}/openshift-client-linux-${VERSION}.tar.gz" \
  | tar zxvf - oc

# === Download supporting tools and archives ===
wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${VERSION}/oc-mirror.tar.gz"
wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${VERSION}/sha256sum.txt"
wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/butane/latest/butane"
wget -q "https://developers.redhat.com/content-gateway/rest/mirror/pub/openshift-v4/clients/mirror-registry/latest/mirror-registry.tar.gz"

# === Extract oc-mirror ===
print_step "Extracting oc-mirror..."
tar -zxvf oc-mirror.tar.gz oc-mirror
chmod +x oc-mirror

# === Make binaries executable ===
chmod +x oc openshift-install butane

# === Move binaries to /usr/local/bin ===
print_step "Installing tools to /usr/local/bin ..."
sudo mv -v oc openshift-install oc-mirror butane /usr/local/bin/

# === Fetch CoreOS ISO URL ===
print_step "Fetching CoreOS live ISO URL..."
COREOS_URL=$(openshift-install coreos print-stream-json | grep -o 'https[^"]*x86_64[^"]*\.iso')

if [[ -z "$COREOS_URL" ]]; then
  echo "❌ Could not detect CoreOS ISO URL."
  exit 1
fi

echo "Found CoreOS ISO: $COREOS_URL"
wget -q --show-progress "$COREOS_URL"

ISO_FILE=$(basename "$COREOS_URL")
echo "✅ CoreOS ISO downloaded: ${ISO_FILE}"

cd - >/dev/null

print_step "✅ All tasks completed successfully!"
echo "📦 All downloaded tarballs and files are in: ${BIN_DIR}"
