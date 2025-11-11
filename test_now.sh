#!/bin/bash
cd /home/eie/ns-allinone-3.35/ns-3.35
./waf build && ./waf --run "scratch/routing --architecture=0 --N_Vehicles=20 --N_RSUs=2 --simTime=10"
