//
//  DebuggingFunctions.h
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

int isBeingDebugged();
