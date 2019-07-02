#!/bin/bash
yes N | sudo dpkg -i pi_stretch_motion_4.2.2-1_armhf.deb
sudo apt-get install -f
sudo cp motion.conf /etc/motion/
sudo cp motion /etc/default
sudo systemctl restart motion
