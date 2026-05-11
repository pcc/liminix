#include <linux/mount.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <errno.h>

#include <asm/setup.h>		/* for COMMAND_LINE_SIZE */
#include <bits/syscall.h>

#include "activate.h"

#define AVER(c) do { if(c < 0) { dprintf(2, "failed: %s: error=0x%x\n", #c, errno); } } while(0)

char * pr_u32(int32_t input);

static void die() {
    /* if init exits, it causes a kernel panic. On the Turris
     * Omnia (and maybe other hardware, I don't know), the kernel
     * panics _before_ any of the messages from AVER are printed,
     * which makes it really hard to tell what went wrong.  So
     * let's wait a little here to give the console a chance to
     * catch up.
     *
     * Yes, I know that file descriptor IO is supposedly
     * non-buffered. Empirical observation suggests that there
     * must be a buffer of some kind somewhere though.
     */

    sleep(10);
    exit(1);
}

char banner[]  = "Running pre-init...\n";

int main(int argc, char *argv[], char *envp[])
{
    write(1, banner, strlen(banner));

    AVER(mount("none", "/nix", "tmpfs", 0, NULL));
    AVER(mkdir("/nix/persist", 0755));
    AVER(syscall(__NR_pivot_root, "/nix", "/nix/persist"));

    AVER(mkdir("/nix", 0755));
    AVER(mount("/persist/nix", "/nix", "bind", MS_BIND, 0));

    activate();

    argv[0] = "init";
    argv[1] = NULL;
    AVER(execve("/bin/init", argv, envp));

    die();
}
