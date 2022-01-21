# Kubernetes-env

## Hello and welcome to Kubenetes-env

* ***This open source project comes with absolutely no warrenty and support.***
* ***Fork this project for your own needs.***
* This is a Kubernetes *self-learning education aids*.
* For education/learning purpose, *1x Control-Plane, 2x Workers* will be more then enough.
* This *1x Control-Plane, 2x Workers* Kubernetes Cluster can all reside in 1 single VM.
* A base VM with the following specification will be required

| Resources | Specifications     |
| --------- |:------------------:|
| vCPU      | 4                  |
| Memory    | 8GB                |
| Disk      | 30GB               |
| NIC       | 1                  |
| Base OS   | Ubuntu 20.04 Focal |

1. Create a base VM with above specification
2. Remember to turn off swap
```
    sudo swapoff -a
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```
3. Bootup and login to your VM
4. Create a `Projects` directory and `cd` into it
5. `git clone https://github.com/tsanghan/kubernetes-env.git`
6. `cd` into `kubernetes-env`
7. `sudo ./prepare-vm.sh`
8. Follow the instruction at the end of the completion of `prepare-vm.sh` script
9. Log back into your VM
**Note:**  The new groups you have been added to will then be in place, you can check this has happened with `id -a`.
10. You have 2 choices to deploy a kubernetes cluster, using *LXD* or *KIND*
11. As of v1.12.0, you now have a 3rd choice, Kubernetes on Virtualbox/Vagrant.

### Kubernetes on LXD

11. We will explore LXD method first
12. `cd` into `Projects/kubernetes-env/kubernetes-on-lxd`
13. Run `prepare-lxd.sh` (this is located in your ~/.local directory, you won't find it in the ~/Project tree!)
14. Wait until the script finishes
15. `lxc launch -p k8s-cloud-init focal-cloud <your lxc node name>`
16. Instructions below will use the node name of *lxd-ctrlp-1*
17. Launch 2 more worker nodes with above command (example *lxd-wrker-1* and *lxd-wrker-2*)
18. `watch lxc ls`
19. All 3 lxc nodes will power down after being prepared
20. Start all nodes `lxc start --all`
21. Run `kubeadm init` on control-plane node with the following long command
22. `lxc exec lxd-ctrlp-1 -- kubeadm init --upload-certs | tee kubeadm-init.out`
23. Wait till kubeadm finishes initializing the control-plane node
24. Perform `kubeadm join` command from `kubeadm init` output on 2 worker nodes. Please refer to last 2 lines of local `kubeadm-init.out` file for the full `kubeadm join` command.
25. Pull `/etc/kubernetes/admin.conf` from within `lxd-ctrlp-1` node into your local `~/.kube` directory with the following command
26. `lxc file pull lxd-ctrlp-1/etc/kubernetes/admin.conf ~/.kube/config` make sure you have created ~/.kube directory first
27. Activate `kubectl` auto-completion
28. `source ~/.bash_complete` assuming you are using bash
29. Now you can access you cluster with `kubectl get nodes` command.  The kubectl command is aliased to `k`.
30. `k get no`
31. All your nodes are not ready, becasue we have yet to instal a CNI plugin
```
NAME          STATUS     ROLES                  AGE     VERSION
lxd-ctrlp-1   NotReady   control-plane,master   2m55s   v1.23.1
lxd-wrker-1   NotReady   <none>                 15s     v1.23.1
lxd-wrker-2   NotReady   <none>                 5s      v1.23.1
```
32. Install calico as it support Network Policy
33. `k apply -f https://docs.projectcalico.org/manifests/calico.yaml`
34. `k get no` again
35. Wait till all nodes are ready
```
NAME          STATUS   ROLES                  AGE     VERSION
lxd-ctrlp-1   Ready    control-plane,master   5m42s   v1.23.1
lxd-wrker-1   Ready    <none>                 3m2s    v1.23.1
lxd-wrker-2   Ready    <none>                 2m52s   v1.23.1
```
36. Type `k get all -A` to see all pods
```
NAMESPACE     NAME                                           READY   STATUS    RESTARTS   AGE
kube-system   pod/calico-kube-controllers-56b8f699d9-vwvvc   1/1     Running   0          85s
kube-system   pod/calico-node-4nvzn                          1/1     Running   0          85s
kube-system   pod/calico-node-j7sw4                          1/1     Running   0          85s
kube-system   pod/calico-node-qvqwx                          1/1     Running   0          85s
kube-system   pod/coredns-78fcd69978-jg7nt                   1/1     Running   0          6m14s
kube-system   pod/coredns-78fcd69978-nnzzt                   1/1     Running   0          6m14s
kube-system   pod/etcd-lxd-ctrlp-1                           1/1     Running   0          6m21s
kube-system   pod/kube-apiserver-lxd-ctrlp-1                 1/1     Running   0          6m15s
kube-system   pod/kube-controller-manager-lxd-ctrlp-1        1/1     Running   0          6m15s
kube-system   pod/kube-proxy-5mthj                           1/1     Running   0          3m43s
kube-system   pod/kube-proxy-999t4                           1/1     Running   0          3m32s
kube-system   pod/kube-proxy-lwb4r                           1/1     Running   0          6m15s
kube-system   pod/kube-scheduler-lxd-ctrlp-1                 1/1     Running   0          6m15s

NAMESPACE     NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP                  6m22s
kube-system   service/kube-dns     ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   6m20s

NAMESPACE     NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-system   daemonset.apps/calico-node   3         3         3       3            3           kubernetes.io/os=linux   85s
kube-system   daemonset.apps/kube-proxy    3         3         3       3            3           kubernetes.io/os=linux   6m20s

NAMESPACE     NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/calico-kube-controllers   1/1     1            1           85s
kube-system   deployment.apps/coredns                   2/2     2            2           6m20s

NAMESPACE     NAME                                                 DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/calico-kube-controllers-56b8f699d9   1         1         1       85s
kube-system   replicaset.apps/coredns-78fcd69978                   2         2         2       6m15s
```
37. Run `k-apply.sh`
38. If you run it, the following services will be installed
```
metrics server
local path provisioner
NGINX ingress controller
metallb

NAMESPACE       NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
default         kubernetes                           ClusterIP      10.96.0.1        <none>           443/TCP                      23m
default         svc-deploy-nginx                     LoadBalancer   10.104.3.132     10.127.202.241   80:31880/TCP                 3m41s
ingress-nginx   ingress-nginx-controller             LoadBalancer   10.102.143.1     10.127.202.240   80:30116/TCP,443:30765/TCP   13m
ingress-nginx   ingress-nginx-controller-admission   ClusterIP      10.110.81.97     <none>           443/TCP                      13m
kube-system     kube-dns                             ClusterIP      10.96.0.10       <none>           53/UDP,53/TCP,9153/TCP       23m
kube-system     metrics-server                       ClusterIP      10.107.154.234   <none>           443/TCP                      13m
```
39. There is also a `ingress.yaml` manifest that will deploy an `ingressClass` and a *ingress resource*
40. However, a `Deployment` and a `Service` is missing, waiting to be create.
41. Explore and enjoy the *1x Control-Plane, 2x Workers* Kubernetes cluster
42. Check the memory usage with `htop`

### Kubernetes with KIND

1. `cd ../kind`
2. Activate `kind` auto-completion
3. `source ~/.bash_complete` assuming you are using bash
4. Start the `kind` cluster
5. `kind create cluster --config kind.yaml`
6. The provided `kind.yaml` will start 1x *Control-Plane Node* and 2x *Worker Nodes* and disabled default CNI
7. `kind` automatically merge `kind` cluster config into `~/.kube/config`
8. `k config get-contexts` will show that there are 2 contexts for 2 clusters
```
CURRENT   NAME                          CLUSTER      AUTHINFO           NAMESPACE
*         kind-kind                     kind-kind    kind-kind
          kubernetes-admin@kubernetes   kubernetes   kubernetes-admin
```
9. The current context is `kind-kind`
10. `k get no`
11. All the nodes are not ready, a CNI plugin as yet to be installed (default CNI in `kind.yaml` is disabled)
```
NAME                 STATUS     ROLES                  AGE     VERSION
kind-control-plane   NotReady   control-plane,master   6m46s   v1.23.1
kind-worker          NotReady   <none>                 6m15s   v1.23.1
kind-worker2         NotReady   <none>                 6m15s   v1.23.1
```
12. We will use calico as it support Network Policy
13. `k apply -f https://docs.projectcalico.org/manifests/calico.yaml`
14. `k get no` again
15. Wait till all the nodes are ready
```

NAME                 STATUS   ROLES                  AGE     VERSION
kind-control-plane   Ready    control-plane,master   9m      v1.23.1
kind-worker          Ready    <none>                 8m29s   v1.23.1
kind-worker2         Ready    <none>                 8m29s   v1.23.1
```
16. `k get all -A` to see all the pods
```
NAMESPACE            NAME                                             READY   STATUS    RESTARTS   AGE
kube-system          pod/calico-kube-controllers-56b8f699d9-f9jxp     1/1     Running   0          2m9s
kube-system          pod/calico-node-79vcm                            1/1     Running   0          2m9s
kube-system          pod/calico-node-lp9md                            1/1     Running   0          2m9s
kube-system          pod/calico-node-t9h7f                            1/1     Running   0          2m9s
kube-system          pod/coredns-78fcd69978-q5vw4                     1/1     Running   0          9m42s
kube-system          pod/coredns-78fcd69978-zxk77                     1/1     Running   0          9m42s
kube-system          pod/etcd-kind-control-plane                      1/1     Running   0          9m56s
kube-system          pod/kube-apiserver-kind-control-plane            1/1     Running   0          9m56s
kube-system          pod/kube-controller-manager-kind-control-plane   1/1     Running   0          9m58s
kube-system          pod/kube-proxy-b75hl                             1/1     Running   0          9m28s
kube-system          pod/kube-proxy-d6858                             1/1     Running   0          9m43s
kube-system          pod/kube-proxy-k654c                             1/1     Running   0          9m28s
kube-system          pod/kube-scheduler-kind-control-plane            1/1     Running   0          9m56s
local-path-storage   pod/local-path-provisioner-85494db59d-8bq57      1/1     Running   0          9m42s

NAMESPACE     NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP                  9m58s
kube-system   service/kube-dns     ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   9m56s

NAMESPACE     NAME                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
kube-system   daemonset.apps/calico-node   3         3         3       3            3           kubernetes.io/os=linux   2m9s
kube-system   daemonset.apps/kube-proxy    3         3         3       3            3           kubernetes.io/os=linux   9m56s

NAMESPACE            NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
kube-system          deployment.apps/calico-kube-controllers   1/1     1            1           2m9s
kube-system          deployment.apps/coredns                   2/2     2            2           9m56s
local-path-storage   deployment.apps/local-path-provisioner    1/1     1            1           9m55s

NAMESPACE            NAME                                                 DESIRED   CURRENT   READY   AGE
kube-system          replicaset.apps/calico-kube-controllers-56b8f699d9   1         1         1       2m9s
kube-system          replicaset.apps/coredns-78fcd69978                   2         2         2       9m43s
local-path-storage   replicaset.apps/local-path-provisioner-85494db59d    1         1         1       9m43s
```
17. Follow step 37. from `Kubernetes on LXD` to proceed
18. Explore and enjoy the 2 Kubernetes clusters
19. Check memory usage with `htop`

### Kubernetes on Virtualbox/Vagrant

1. ***WARNING*** This is just an acamdemic exercise. This is ***NOT*** the prefered method to create a Kubernetes cluster for self-learning & education, given that the 2 methods available above exists.
2. But, if you ***MUST***, follow the instrctions below at you own ***RISKS***.
3. Make sure you have turn on *nested* virtualization on your Hypervisor on your base OS.
4. The instructions below will bring up *1x Control-Plane, 2x Workers* Kubernetes Cluster with the following specifications.

| Node        | vCPU | Memory |
| ------------|:----:|:------:|
| vbx-ctrlp-1 | 2    | 2GB    |
| vbx-wrker-1 | 2    | 1.5GB  |
| vbx-wrker-2 | 2    | 1.5GB  |

4. `cd ../kubernetes-on-virtualbox`
5. `get-vb.sh`
6. `get-vagrant.sh`
7. `create-vbx-cluster.sh`
8. Enjoy!!
9. Check memory usage with `htop`

## How to stop the clusters?
### Kubernetes on LXD
1. `lxc stop --all`
2. To start again `lxc start --all`
3. Nodes instance can be deleted the with `lxc delete <node name>`
### Kubernetes with KIND
1. There are no provision to stop a `kind` cluster with `kind`.
2. Kind cluster can only be `create`d or `delete`d
3. `kind delete cluster`
4. Kind cluster can be stopped with `docker` command
5. `docker container ls`
```
CONTAINER ID   IMAGE                  COMMAND                  CREATED             STATUS              PORTS                       NAMES
20ffab3b00a3   kindest/node:v1.23.1   "/usr/local/bin/entr…"   About an hour ago   Up About a minute   127.0.0.1:44651->6443/tcp   kind-control-plane
38f750fd85cb   kindest/node:v1.23.1   "/usr/local/bin/entr…"   About an hour ago   Up About a minute                               kind-worker2
26e00165cc2c   kindest/node:v1.23.1   "/usr/local/bin/entr…"   About an hour ago   Up About a minute                               kind-worker
```
5. `docker stop <NAME/CONTAINER ID> <NAME/CONTAINER ID> ...`
### Kubernetes on Virtualbox/Vagrant
1. `stop-vbx-cluster.sh`
