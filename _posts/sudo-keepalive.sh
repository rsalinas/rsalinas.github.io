#! /bin/bash

sudo -v
while [ -d /proc/$$  ]; do sudo -nv; sleep 3; done &

