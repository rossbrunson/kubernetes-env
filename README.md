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

## Preparing your System
<br>

1. Use a base VM with the above specifications.
2. Bootup and login to your VM.
3. You'll be turning off your systems's use of swap with the first command, and then ensure it's off for future startups by changing the `/etc/fstab` file:
    ```
    sudo swapoff -a
    ```
    ```
    sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
    ```
4. Create a `Projects` directory in your home directory and `cd` into it
    ```
    mkdir ~/Projects ; cd ~/Projects
    ```
5. Clone (download locally) the `kubernetes-env` respository:
    ```
    git clone https://github.com/tsanghan/kubernetes-env.git
    ```
6. Change directory into the new `kubernetes-env` directory:
    ```
    cd ~/Projects/kubernetes-env
    ```
7. Run the `prepare-vm.sh` script
    ```
    sudo ./prepare-vm.sh
    ```
8. Inspect (and write to an output file) your group membership using the `id` command.
    ```
    id -a | tee currentid-a.out
    ```
<br>**Note:**  Your current identity configuration will be shown and also written to `currentid-a.out` file in case you want to see the previous `id` command output.<br><br>

9. **Logout of your VM** and then log back into your VM, then run the `id` command again to see what has changed.
    ```
    id -a | grep 'lxd\|docker' 
    ```
<br> **Expected Output**<br>

<pre>
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu),4(adm),20(dialout),24(cdrom),25(floppy),27(sudo),29(audio),30(dip),44(video),46(plugdev),117(netdev),118(<b>lxd</b>),998(<b>docker</b>)
</pre>

<br>**Note:**  You should see that new groups have been added, such as the `lxd` and `docker` group membership shown in **bold** in the output above.<br><br>

10. You now have 2 choices to deploy a kubernetes cluster, using **LXD** or **KIND**.  As of v1.12.0, you now have a 3rd choice, **Kubernetes on Virtualbox/Vagrant**.<br><br>

## Kubernetes on LXD

11. We will explore LXD method first
12. Change directory into the `kubernetes-on-lxd` directory:
    ```
    cd ~/Projects/kubernetes-env/kubernetes-on-lxd
    ```
13. Run the `prepare-lxd.sh` script:
    ```
    ./prepare-lxd.sh
    ```
**Note:**  This script and others are located in your `~/.local` directory, you won't find them in the `~/Projects` tree!<br><br>

14. Wait until the script finishes.

**Note:**  Do **NOT** at this time run the suggested `lxc launch distro:version` command. 
<br><br>
## Initializing your cluster nodes

First, you should understand that the `lxc` command is your key to sending commands to the LXD container, which holds the nodes you just created.  The `lxc` command "drop ships" or delivers commands into the LXD container, (and even into nodes!), instead of running those commands on your host system's command line.

In this section, You will use the `lxc` command to send commands to your container, aka `lxc launch`, `lxc ls` and `lxc start`, all of which are executed at the __container__ level.

The instructions below will create the control plane node named **lxd-ctrlp-1**, and 2 worker nodes named **lxd-wrkr-1** and **lxd-wrkr-2**.  They will not be a functional cluster yet, just a set of nodes.

**NOTE:**  <br><br>

15. Initialize your control plane node
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
19. **All 3 lxc nodes should eventually power down after being prepared**, this can take several minutes.
<br><br>**Note:**  When all nodes are shut down, press `Ctrl-c` to exit the `watch` command.<br><br>
20. Start all of your nodes:
    ```
    lxc start --all
    ```
<br>**Note:**  If you want to see if your nodes are running, type `watch lxc ls` again.<br>
<br>
## Initializing the Control Plane Node
<br>
In this section, you'll be doing a complex set of inter-related tasks that will end up with your worker nodes properly joined into the cluster you have created with the control plane.

<br>First, you will run a `kubeadm init...` command on the control plane node to generate the certificates and keys needed to allow the worker nodes to join the cluster.  Then you'll run a particular `kubeadm join...` command on **each** of the worker nodes which will join them to the cluster.

To run commands on any of the nodes, you'll preface them with the `lxc exec <nodename> --` string, so the actual `kubeadm` commands will execute **inside** the `<nodename>`, not on your host command line!

**Example:**<br>
    
    lxc exec node1 -- kubeadm somecmd --someoption
    
This example would execute the `kubeadm somecmd` command on `node1`, causing an action on that node only.
<br><br>
## Build the Control Plane Node
<br>

21. First, run `kubeadm init` on the control-plane node with the following command:
   ```
   lxc exec lxd-ctrlp-1 -- kubeadm init --upload-certs | tee kubeadm-init.out
   ```

22. Wait until `kubeadm` finishes initializing the control-plane node, and **TAKE NOTE** of the last couple of lines of output that begin with `kubeadm join 10.xxx.xxx.xxx`.  

**NOTE:** This is the command that you will copy and paste after `lxc exec <nodename> --` to build the join command that must be run on each of your worker nodes to join them to the cluster.  Your cluster's unique `kubadm init...` output is written to the `./kubeadm-init.out` file, which you can view if you need that `kubeadm join...` command again!
<br><br>
## Join the worker nodes to the Cluster
<br>

23. Now it's time to put the two commands together and join both of your worker nodes to the cluster. 
<br><br>**Example:**  Put your commands together similar to this example and execute them as one long command.  The **ONLY** difference between the two commands should be the 1 and 2 in the worker node names.  We recommend you do this in an editor and then copy and paste it into your terminal to execute.<br><br>
    ```
    lxc exec lxd-wrkr-1 -- kubeadm join 10.xxx.xxx.xxx:6443 --token sOm3r3@11yLoNgT@k3n --discovery-token-ca-cert-hash sha256:sOm3r3@11yr3@11yr3@11yr3@11yr3@11yr3@11yLoNgT@k3n
    ```
    ```
    lxc exec lxd-wrkr-2 -- kubeadm join 10.xxx.xxx.xxx:6443 --token sOm3r3@11yLoNgT@k3n --discovery-token-ca-cert-hash sha256:sOm3r3@11yr3@11yr3@11yr3@11yr3@11yr3@11yLoNgT@k3n
    ```

<br>

## Setup your Host to Execute `kube*` commands
<br>

**WARNING:** If you run `kubectl get nodes` or other `kube*` commands at this point, you will almost certainly get the message below:
<pre>
The connection to the server localhost:8080 was refused - did you specify the right host or port?
</pre>
This error is caused by the right configuration files not being present on the local host, which this next section addresses.

24. Pull the `/etc/kubernetes/admin.conf` from within the **lxd-ctrlp-1** node into your local `~/.kube` directory with the following command:
    ```
    mkdir ~/.kube
    ```
    ```
    lxc file pull lxd-ctrlp-1/etc/kubernetes/admin.conf ~/.kube/config
    ```

<br>

## Configure `kubectl` autocompletion
<br>

25. Activate `kubectl` auto-completion with these commands:
    ```
    source /usr/share/bash-completion/bash_completion
    ```
    ```
    echo 'source <(kubectl completion bash)' >>~/.bashrc
    ```
26. Incorporate the contents of **bash_complete** into your current shell:
    ```
    source ~/.bash_complete
    ```
<br>

## NOW Verify Your Cluster Configuration

<br>

27. Now access your cluster with either the actual `kubectl get nodes` command, or use the aliased `k get no` short command.

    ```
    k get no      
    ```
    OR
    ```
    kubectl get nodes
    ```
<br> **Expected Output**<br>
<pre>
NAME          STATUS     ROLES                  AGE     VERSION
lxd-ctrlp-1   <b>NotReady</b>   control-plane,master   2m55s   v1.23.2
lxd-wrker-1   <b>NotReady</b>   <none>                 15s     v1.23.2
lxd-wrker-2   <b>NotReady</b>   <none>                 5s      v1.23.2
</pre>

## Install the Calico Container Network Interface Plugins
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

**Expected Output Before Ready**<br>
<pre>
NAME          STATUS     ROLES                  AGE     VERSION
lxd-ctrlp-1   <b>NotReady</b>   control-plane,master   2m55s   v1.23.2
lxd-wrker-1   <b>NotReady</b>   < none >               15s     v1.23.2
lxd-wrker-2   <b>NotReady</b>   < none >               5s      v1.23.2
</pre>
**When Ready, output will show your nodes with a Status of `Ready`:** <br>

<pre>
NAME          STATUS     ROLES                  AGE     VERSION
lxd-ctrlp-1   <b>Ready</b>   control-plane,master   2m55s   v1.23.2
lxd-wrker-1   <b>Ready</b>   < none >               15s     v1.23.2
lxd-wrker-2   <b>Ready</b>   < none >               5s      v1.23.2
</pre>
**Note:**  In order to stop watching the nodes, press `Ctrl-c`.<br><br>

32. To see all your pods, type:
    ```
    k get all -A
    ```

**Expected Output:** <br>

<pre>
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
</pre>
33. Now Run the `k-apply.sh` script:
    ```
    k-apply.sh
    ```
34. When run, the following services will be installed:
- metrics server
- local path provisioner
- NGINX ingress controller
- metallb
<br><br>
**Expected Output:** <br>

<pre>
NAMESPACE       NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)                      AGE
default         kubernetes                           ClusterIP      10.96.0.1        <none>           443/TCP                      23m
default         svc-deploy-nginx                     LoadBalancer   10.104.3.132     10.127.202.241   80:31880/TCP                 3m41s
ingress-nginx   ingress-nginx-controller             LoadBalancer   10.102.143.1     10.127.202.240   80:30116/TCP,443:30765/TCP   13m
ingress-nginx   ingress-nginx-controller-admission   ClusterIP      10.110.81.97     <none>           443/TCP                      13m
kube-system     kube-dns                             ClusterIP      10.96.0.10       <none>           53/UDP,53/TCP,9153/TCP       23m
kube-system     metrics-server                       ClusterIP      10.107.154.234   <none>           443/TCP                      13m
</pre>
35. There is also a `ingress.yaml` manifest that will deploy an `ingressClass` and a *ingress resource*
36. However, a `Deployment` and a `Service` is missing, waiting to be created.

### Explore and enjoy the *1x Control-Plane, 2x Workers* Kubernetes cluster
37. Check the memory usage with:
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
