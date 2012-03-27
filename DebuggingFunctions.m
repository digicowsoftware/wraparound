//
//  DebuggingFunctions.m
//  Wraparound
//
//  Created by Mark Tyrrell on 11/15/11.
//  Copyright 2011 Digital Cow Software. All rights reserved.
//

#include <sys/sysctl.h>
#include <unistd.h>


#include <err.h>
#include <errno.h>
#include <stdio.h>

int isBeingDebugged() {
	int mib[4];
	size_t bufSize = 0;
	int local_error = 0;
	struct kinfo_proc kp;
	
	mib[0] = CTL_KERN;
	mib[1] = KERN_PROC;
	mib[2] = KERN_PROC_PID;
	mib[3] = getpid();
	
	bufSize = sizeof (kp);
	if ((local_error = sysctl(mib, 4, &kp, &bufSize, NULL, 0)) < 0) {
		perror("Failure calling sysctl");
		return 0;
	}
	if (kp.kp_proc.p_flag & P_TRACED)
		return 1;
	return 0;
}
