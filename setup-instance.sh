#!/bin/bash

main_function() {
USER='ubuntu'
apt-get update -y
apt-get install wget git python3 python3-pip python3-venv unzip nginx jq rustc cargo ffmpeg -y

# Install cuda
wget -O /etc/apt/preferences.d/cuda-repository-pin-600 https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub
add-apt-repository "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /" -y
apt-get update -y
apt-get install cuda-11-8 -y
sudo -c "echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc" $USER

# Add apps
su -c "wget -O /home/$USER/gradio-apps.json https://raw.githubusercontent.com/carlgira/oci-gradio-app-manager/main/gradio-apps.json" $USER
su -c "wget -O /home/$USER/add-gradio-app.sh https://raw.githubusercontent.com/carlgira/oci-gradio-app-manager/main/add-gradio-app.sh" $USER
su -c "sh /home/$USER/add-gradio-app.sh /home/$USER/gradio-apps.json" $USER

}

main_function 2>&1 >> /var/log/startup.log

