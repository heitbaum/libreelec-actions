#!/bin/bash
git clone https://github.com/LibreELEC/LibreELEC.tv.git
git checkout 10.0.1
cd LibreELEC.tv
pwd 
ls -al
PROJECT=Amlogic ARCH=arm DEVICE=AMLGX  tools/download-tool

PROJECT=Amlogic ARCH=arm DEVICE=AMLGX  make image