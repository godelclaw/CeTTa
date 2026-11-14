/* Test-only fault injection for native storage writes, loaded with LD_PRELOAD.
 * While the file named by CETTA_STORE_FAULT_ARM exists, its first word selects
 * one fault; each injection appends one line to CETTA_STORE_FAULT_MARKER.
 *   segment     write() to a store segment fails with ENOSPC
 *   torn        the first write() to a store segment is cut short; later ones fail
 *   rename      renameat() onto a store's root.csl fails with ENOSPC
 *   rename-eio  renameat() onto a store's root.csl fails with EIO
 *   dirsync     fsync() of a directory syncs it, then reports EIO
 *   journal     the first write() to a space journal is cut short; later ones fail
 * Only the program's own calls are seen, not glibc's internal ones. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdlib.h>

static void mode(char word[32]) {
    memset(word,0,32);
    const char *path=getenv("CETTA_STORE_FAULT_ARM");
    if (!path) return;
    int saved=errno,fd=open(path,O_RDONLY|O_CLOEXEC);
    if (fd>=0) { ssize_t n=read(fd,word,31);close(fd);if (n<0) n=0;word[n]=0;word[strcspn(word," \t\r\n")]=0; }
    errno=saved;
}
static void mark(const char *what) {
    const char *path=getenv("CETTA_STORE_FAULT_MARKER");
    if (!path) return;
    int saved=errno,fd=open(path,O_WRONLY|O_CREAT|O_APPEND|O_CLOEXEC,0600);
    if (fd>=0) { (void)!write(fd,what,strlen(what));(void)!write(fd,"\n",1);close(fd); }
    errno=saved;
}
static const char *file_name(int fd,char path[4096]) {
    char link[64];snprintf(link,sizeof(link),"/proc/self/fd/%d",fd);
    int saved=errno;ssize_t n=readlink(link,path,4095);errno=saved;
    if (n<=0) return NULL;
    path[n]=0;const char *slash=strrchr(path,'/');return slash ? slash+1 : path;
}
static bool segment_file(const char *name) {
    return name && strlen(name)==44 && !strncmp(name,"segment-",8) && !strcmp(name+40,".csi");
}
static bool cut;
ssize_t write(int fd,const void *bytes,size_t size) {
    static ssize_t (*real)(int,const void *,size_t);
    if (!real) *(void **)(&real)=dlsym(RTLD_NEXT,"write");
    char word[32],path[4096];struct stat st;
    mode(word);
    if (*word && size>1 && !fstat(fd,&st) && S_ISREG(st.st_mode)) {
        const char *name=file_name(fd,path);
        bool segment=segment_file(name),journal=name && !strcmp(name,"journal.csl");
        bool fail=(segment && (!strcmp(word,"segment") || !strcmp(word,"torn"))) || (journal && !strcmp(word,"journal"));
        if (fail && strcmp(word,"segment") && !cut) {
            cut=true;mark(segment ? "torn segment write" : "torn journal write");
            return real(fd,bytes,size/2);
        }
        if (fail) { mark(segment ? "segment write ENOSPC" : "journal write ENOSPC");errno=ENOSPC;return -1; }
    }
    return real(fd,bytes,size);
}
int renameat(int from,const char *old,int to,const char *new) {
    static int (*real)(int,const char *,int,const char *);
    if (!real) *(void **)(&real)=dlsym(RTLD_NEXT,"renameat");
    char word[32];mode(word);
    const char *slash=new ? strrchr(new,'/') : NULL,*name=slash ? slash+1 : new;
    if (name && !strcmp(name,"root.csl")) {
        if (!strcmp(word,"rename")) { mark("rename ENOSPC");errno=ENOSPC;return -1; }
        if (!strcmp(word,"rename-eio")) { mark("rename EIO");errno=EIO;return -1; }
    }
    return real(from,old,to,new);
}
int fsync(int fd) {
    static int (*real)(int);
    if (!real) *(void **)(&real)=dlsym(RTLD_NEXT,"fsync");
    char word[32];struct stat st;mode(word);
    if (!strcmp(word,"dirsync") && !fstat(fd,&st) && S_ISDIR(st.st_mode)) {
        (void)real(fd);mark("directory fsync EIO");errno=EIO;return -1;
    }
    return real(fd);
}
