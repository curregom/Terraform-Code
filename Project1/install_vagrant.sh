LATEST_VAGRANT=$(
  curl -s https://github.com/hashicorp/vagrant/releases.atom | \
   xml2 | grep -oP '(?<=feed/entry/title=).*' | sort -V | tail -1
)

PACKAGE_NAME="vagrant_${LATEST_VAGRANT##v}_x86_64.deb"
URL_PREFIX="releases.hashicorp.com/vagrant/${LATEST_VAGRANT##v}"

pushd ~/Downloads
curl -sOL https://$URL_PREFIX/$PACKAGE_NAME
sudo apt install ./$PACKAGE_NAME
popd