#!/bin/sh
# The following are GC roots:
# /boot: the currently booted configuration.
# /persist/boot: the configuration that will boot next.
# /persist/prevboot: the recovery configuration.
(cd /nix/store && min-list-garbage /boot/etc/nix-store-paths /persist/boot/etc/nix-store-paths /persist/prevboot/etc/nix-store-paths | xargs rm -r)
