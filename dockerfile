# syntax=docker/dockerfile:1
FROM ubuntu:20.04
RUN apt update
RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata
RUN apt install -y curl gnupg lsb lsb-release software-properties-common python3-pip jq openssh-client
RUN curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
RUN apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
RUN apt install -y terraform
RUN pip install ansible
COPY scriptVM/ /home/sysadmin/scriptVM/
COPY .ssh /root/.ssh