# Talos Linux

```bash
# https://github.com/siderolabs/talos/releases
curl -LO https://github.com/siderolabs/talos/releases/download/v1.10.9/metal-amd64.iso
$ shasum -a 256 metal-amd64.iso 
7843b527f06f9a35e13fd9e974d1dfd1403b8da42610e4bc477e1c6bc34010ca  metal-amd64.iso

virt-install \
  --connect qemu:///system \
  --name talos-cluster \
  --boot hd,cdrom \
  --cdrom /var/lib/libvirt/iso/metal-amd64.iso \
  --disk pool=default,format=qcow2,bus=virtio,size=60 \
  --memory 4096 \
  --vcpus 2 \
  --os-variant linux2022 \
  --network network=host-network,model=virtio \
  --graphics spice \
  --noautoconsole

# Talos boots into RAM-only live mode
virt-viewer talos-cluster &
```

```
# Make sure you grab the same version of talosctl
curl -LO https://github.com/siderolabs/talos/releases/download/v1.10.9/talosctl-linux-amd64
$ shasum -a 256 talosctl-linux-amd64 
59aebb338eea4c3b7c5a5ef20f2817981c091fe00dfc3f9c79c47c39b9305b68  talosctl-linux-amd64
sudo cp talosctl-linux-amd64 /usr/local/bin/talosctl
sudo chmod +x /usr/local/bin/talosctl

$ talosctl version
Client:
	Tag:         v1.10.9
	SHA:         c48f7ede
	Built:       
	Go version:  go1.24.11
	OS/Arch:     linux/amd64
Server:
error constructing client: failed to determine endpoint

# get IP from console
TALOS_IP=10.63.33.141

$ talosctl get disks --nodes 10.63.33.141 --insecure
NODE   NAMESPACE   TYPE   ID      VERSION   SIZE     READ ONLY   TRANSPORT   ROTATIONAL   WWID   MODEL          SERIAL
       runtime     Disk   loop0   2         78 MB    true                                                       
       runtime     Disk   sr0     2         315 MB   false       sata        true                QEMU DVD-ROM   
       runtime     Disk   vda     2         64 GB    false       virtio      true

talosctl gen config talos-cluster https://10.63.33.141:6443 --install-disk /dev/vda -o configs/
talosctl apply-config --nodes 10.63.33.141 --insecure --file configs/controlplane.yaml
talosctl bootstrap --nodes 10.63.33.141 -e 10.63.33.141 --talosconfig configs/talosconfig
talosctl dashboard --nodes 10.63.33.141 -e 10.63.33.141 --talosconfig configs/talosconfig

talosctl logs -f -n 10.63.33.141 -e 10.63.33.141 --talosconfig configs/talosconfig etcd
talosctl -n 10.63.33.141 -e 10.63.33.141 --talosconfig configs/talosconfig service
```

```bash
# Make sure the version of kubectl you use is within one minor difference of your cluster
# Kubernetes: v1.33.6

curl -LO https://dl.k8s.io/release/v1.34.0/bin/linux/amd64/kubectl
curl -LO https://dl.k8s.io/release/v1.34.0/bin/linux/amd64/kubectl.sha256
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

chmod +x kubectl
mkdir -p ~/.local/bin
mv ./kubectl ~/.local/bin/kubectl
# and then append (or prepend) ~/.local/bin to $PATH

talosctl -n 10.63.33.141 -e 10.63.33.141 --talosconfig configs/talosconfig kubeconfig ./kubeconfig
export KUBECONFIG=./kubeconfig
$ kubectl get nodes
NAME            STATUS   ROLES           AGE   VERSION
talos-m27-blz   Ready    control-plane   23m   v1.33.6
```

```
# https://docs.siderolabs.com/talos/v1.10/deploy-and-manage-workloads/workers-on-controlplane
vi configs/controlplane.yaml
# Uncomment: allowSchedulingOnControlPlanes: true

talosctl apply-config --nodes 10.63.33.141 -e 10.63.33.141 --talosconfig configs/talosconfig --file configs/controlplane.yaml
$ kubectl get pods -A
NAMESPACE     NAME                                    READY   STATUS    RESTARTS      AGE
kube-system   coredns-78d87fb69b-m2mf6                1/1     Running   0             36m
kube-system   coredns-78d87fb69b-tchzm                1/1     Running   0             36m
kube-system   kube-apiserver-talos-m27-blz            1/1     Running   0             35m
kube-system   kube-controller-manager-talos-m27-blz   1/1     Running   2 (37m ago)   35m
kube-system   kube-flannel-4b7t4                      1/1     Running   0             36m
kube-system   kube-proxy-jvv66                        1/1     Running   0             36m
kube-system   kube-scheduler-talos-m27-blz            1/1     Running   2 (37m ago)   35
```

```bash
virsh destroy talos
virsh undefine talos --nvram --remove-all-storage
```
