#!/usr/bin/env bash
# Determine type/speed of the processor(s) on a Mac

system_profiler SPHardwareDataType

echo "Processor Type:" && echo

sysctl -n machdep.cpu.brand_string

echo
