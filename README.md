# What's DiskSim?

[DiskSim](http://www.pdl.cmu.edu/DiskSim/index.shtml) is an efficient, accurate, highly-configurable disk system simulator originally developed at the University of Michigan and enhanced at CMU to support research into various aspects of storage subsystem architecture. It is written in C and requires no special system software (just basic POSIX interfaces). DiskSim includes modules for most secondary storage components of interest, including device drivers, buses, controllers, adapters, and disk drives. DiskSim also includes support for a number of externally-provided trace formats and internally-generated synthetic workloads, and includes hooks for inclusion in a larger scale system-level simulator.

# Disksim patching and compiling
This directory is the work of different sources and uploaders combined together
* DIXtrac tool from [Carnegie Mellon University](http://www.pdl.cmu.edu/DiskSim/index.shtml)
* Microsoft SSD extension from [Microsoft.com](https://www.microsoft.com/en-us/download/details.aspx?id=52332)
* 64bit patch from [Western Digital Corp.](https://github.com/westerndigitalcorporation/DiskSim)
* Different patches has been combined together and made some changes to compile the code from different user [PFSsim](https://github.com/myidpt/PFSsim) [benh](https://github.com/benh) [dmeister](https://github.com/dmeister).



## Installation requirement
To compile the all the above code following tools are required
* [Bison](https://www.gnu.org/software/bison/)
* [Flex](https://github.com/westes/flex)
* A 64 bit version of Linux (Ubuntu)

A make file has been added to ease the process to build the disksim 4.0 without individually compiling and patching each module.

### List of changes coming
