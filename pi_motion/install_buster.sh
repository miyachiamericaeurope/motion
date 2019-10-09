#!/bin/bash
#yes N | sudo dpkg -i pi_stretch_motion_4.2.2-1_armhf.deb
#sudo apt-get install -f
sudo cp motion.conf /etc/motion/
sudo cp motion.start_motion_daemon /etc/default/motion
sudo cp motion.initd /etc/init.d/motion
#sudo systemctl daemon-reload
sudo systemctl restart motion
