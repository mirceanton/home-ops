FROM ubuntu:22.04

# Create user
RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1000 mike
RUN  echo 'mike:   ' | chpasswd

# Update Packages and install basic tools
RUN apt update && apt upgrade -y && apt install git curl wget unzip sudo iproute2 -y

# Install taskfile
RUN cd /tmp && \
    wget --no-check-certificate https://github.com/go-task/task/releases/download/v3.29.1/task_linux_amd64.deb && \
    dpkg -i task_linux_amd64.deb

# Clone this repository
RUN mkdir /workspace && \
    cd /workspace && \
    git clone https://github.com/mirceanton/home-ops
WORKDIR /workspace/home-ops

# Install required tools
RUN task tools

# Set up ssh server
RUN apt install openssh-server -y
RUN service ssh start
EXPOSE 22

ENTRYPOINT [ "/bin/bash" ]
CMD [ "sleep", "infinity" ]
