FROM ubuntu:22.04

# Update Packages and install basic tools
RUN apt update && apt upgrade -y && apt install git curl wget unzip sudo -y

# Install taskfile
RUN wget --no-check-certificate https://github.com/go-task/task/releases/download/v3.29.1/task_linux_amd64.deb && \
    dpkg -i task_linux_amd64.deb

# Install required tools
RUN git config --global http.sslVerify false && \
    git clone https://github.com/mirceanton/home-ops && \
    cd home-ops && \
    task tools
