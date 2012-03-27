//
//  GetParentPID.m
//  Wraparound
//
//  Created by Mark Tyrrell on 11/15/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//
// Credit to Dirk @ http://www.objectpark.net/parentpid.html

#include <sys/sysctl.h>

#define OPProcessValueUnknown UINT_MAX

int OPParentIDForProcessID(int pid) {
    struct kinfo_proc info;
    size_t length = sizeof(struct kinfo_proc);
    int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, pid };
    if (sysctl(mib, 4, &info, &length, NULL, 0) < 0)
        return OPProcessValueUnknown;
    if (length == 0)
        return OPProcessValueUnknown;
    return info.kp_eproc.e_ppid;
}
