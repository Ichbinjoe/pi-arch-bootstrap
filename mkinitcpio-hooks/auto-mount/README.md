# Auto-Format

This module is a mkinitcpio module which on earlyhook, looks at all disks on
the system, and if not formatted with one partition will format them.

The module will then set up fstab to mount all disks
