FROM mcr.microsoft.com/devcontainers/base:jammy

# Update and install common dependencies, GH CLI, Azure CLI & PowerShell
RUN apt-get update && \
	apt-get upgrade -y && \
	apt-get install -y apt-transport-https software-properties-common git curl wget jq unzip && \
	apt-get update && \
	apt-get install -y libusb-1.0-0 && \
	apt-get install -y cmake && \
	apt-get clean

# Install IAR Embedded Workbench for ARM
RUN curl -s -O https://updates.iar.com/FileStore/STANDARD/001/003/322/cxarm-9.60.3.deb && \
    dpkg -i cxarm-9.60.3.deb && \
    rm cxarm-9.60.3.deb