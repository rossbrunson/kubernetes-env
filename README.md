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

## Instructions:

This guide is formatted so that you can copy and paste all commands directly from the guide and press ENTER to execute them in your shell.  Please note that there are a couple of steps towards the end of this guide where you will need to compose several commands from output that is exclusive to YOUR kubernetes cluster, so read the instructions on those steps carefully.<br>

#### Steps
1. Use a base VM with the above specifications.
2. Bootup and login to your VM.
3. You'll be turning off swap with the first command, and changing the `/etc/fstab` file to make that change persistent with the second command:
    ```
    sudo swapoff -a
    ```
    ```
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    ```
4. Create a `Projects` directory and `cd` into it
    ```
    mkdir ~/Projects ; cd ~/Projects
    ```
5. Clone (download locally) the kubernetes-env respository:
    ```
    git clone https://github.com/tsanghan/kubernetes-env.git
    ```
6. Change directory into the new `kubernetes-env` directory:
    ```
    cd ~/Projects/kubernetes-env
    ```
7. Run the prepare-vm.sh script
    ```
    sudo ./prepare-vm.sh
    ```
8. Follow the instructions at the end of the completion of `prepare-vm.sh` script
<br><br>**Note:**   Currently there are NO instructions at the end of this script.<br><br>
9. **Logout of your VM** and then log back into your VM (to refresh your identity.)
    <br><br>**Note:**  The new groups you have been added to will then be in place, you can check this has happened with `id -a`.<br><br>
10. You now have 2 choices to deploy a kubernetes cluster, using *LXD* or *KIND*
    <br><br>**Note:**   As of v1.12.0, you now have a 3rd choice, Kubernetes on Virtualbox/Vagrant.<br><br>

### Kubernetes on LXD

11. We will explore LXD method first
12. Change directory into the kubernetes-on-lxd directory:
    ```
    cd ~/Projects/kubernetes-env/kubernetes-on-lxd
    ```
13. Run the `prepare-lxd.sh` script:
    ```
    prepare-lxd.sh
    ```
    **Note:**  (This script and others are located in your `~/.local` directory, you won't find them in the `~/Projects` tree!)<br><br>
14. Wait until the script finishes.
<br><br>**Note:**  The instructions below will use the control plane node name of **lxd-ctrlp-1**, and worker node names **lxd-cwrkr-1** and **lxd-wrkr-2**.<br><br>
15. You will now initialize your control plane node
    ```
    lxc launch -p k8s-cloud-init focal-cloud lxd-ctrlp-1
    ```
16. The `lxd-ctrlp-1` instance will be created.
17. Launch 2 worker nodes with:
    ```
    lxc launch -p k8s-cloud-init focal-cloud lxd-wrkr-1
    ```
    ```
    lxc launch -p k8s-cloud-init focal-cloud lxd-wrkr-2    
    ```
18. You can watch your nodes finish and then shut down with:
    ```
    watch lxc ls
    ```
19. All 3 lxc nodes should eventually power down after being prepared, this can take several minutes.
<br><br>**Note:**  In order to stop watching the nodes, press `Ctrl-c`.<br><br>
20. Start all of your nodes:
    ```
    $ lxc start --all
    ```
21. Run `kubeadm init` on the control-plane node with the following command:
    ```
    $ lxc exec lxd-ctrlp-1 -- kubeadm init --upload-certs | tee kubeadm-init.out
    ```
22. Wait until `kubeadm` finishes initializing the control-plane node
<br><br>**Note:**  Do NOT clear your screen at this time, you'll need the last couple of lines, starting below where it states `Then you can join any number of worker nodes....`<br>
<br> 
You'll be running the `kubeadm join <etc...>` command on each of your worker nodes.  This command has to be preceeded with the command to cause it to run on the worker node, which is:
    ```
    lxc exec <workernodename> -- (and then the kubeadm join command all the way to the end of the sha hash.)
    ```
23. As an example, when we created this set of steps, we ran the two commands below, using OUR HASH, and you'll need your specific hash to be successful. 
<br><br>**Example:**<br>
<br>**Note:**  If you need the `kubeadm join blah blah` output again, it's located in the `~/Projects/kubernetes-env/kubernetes-on-lxd/kubeadm-init.out` file, at the bottom, so maybe use `tail kubeadm-init.out` to see it easily!<br><br>

    ```
    lxc exec lxd-wrkr-1 -- kubeadm join 10.xxx.xxx.xxx:6443 --token sOm3r3@11yLoNgT@k3n --discovery-token-ca-cert-hash sha256:sOm3r3@11yr3@11yr3@11yr3@11yr3@11yr3@11yLoNgT@k3n
    ```
    ```
    lxc exec lxd-wrkr-2 -- kubeadm join 10.xxx.xxx.xxx:6443 --token sOm3r3@11yLoNgT@k3n --discovery-token-ca-cert-hash sha256:sOm3r3@11yr3@11yr3@11yr3@11yr3@11yr3@11yLoNgT@k3n
    ```
24. Pull the `/etc/kubernetes/admin.conf` from within the **lxd-ctrlp-1** node into your local `~/.kube` directory with the following command:
    ```
    mkdir ~/.kube
    ```
    ```
    lxc file pull lxd-ctrlp-1/etc/kubernetes/admin.conf ~/.kube/config
    ```
25. Activate `kubectl` auto-completion with these commands:
    ```
    source /usr/share/bash-completion/bash_completion
    ```
    ```
    echo 'source <(kubectl completion bash)' >>~/.bashrc
    ```
26. Incorporate the contents of **bash_complete** into your current shell:
    ```
    $ source ~/.bash_complete
    ```
27. Now access your cluster with `kubectl get nodes` command.  
    <br>**Note:**  The kubectl command is aliased to `k`, so you can either abbreviate it or type it out.<br><br>
    ```
    k get no      
    ```
    OR
    ```
    kubectl get nodes
    ```
<br> **Expected Output**<br>
```
NAME          STATUS     ROLES                  AGE     VERSION
lxd-ctrlp-1   NotReady   control-plane,master   2m55s   v1.23.1
lxd-wrker-1   NotReady   <none>                 15s     v1.23.1
lxd-wrker-2   NotReady   <none>                 5s      v1.23.1
```
28. All your nodes are not ready, because we have yet to install a CNI plugin.
29. Install calico so it supports Network Policy 
    ```
    k apply -f https://docs.projectcalico.org/manifests/calico.yaml
    ```
30. Watch your `kubectl get nodes` output for readiness:
    ```
    watch kubectl get nodes
    ```
31. Wait until all nodes are ready, this could take a minute or so.<br>

**Expected Output**<br>
```
NAME          STATUS   ROLES                  AGE     VERSION
lxd-ctrlp-1   Ready    control-plane,master   5m42s   v1.23.2
lxd-wrker-1   Ready    <none>                 3m2s    v1.23.2
lxd-wrker-2   Ready    <none>                 2m52s   v1.23.2
```
**When Ready, output will show your nodes with a Status of `Ready`:** <br>

```
NAME          STATUS   ROLES                  AGE   VERSION
lxd-ctrlp-1   Ready    control-plane,master   19m   v1.23.2
lxd-wrkr-1    Ready    <none>                 14m   v1.23.2
lxd-wrkr-2    Ready    <none>                 12m   v1.23.2
```
**Note:**  In order to stop watching the nodes, press `Ctrl-c`.<br><br>

32. To see all your pods, type:
    ```
    k get all -A
    ```

**Expected Output:** <br>

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
33. Now Run the k-apply.sh script:
    ```
    k-apply.sh
    ```
34. When run, the following services will be installed:
- metrics server
- local path provisioner
- NGINX ingress controller
- metallb
```
NAMESPACE       NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
default         kubernetes                           ClusterIP      10.96.0.1        <none>           443/TCP                      23m
default         svc-deploy-nginx                     LoadBalancer   10.104.3.132     10.127.202.241   80:31880/TCP                 3m41s
ingress-nginx   ingress-nginx-controller             LoadBalancer   10.102.143.1     10.127.202.240   80:30116/TCP,443:30765/TCP   13m
ingress-nginx   ingress-nginx-controller-admission   ClusterIP      10.110.81.97     <none>           443/TCP                      13m
kube-system     kube-dns                             ClusterIP      10.96.0.10       <none>           53/UDP,53/TCP,9153/TCP       23m
kube-system     metrics-server                       ClusterIP      10.107.154.234   <none>           443/TCP                      13m
```
35. There is also a `ingress.yaml` manifest that will deploy an `ingressClass` and a *ingress resource*
36. However, a `Deployment` and a `Service` is missing, waiting to be created.
47. Explore and enjoy the *1x Control-Plane, 2x Workers* Kubernetes cluster
38. Check the memory usage with:
    ```
    $ htop
    ```

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
