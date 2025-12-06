#!/bin/bash
set -e

# === Configuration ===
rm -rf ./bin
BIN_DIR="./bin"
mkdir -p "$BIN_DIR"
yum install vim wget git jq podman -y 

# === Function for visual steps ===
print_step() {
  echo -e "\n\033[1;34m[STEP]\033[0m $1"
}

# === Ensure /usr/local/bin is in PATH ===
if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
  echo "[INFO] /usr/local/bin is not in PATH. Adding it temporarily for this session..."
  export PATH="$PATH:/usr/local/bin"
fi



# === Persist /usr/local/bin to PATH after script finishes ===
print_step "Updating PATH in ~/.bashrc if not already present..."

if ! grep -q '/usr/local/bin' ~/.bashrc; then
  echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
  echo "✅ Added /usr/local/bin to PATH in ~/.bashrc"
else
  echo "ℹ️ /usr/local/bin is already in ~/.bashrc"
fi

# === Ask for version ===
read -rp "Enter OpenShift version (e.g., 4.16.6): " VERSION
if [[ -z "$VERSION" ]]; then
  echo "❌ Version cannot be empty."
  exit 1
fi

print_step "Downloading OpenShift ${VERSION} components to ${BIN_DIR} ..."

cd "$BIN_DIR"

# === Download and extract OpenShift binaries ===
#curl -s "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${VERSION}/openshift-install-linux-${VERSION}.tar.gz" \
#  | tar zxvf - openshift-install

#curl -s "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${VERSION}/openshift-client-linux-${VERSION}.tar.gz" \
#  | tar zxvf - oc

# === Download supporting tools and archives ===
wget -q "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${VERSION}/openshift-client-linux-${VERSION}.tar.gz"
wget -q ""https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${VERSION}/openshift-install-linux-${VERSION}.tar.gz
wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${VERSION}/oc-mirror.tar.gz"
wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${VERSION}/sha256sum.txt"
wget -q "https://mirror.openshift.com/pub/openshift-v4/clients/butane/latest/butane"
wget -q "https://mirror.openshift.com/pub/cgw/mirror-registry/latest/mirror-registry-amd64.tar.gz"

# === Extract oc-mirror ===
print_step "Extracting oc-mirror..."
tar -zxvf oc-mirror.tar.gz oc-mirror
chmod +x oc-mirror
tar -xvf openshift-install-linux-${VERSION}.tar.gz
tar -xvf openshift-client-linux-${VERSION}.tar.gz

# === Make binaries executable ===
chmod +x oc openshift-install butane kubectl 
print_step "Extracting mirror-registry..."
tar -zxvf mirror-registry-amd64.tar.gz

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
