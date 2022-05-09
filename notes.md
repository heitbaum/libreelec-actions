### Ideas - something for the future
- I could be smarter and build the docker base that is then subsequently used with the .config ???
- ~use concurrecy groups to stop same build target concurrency builds.~
  - ~https://github.blog/changelog/2021-04-19-github-actions-limit-workflow-run-or-job-concurrency/~
  - ~DONE~
- do the nightly runs
  - https://stackoverflow.com/questions/63014786/how-to-schedule-a-github-actions-nightly-build-but-run-it-only-when-there-where
  - https://gist.github.com/jasonrudolph/1810768
  - might need to have a prescript to is dispatch that checks bbefore spawning ....
- how to spawn all the workflows
  - use workflow_run
    - https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_run
  - use workflow_dispatch
  - github actions workflow dispatch
  - https://docs.github.com/en/actions/using-workflows/triggering-a-workflow#triggering-a-workflow-from-a-workflow
  - https://github.blog/2022-02-10-using-reusable-workflows-github-actions/
- reusable workflows
  - https://yonatankra.com/7-github-actions-tricks-i-wish-i-knew-before-i-started/
- other stuff: / subworkflow / actions
  - https://github.com/actions/runner/discussions/1419?msclkid=b3843972cf3711ecbe5439078f5daf4c
  - https://github.github.io/actions-cheat-sheet/actions-cheat-sheet.pdf
  - https://www.bing.com/search?q=github+%22uses%22+same+repository&cvid=60fe0aef5c1549db9efa12bca84795ea&aqs=edge..69i57j69i64l2.15260j0j1&FORM=ANAB01&PC=U531
  - https://docs.github.com/en/actions/using-workflows/reusing-workflows#creating-a-reusable-workflow

### Current status / things to understand / work though
- there is only 1 (shared) build-root (dont buiuld the same architecture at the same time - it will lock / fail)
  - it will handle building without clean/distclean, if it needs to be cleaned - then call clean
  - need to adjust clean to clean for a specific directory `build.LibreELEC-Generic.x86_64-11.0-devel`
- there are unique _instX_work directories per image (container)
  - only start one of each image !!! 
  - each image  has the unique key to connect to github
- there is a shared source directory
- there is a shared target directory


### Install ubuntu 22.04 (without docker but with openssh) on the physical hardware.
- the userid choosen to be created on the ubuntu was `docker`
- Install docker on the ubuntu host
  - https://docs.docker.com/engine/install/ubuntu/#installation-methods

```
sudo apt-get update

sudo apt-get install \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

### Prepare the DATA filesystem 
- Create the /var/media/data filesystem
  - `lvcreate -l 100%FREE -n data ubuntu-vg`
  - `mkfs.ext4 -m 0 /dev/ubuntu-vg/data`
  - `echo "/dev/disk/by-id/dm-name-ubuntu--vg-data /var/media/DATA ext4 rw,relatime 0 1" >> /etc/fstab`
  - `mkdir -p /var/media/DATA`
  - `mount /var/media/DATA`
  - `mkdir -p /var/media/DATA/github-actions/{build-root,sources,target}`
  - `chown -R docker:docker /var/media/DATA/github-actions`

### Create the instance 3 of the docker:

```
GH_ACTIONS_TOKEN=<replace_with_token>
docker build --pull -t github-runner3 --build-arg GH_ACTIONS_TOKEN=${GH_ACTIONS_TOKEN} \
  --build-arg INST_WORK=_inst3_work \
  --build-arg INST_NAME=nuc10_inst3 \
  github-runner
```

### to check your inst3 runner is correct:
```
docker run --log-driver none -it github-runner3:latest cat /home/docker/actions-runner/.runner
{
  "agentId": 32,
  "agentName": "nuc10_inst3",
  "poolId": 1,
  "poolName": "Default",
  "serverUrl": "https://pipelines.actions.githubusercontent.com/xxx",
  "gitHubUrl": "https://github.com/heitbaum/libreelec-actions",
  "workFolder": "/var/media/DATA/github-actions/_inst3_work"
}
```

### Run instance 3 of the runner as a daemon (see -d):
Note the instance 3 = `github-runner3`

```
docker run --log-driver none -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/media/DATA/github-actions:/var/media/DATA/github-actions \
  -d -it github-runner3:latest bash /home/docker/runme.sh
```

### cleanup images
```
docker image rm -f github-runner1
docker image rm -f github-runner2
docker image rm -f github-runner3
docker image rm -f github-runner4
```

### Build more instances:
```
GH_ACTIONS_TOKEN=<replace_with_token>
docker build --pull -t github-runner1 --build-arg GH_ACTIONS_TOKEN=${GH_ACTIONS_TOKEN} \
  --build-arg INST_WORK=_inst1_work --build-arg INST_NAME=nuc10_inst1 github-runner
  
docker run --log-driver none -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/media/DATA/github-actions:/var/media/DATA/github-actions \
  -d -it github-runner1:latest bash /home/docker/runme.sh

docker build --pull -t github-runner2 --build-arg GH_ACTIONS_TOKEN=${GH_ACTIONS_TOKEN} \
  --build-arg INST_WORK=_inst2_work --build-arg INST_NAME=nuc10_inst2 github-runner
  
docker run --log-driver none -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/media/DATA/github-actions:/var/media/DATA/github-actions \
  -d -it github-runner2:latest bash /home/docker/runme.sh
  
docker build --pull -t github-runner4 --build-arg GH_ACTIONS_TOKEN=${GH_ACTIONS_TOKEN} \
  --build-arg INST_WORK=_inst4_work --build-arg INST_NAME=nuc10_inst4 github-runner
  
docker run --log-driver none -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/media/DATA/github-actions:/var/media/DATA/github-actions \
  -d -it github-runner4:latest bash /home/docker/runme.sh
```

### create an /etc/rc.local file on the ubuntu
```
touch /etc/rc.local
chmod 755 /etc/rc.local
echo "#!/bin/sh" > /etc/rc.local
# add the docker startups to the rc.local
vi /etc.rc.local 

systemctl status rc-local
systemctl enable rc-local
systemctl start rc-local
```

### Check that your containers are running
```
docker@nuc10:~$ docker ps
CONTAINER ID   IMAGE                   COMMAND                  CREATED          STATUS          PORTS     NAMES
91cfd57dc4dd   github-runner1:latest   "bash /home/docker/r…"   11 seconds ago   Up 10 seconds             exciting_nightingale
f1fdeb68c519   github-runner4:latest   "bash /home/docker/r…"   54 seconds ago   Up 53 seconds             quirky_easley
f3782edf1a7a   github-runner2:latest   "bash /home/docker/r…"   7 minutes ago    Up 7 minutes              peaceful_neumann
b09900fb96e3   gh-libreelec            "make image"             42 minutes ago   Up 42 minutes             angry_mclaren
59c876a3c059   github-runner3:latest   "bash /home/docker/r…"   46 minutes ago   Up 46 minutes             crazy_lalande
```

https://github.com/heitbaum/libreelec-actions/settings/actions/runners

![image](https://user-images.githubusercontent.com/6086324/166673305-ab244d1d-bec3-4f37-8287-ad359f484b3b.png)

### Execute a run

![image](https://user-images.githubusercontent.com/6086324/166674391-609e3227-3929-4215-bc71-916aff6548c8.png)

### Check the build host:
```
docker@nuc10:/var/media/DATA/github-actions$ ls -l *
_inst3_work:
total 28
drwxr-xr-x 3 docker docker 4096 May  4 10:46 _PipelineMapping
drwxr-xr-x 4 docker docker 4096 May  4 10:46 _actions
drwxr-xr-x 4 docker docker 4096 May  4 10:48 _temp
drwxr-xr-x 2 docker docker 4096 May  4 10:46 _tool
drwxr-xr-x 3 docker docker 4096 May  4 10:46 libreelec-actions

build-root:
total 12
drwxr-xr-x 12 docker docker 4096 May  4 11:26 build.LibreELEC-Generic.x86_64-11.0-devel

sources:
total 552
drwxr-xr-x   2 docker docker 4096 May  4 10:59 Jinja2
drwxr-xr-x   2 docker docker 4096 May  4 11:00 Mako
...

target:
total 8
...
```

### Build host details
```
$ dmesg | grep NUC
[    0.000000] DMI: Intel(R) Client Systems NUC10i7FNH/NUC10i7FNB, BIOS FNCML357.0045.2020.0817.1709 08/17/2020

$ lscpu
Architecture:            x86_64
  CPU op-mode(s):        32-bit, 64-bit
  Address sizes:         39 bits physical, 48 bits virtual
  Byte Order:            Little Endian
CPU(s):                  12
  On-line CPU(s) list:   0-11
Vendor ID:               GenuineIntel
  Model name:            Intel(R) Core(TM) i7-10710U CPU @ 1.10GHz
  
$ top - 11:43:05 up  1:17,  3 users,  load average: 19.37, 18.80, 16.68
Tasks: 334 total,  10 running, 324 sleeping,   0 stopped,   0 zombie
%Cpu(s): 69.8 us, 11.0 sy,  0.0 ni, 19.2 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :  64151.6 total,  30210.1 free,   2065.9 used,  31875.6 buff/cache
MiB Swap:   8192.0 total,   8192.0 free,      0.0 used.  61326.6 avail Mem

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
1907015 docker    20   0   98176  83668  24100 R 100.0   0.1   0:04.02 cc1
1903817 docker    20   0   71920  68908   5148 R 100.0   0.1   0:05.62 automake
1906621 docker    20   0  354880 324168  18116 R 100.0   0.5   0:04.36 cc1plus
```

### OTHER STUFF - NOTES to self only

https://devopscube.com/run-docker-in-docker/

```
sudo chgrp docker /var/run/docker.sock
nuc11:~ # mkdir /var/media/DATA/github-actions
nuc11:~ # chown 1000:1000 /var/media/DATA/github-actions
nuc11:~ # cp -dpR LibreELEC.tv/sources /var/media/DATA/github-actions/

# build the github runner (use github-runner/Dockerfile)
docker build --pull -t github-runner github-runner

```

The you can `docker@1a46680e167f:~/actions-runner$ ./run.sh` from within the docker. 
Or `docker run --log-driver none -v /var/run/docker.sock:/var/run/docker.sock -v /var/media/DATA/github-actions:/var/media/DATA/github-actions -it github-runner:latest sh /home/docker/runme.sh` from the host.
