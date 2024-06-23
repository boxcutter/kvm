# CentOS Cloud Images

## CentOS Stream 9 UEFI virtual firmware

```
cd centos/cloud/x86_64
packer init .
PACKER_LOG=1 packer build \
  -var-file centos-stream-9-x86_64.pkrvars.hcl \
  centos.pkr.hcl
```
