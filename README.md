# Pi PXE Bootstrap

## Notice: This repository is a work in progress! It should not be viewed as
working, functioning, logical, or even run.

This repository is focused on in a very simple and easy way bootstrapping my
raspberry pi to host itself as a PXE boot server, which my other servers can
then perform a diskless boot off of. The Pi can boot computers in one of two
modes: server mode, where it automatically boots into a fabricated version of
arch (also created by this script) with options for numerous Live CD options,
or which boots straight into the installed operating system with the same
options for LiveCDs to be booted into instead.

Requirements:

This script requires ArchLinux to build the underlying server distro

Server Distrobution: ArchLinux

Current LiveCD Enumeration:

+ Memtest86+
+ Clonezilla
+ Knoppix (Functionality in progress)
+ Support for adding SpinRite (No functionality yet)
