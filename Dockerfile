FROM solita/ansible-ssh

ARG USER=ansible

# Add sudo
RUN apt update && apt install sudo -y

# Setup running user on the container with sudo rights and
# password-less ssh login
RUN usermod -aG sudo ansible

RUN echo 'ansible ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers.d/ansible
