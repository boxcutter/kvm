# Install Hashicorp Packer on Ubuntu 24.04

```
# Add Hashicorp's official GPG key
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add the repository to Apt sources
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
sudo apt-get update

# To install the latest version
sudo apt install packer

# Verify the install
$ packer --version
Packer v1.11.0
```
