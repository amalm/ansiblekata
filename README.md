# Ansible Kata

## Set up Ansible using Docker
In the Kata we will use two Docker containers based on the image [solita/ansible-ssh](https://hub.docker.com/r/solita/ansible-ssh).

The image is pre-installed with [Ansible](https://docs.ansible.com/) and a SSH server.

### Build the Docker image *katabox* to use as a provisioning target
<code>docker build . -tkatabox:latest</code>

Start the containers using <code>docker-compose up</code>.

Two containers are started:
- <code>ansible</code> that is the ansible host from which the Ansible installation is done.
- <code>katabox</code> which is the server we will configure with Ansible.

The following files and directories are mounted from the local file system into the containers:
- <code>/etc/ansible/hosts</code> - this is the ansible inventory containing only one server, <code>katabox</code>.
- <code>.ssh</code> directory contains the SSH public and private keys, provided to bootstrap ssh from the <code>ansible</code> container to the <code>katabox</code>

## Check Ansible
Open the terminal of the <code>ansible</code> container:
<code>docker-compose exec ansible bash</code>
You should have a prompt like:

<code>root@6cccba8846bc:/#</code>.

NOTE: you are now logged in as <code>root</code>. 

Change user to <code>ansible</code>:

<code>su -l ansible</code>.

### Verify the SSH setup
<code>ssh ansible@katabox</code>

After acknowledging the <code>ECDSA key fingerprint</code> challenge, you should see a prompt like:

<code>ansible@d3d20bffe3ad:~$</code>

Exit the <code>katabox</code> with Ctrl-D, you are now back on the <code>ansible</code> container.

### Check inventory
<code>
ansible@6cccba8846bc:~$ ansible all --list-hosts
</code>

You should see something like this:

<code>
  hosts (1):
    katabox
</code>

### Ping all nodes
<code>cd ansibles</code>

<code>ansible all -m ping</code>
<code>
katabox | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
</code>

**We are good to go!**

## Ansible Hello World
There is a playbook prepared in the <code>ansibles</code> folder: <code>helloworldplaybook.yaml</code>.

<code>
ansible@6e1a7eb1db17:~/ansibles$ ansible-playbook helloworldplaybook.yaml

PLAY [Echo] ********************************************************************

TASK [setup] *******************************************************************
ok: [katabox]

TASK [Print debug message] *****************************************************
ok: [katabox] => {
    "msg": "Hello, world!"
}

PLAY RECAP *********************************************************************
katabox                    : ok=2    changed=0    unreachable=0    failed=0
</code>

## Ansible Put a file on a provisioned server
<code>
ansible@6e1a7eb1db17:~/ansibles$ ansible-playbook fileplaybook.yaml

PLAY [Template Play] ***********************************************************

TASK [setup] *******************************************************************
ok: [katabox]

TASK [Put a file on the provisioned environment] *******************************
changed: [katabox]

PLAY RECAP *********************************************************************
katabox                    : ok=2    changed=1    unreachable=0    failed=0
</code>

You can check that the file is actually there:

<code>>
C:\Workspaces\git\katas\ansiblekata>docker-compose exec katabox bash
root@57e755f32680:/# su -l ansible
ansible@57e755f32680:~$ cat file.conf
Hi there!ansible
</code>

## A peak at reusable structures
One Best Practice is to use *roles*. See the playbook <code>fileroleplaybook.yaml</code>.

The code is really compact, the actually code is in <code>ansibles\roles\common\tasks\main.yaml</code>.

Try it out:

<code>
ansible@6e1a7eb1db17:~/ansibles$ ansible-playbook fileroleplaybook.yaml

PLAY [Template Play] ***********************************************************

TASK [setup] *******************************************************************
ok: [katabox]

TASK [common : Put a file on the provisioned environment] **********************
ok: [katabox]

PLAY RECAP *********************************************************************
katabox                    : ok=2    changed=0    unreachable=0    failed=0
</code>

## Install NodeJS
<code>ansible-playbook nodejsplaybook.yaml</code>

### Install a NodeJS file
A JS file like below would start a NodeJS server on the *katabox*.
Add a *role* *webserver* with that snippet to be installed and started.
Verify by opening *http://localhost:3000* in a browser on your local machine.

<code>
const http = require('http');

const hostname = 'katabox';
const port = 3000;

const server = http.createServer((req, res) => {
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello World');
});

server.listen(port, hostname, () => {
  console.log(`Server running at http://${hostname}:${port}/`);
});
</code>

## FAQ
### I get an error like <code>ECDSA host key for katabox has changed</code>
This is due to the fact that when the <code>katabox</code> Docker container is recreated, it gets another host key. Follow the instruction hinted:

<code>ssh-keygen -f "/home/ansible/.ssh/known_hosts" -R katabox</code>

and try again.

<code>
ansible@6cccba8846bc:~$ ssh ansible@katabox
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@       WARNING: POSSIBLE DNS SPOOFING DETECTED!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
The ECDSA host key for katabox has changed,
and the key for the corresponding IP address 172.31.0.2
is unknown. This could either mean that
DNS SPOOFING is happening or the IP address for the host
and its host key have changed at the same time.
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ECDSA key sent by the remote host is
SHA256:6cMrdCbh7ZMCsUlgAx6Pt8eFMawoKj2/1v5soO0qXX0.
Please contact your system administrator.
Add correct host key in /home/ansible/.ssh/known_hosts to get rid of this message.
Offending ECDSA key in /home/ansible/.ssh/known_hosts:5
  remove with:
  ssh-keygen -f "/home/ansible/.ssh/known_hosts" -R katabox
  
  
ECDSA host key for katabox has changed and you have requested strict checking.
Host key verification failed.
</code>

### I get an error like <code>Failed to mount cgroup at /sys/fs/cgroup/systemd: Operation not permitted</code> on a Linux machine

This is if only cGroup v2 is allowed.
To switch to a hybrid mode allowing cGroup v1 and v2 add the following Kernel parameter:

<code>
systemd.unified_cgroup_hierarchy=false
</code>
