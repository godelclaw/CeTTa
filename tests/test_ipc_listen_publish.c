/* A listener's name appears only once it accepts. Watched with inotify, the
 * name arrives by rename, never by creation; a connection made the moment it
 * appears is accepted; its mode is already final; no staged name is left. A
 * stale stage of ours is replaced, anything else there is refused, and a
 * path too long for the stage binds directly. */
#define _GNU_SOURCE
#include "ipc_client.h"
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/inotify.h>
#include <sys/prctl.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <unistd.h>

static int connect_to(const char *path) {
    struct sockaddr_un address={.sun_family=AF_UNIX};
    assert(strlen(path)<sizeof(address.sun_path));strcpy(address.sun_path,path);
    int fd=socket(AF_UNIX,SOCK_STREAM|SOCK_CLOEXEC,0);assert(fd>=0);
    int result=connect(fd,(struct sockaddr *)&address,sizeof(address));
    int saved=errno;close(fd);errno=saved;return result;
}
/* A listener in a child, so the parent watches it come up. */
static pid_t listen_in_child(const char *path) {
    pid_t parent=getpid(),child=fork();assert(child>=0);
    if (!child) {
        /* A failed assertion in the parent must not leave the child behind. */
        if (prctl(PR_SET_PDEATHSIG,SIGKILL) || getppid()!=parent) _exit(3);
        if (cetta_ipc_listen(path,0600,(gid_t)-1,4)<0) _exit(2);
        for (;;) pause();
    }
    return child;
}
static void stop(pid_t child) {
    int status;kill(child,SIGTERM);assert(waitpid(child,&status,0)==child);
}
static void published_when_accepting(const char *dir,unsigned round) {
    char path[108];snprintf(path,sizeof(path),"%s/s%u.sock",dir,round);
    int watch=inotify_init1(IN_CLOEXEC);assert(watch>=0);
    assert(inotify_add_watch(watch,dir,IN_CREATE|IN_MOVED_TO)>=0);
    pid_t child=listen_in_child(path);
    const char *name=strrchr(path,'/')+1;uint32_t mask=0;
    char buffer[4096] __attribute__((aligned(__alignof__(struct inotify_event))));
    while (!mask) {
        ssize_t n=read(watch,buffer,sizeof(buffer));assert(n>0);
        for (char *at=buffer;at<buffer+n;) {
            struct inotify_event *event=(struct inotify_event *)at;
            if (event->len && !strcmp(event->name,name)) {mask=event->mask;break;}
            at+=sizeof(*event)+event->len;
        }
    }
    assert(!connect_to(path));
    assert(mask&IN_MOVED_TO);assert(!(mask&IN_CREATE));
    struct stat st;assert(!stat(path,&st) && S_ISSOCK(st.st_mode) && (st.st_mode&0777)==0600);
    char staged[128];snprintf(staged,sizeof(staged),"%s.bind",path);
    assert(lstat(staged,&st) && errno==ENOENT);
    stop(child);close(watch);assert(!unlink(path));
}
static void stale_stage_replaced_foreign_refused(const char *dir) {
    char path[108],staged[128];
    snprintf(path,sizeof(path),"%s/stale.sock",dir);snprintf(staged,sizeof(staged),"%s.bind",path);
    /* A socket left at the stage by an interrupted start. */
    struct sockaddr_un address={.sun_family=AF_UNIX};strcpy(address.sun_path,staged);
    int left=socket(AF_UNIX,SOCK_STREAM|SOCK_CLOEXEC,0);assert(left>=0);
    assert(!bind(left,(struct sockaddr *)&address,sizeof(address)));close(left);
    int fd=cetta_ipc_listen(path,0600,(gid_t)-1,4);assert(fd>=0);
    struct stat st;assert(lstat(staged,&st) && errno==ENOENT);
    assert(!connect_to(path));close(fd);assert(!unlink(path));
    /* Anything else at the stage is not ours to remove. */
    int file=open(staged,O_CREAT|O_EXCL|O_WRONLY|O_CLOEXEC,0600);assert(file>=0);close(file);
    assert(cetta_ipc_listen(path,0600,(gid_t)-1,4)<0);
    assert(!lstat(staged,&st) && S_ISREG(st.st_mode));
    assert(lstat(path,&st) && errno==ENOENT);
    assert(!unlink(staged));
}
static void long_path_binds_directly(const char *dir) {
    char path[108];size_t base=strlen(dir)+1;
    assert(base+8<sizeof(path)-1);
    /* As long as a socket path may be: the stage suffix no longer fits. */
    memset(path,0,sizeof(path));memcpy(path,dir,base-1);path[base-1]='/';
    memset(path+base,'p',sizeof(path)-1-base);
    int fd=cetta_ipc_listen(path,0600,(gid_t)-1,4);assert(fd>=0);
    assert(!connect_to(path));close(fd);assert(!unlink(path));
}

int main(void) {
    const char *root=getenv("TMPDIR");char dir[64];
    snprintf(dir,sizeof(dir),"%s/ipc-publish-XXXXXX",root && *root && strlen(root)<24 ? root : "/tmp");
    assert(mkdtemp(dir));
    for (unsigned round=0;round<50;round++) published_when_accepting(dir,round);
    stale_stage_replaced_foreign_refused(dir);
    long_path_binds_directly(dir);
    assert(!rmdir(dir));
    puts("PASS: a listener's name appears only once it accepts");
    return 0;
}
