.\" Copyright (c) 1980 Regents of the University of California.
.\" All rights reserved.  The Berkeley software License Agreement
.\" specifies the terms and conditions for redistribution.
.\"
.\"	@(#)6.t	6.1 (Berkeley) 5/14/86
.\"
.de IR
\fI\\$1\fP\|\\$2
..
.ds LH "Installing/Operating \*(4B
.nr H1 6
.nr H2 0
.ds RH "System Operation
.ds CF \*(DY
.bp
.LG
.B
.ce
6. SYSTEM OPERATION
.sp 2
.R
.NL
.PP
This section describes procedures used to operate a VAX UNIX system.
Procedures described here are used periodically, to reboot the system,
analyze error messages from devices, do disk backups, monitor
system performance, recompile system software and control local changes.
.NH 2
Bootstrap and shutdown procedures
.PP
In a normal reboot, the system checks the disks and comes up multi-user
without intervention at the console.
Such a reboot
can be stopped (after it prints the date) with a ^C (interrupt).
This will leave the system in single-user mode, with only the console
terminal active.
It is also possible to allow the filesystem checks to complete
and then to return to single-user mode by signaling \fIfsck\fP
with a QUIT signal (^\).
.PP
If booting from the console command level is needed, then the command
.DS
\fB>>>\fP B
.DE
will boot from the default device.
On an 8650, 8600, 11/785, 11/780, or 11/730 the default device is
determined by a ``DEPOSIT''
command stored on the console boot device in the file ``DEFBOO.CMD''
(``DEFBOO.COM'' on an 8650 or 8600);
on an 11/750 the default device is determined by the setting of a switch
on the front panel.
.PP
You can boot a system up single user
on an 8650, 8600, 785, 780, or 730 by doing
.DS
\fB>>>\fP B \fIXX\fP\|S
.DE
where \fIXX\fP is one of HP, HK, UP, RA, or RB for a 730.
The corresponding command on an 11/750 is
.DS
\fB>>>\fP B/2
.DE
.PP
For second vendor storage modules on the
UNIBUS or MASSBUS of an 11/750 you will need to
have a boot prom.  Most vendors will sell you
such proms for their controllers; contact your vendor
if you don't have one.
.PP
Other possibilities are:
.DS
\fB>>>\fP B ANY
.DE
or, on a 750
.DS
\fB>>>\fP B/3
.DE
These commands boot and ask for the name of the system to be booted.
They can be used after building a new test system to give the
boot program the name of the test version of the system.
.PP
To bring the system up to a multi-user configuration from the single-user
status after, e.g., a ``B HPS'' on an 8650, 8600, 11/785 or 11/780, ``B RBS''
on a 11/730, or a ``B/2'' on an
11/750 all you have to do is hit ^D on the console.  The system
will then execute /etc/rc,
a multi-user restart script (and /etc/rc.local),
and come up on the terminals listed as
active in the file /etc/ttys.
See
\fIinit\fP\|(8)
and
\fIttys\fP\|(5).
Note, however, that this does not cause a file system check to be performed.
Unless the system was taken down cleanly, you should run
``fsck \-p'' or force a reboot with
\fIreboot\fP\|(8)
to have the disks checked.
.PP
To take the system down to a single user state you can use
.DS
\fB#\fP kill 1
.DE
or use the
\fIshutdown\fP\|(8)
command (which is much more polite, if there are other users logged in.)
when you are up multi-user.
Either command will kill all processes and give you a shell on the console,
as if you had just booted.  File systems remain mounted after the
system is taken single-user.  If you wish to come up multi-user again, you
should do this by:
.DS
\fB#\fP cd /
\fB#\fP /etc/umount -a
\fB#\fP ^D
.DE
.PP
Each system shutdown, crash, processor halt and reboot
is recorded in the file /usr/adm/shutdownlog
with the cause.
.NH 2
Device errors and diagnostics
.PP
When serious errors occur on peripherals or in the system, the system
prints a warning diagnostic on the console.
These messages are collected
by the system error logging process
.IR syslogd (8)
and written into a system error log file
\fI/usr/adm/messages\fP.
Less serious errors are sent directly to \fIsyslogd\fP,
which may log them on the console.
The error priorities that are logged and the locations to which they are logged
are controlled by \fI/etc/syslog.conf\fP.  See
.IR syslogd (8)
for details.
.PP
Error messages printed by the devices in the system are described with the
drivers for the devices in section 4 of the programmer's manual.
If errors occur suggesting hardware problems, you should contact
your hardware support group or field service.  It is a good idea to
examine the error log file regularly
(e.g. with ``tail \-r \fI/usr/adm/messages\fP'').
.NH 2
File system checks, backups and disaster recovery
.PP
Periodically (say every week or so in the absence of any problems)
and always (usually automatically) after a crash,
all the file systems should be checked for consistency
by
\fIfsck\fP\|(1).
The procedures of
\fIreboot\fP\|(8)
should be used to get the system to a state where a file system
check can be performed manually or automatically.
.PP
Dumping of the file systems should be done regularly,
since once the system is going it is easy to
become complacent.
Complete and incremental dumps are easily done with
\fIdump\fP\|(8).
You should arrange to do a towers-of-hanoi dump sequence; we tune
ours so that almost all files are dumped on two tapes and kept for at
least a week in most every case.  We take full dumps every month (and keep
these indefinitely).
Operators can execute ``dump w'' at login that will tell them what needs
to be dumped
(based on the /etc/fstab
information).
Be sure to create a group
.B operator
in the file /etc/group
so that dump can notify logged-in operators when it needs help.
.PP
More precisely, we have three sets of dump tapes: 10 daily tapes,
5 weekly sets of 2 tapes, and fresh sets of three tapes monthly.
We do daily dumps circularly on the daily tapes with sequence
`3 2 5 4 7 6 9 8 9 9 9 ...'.
Each weekly is a level 1 and the daily dump sequence level
restarts after each weekly dump.
Full dumps are level 0 and the daily sequence restarts after each full dump
also.
.PP
Thus a typical dump sequence would be:
.br
.ne 6
.KS
.TS
center;
c c c c c
n n n l l.
tape name	level number	date	opr	size
_
FULL	0	Nov 24, 1979	jkf	137K
D1	3	Nov 28, 1979	jkf	29K
D2	2	Nov 29, 1979	rrh	34K
D3	5	Nov 30, 1979	rrh	19K
D4	4	Dec 1, 1979	rrh	22K
W1	1	Dec 2, 1979	etc	40K
D5	3	Dec 4, 1979	rrh	15K
D6	2	Dec 5, 1979	jkf	25K
D7	5	Dec 6, 1979	jkf	15K
D8	4	Dec 7, 1979	rrh	19K
W2	1	Dec 9, 1979	etc	118K
D9	3	Dec 11, 1979	rrh	15K
D10	2	Dec 12, 1979	rrh	26K
D1	5	Dec 15, 1979	rrh	14K
W3	1	Dec 17, 1979	etc	71K
D2	3	Dec 18, 1979	etc	13K
FULL	0	Dec 22, 1979	etc	135K
.TE
.KE
We do weekly dumps often enough that daily dumps always fit on one tape.
.PP
Dumping of files by name is best done by
\fItar\fP\|(1)
but the amount of data that can be moved in this way is limited
to a single tape.
Finally if there are enough drives entire
disks can be copied with
\fIdd\fP\|(1)
using the raw special files and an appropriate
blocking factor; the number of sectors per track is usually
a good value to use, consult \fI/etc/disktab\fP.
.PP
It is desirable that full dumps of the root file system be
made regularly.
This is especially true when only one disk is available.
Then, if the
root file system is damaged by a hardware or software failure, you
can rebuild a workable disk doing a restore in the
same way that the initial root file system was created.
.PP
Exhaustion of user-file space is certain to occur
now and then; disk quotas may be imposed, or if you
prefer a less facist approach, try using the programs
\fIdu\fP\|(1),
\fIdf\fP\|(1),
\fIquot\fP\|(8),
combined with threatening
messages of the day, and personal letters.
.NH 2
Moving file system data
.PP
If you have the equipment,
the best way to move a file system
is to dump it to magtape using
\fIdump\fP\|(8),
use
\fInewfs\fP\|(8)
to create the new file system,
and restore the tape, using \fIrestore\fP\|(8).
If for some reason you don't want to use magtape,
dump accepts an argument telling where to put the dump;
you might use another disk.
Filesystems may also be moved by piping the output of \fIdump\fP
to \fIrestore\fP.
The \fIrestore\fP program uses an ``in-place'' algorithm that
allows file system dumps to be restored without concern for the
original size of the file system.  Further, portions of a
file system may be selectively restored using a method similar
to the tape archive program.
.PP
If you have to merge a file system into another, existing one,
the best bet is to
use \fItar\fP\|(1).
If you must shrink a file system, the best bet is to dump
the original and restore it onto the new file system.
If you
are playing with the root file system and only have one drive,
the procedure is more complicated.
If the only drive is a Winchester disk, this procedure may not be used
without overwriting the existing root or another partition.
What you do is the following:
.IP 1.
GET A SECOND PACK!!!!
.IP 2.
Dump the root file system to tape using
\fIdump\fP\|(8).
.IP 3.
Bring the system down and mount the new pack.
.IP 4.
Load the distribution tape and install the new
root file system as you did when first installing the system.
.IP 5.
Boot normally
using the newly created disk file system.
.PP
Note that if you change the disk partition tables or add new disk
drivers they should also be added to the standalone system in
\fI/sys/stand\fP and the default disk partition tables in \fI/etc/disktab\fP
should be modified.
.NH 2
Monitoring System Performance
.PP
The
.I systat
program provided with the system is designed to be an aid to monitoring
systemwide activity.  The default ``pigs'' mode shows a dynamic ``ps''.
By running in the ``vmstat'' mode
when the system is active you can judge the system activity in several
dimensions: job distribution, virtual memory load, paging and swapping
activity, device interrupts, and disk and cpu utilization.
Ideally, there should be few blocked (b) jobs,
there should be little paging or swapping activity, there should
be available bandwidth on the disk devices (most single arms peak
out at 20-30 tps in practice), and the user cpu utilization (us) should
be high (above 50%).
.PP
If the system is busy, then the count of active jobs may be large,
and several of these jobs may often be blocked (b).  If the virtual
memory is active, then the paging demon will be running (sr will
be non-zero).  It is healthy for the paging demon to free pages when
the virtual memory gets active; it is triggered by the amount of free
memory dropping below a threshold and increases its pace as free memory
goes to zero.
.PP
If you run in the ``vmstat'' mode
when the system is busy, you can find
imbalances by noting abnormal job distributions.  If many
processes are blocked (b), then the disk subsystem
is overloaded or imbalanced.  If you have several non-dma
devices or open teletype lines that are ``ringing'', or user programs
that are doing high-speed non-buffered input/output, then the system
time may go high (60-70% or higher).
It is often possible to pin down the cause of high system time by
looking to see if there is excessive context switching (cs), interrupt
activity (in) and per-device interrupt counts,
or system call activity (sy).  Cumulatively on one of
our large machines we average about 60-100 context switches and interrupts
per second and about 70-120 system calls per second.
.PP
If the system is heavily loaded, or if you have little memory
for your load (2M is little in most any case), then the system
may be forced to swap.  This is likely to be accompanied by a noticeable
reduction in system performance and pregnant pauses when interactive
jobs such as editors swap out.
If you expect to be in a memory-poor environment
for an extended period you might consider administratively
limiting system load.
.NH 2
Recompiling and reinstalling system software
.PP
It is easy to regenerate the system, and it is a good
idea to try rebuilding pieces of the system to build confidence
in the procedures.
The system consists of two major parts:
the kernel itself (/sys) and the user programs
(/usr/src and subdirectories).
The major part of this is /usr/src.
.PP
The three major libraries are the C library in /usr/src/lib/libc
and the \s-2FORTRAN\s0 libraries /usr/src/usr.lib/libI77 and
/usr/src/usr.lib/libF77.  In each
case the library is remade by changing into the corresponding directory
and doing
.DS
\fB#\fP make
.DE
and then installed by
.DS
\fB#\fP make install
.DE
Similar to the system,
.DS
\fB#\fP make clean
.DE
cleans up.
.PP
The source for all other libraries is kept in subdirectories of
/usr/src/usr.lib; each has a makefile and can be recompiled by the above
recipe.
.PP
If you look at /usr/src/Makefile, you will see that
you can recompile the entire system source with one command.
To recompile a specific program, find
out where the source resides with the \fIwhereis\fP\|(1)
command, then change to that directory and remake it
with the makefile present in the directory.
For instance, to recompile ``date'', 
all one has to do is
.DS
\fB#\fP whereis date
\fBdate: /usr/src/bin/date.c /bin/date /usr/man/man1/date.1\fP
\fB#\fP cd /usr/src/bin
\fB#\fP make date
.DE
this will create an unstripped version of the binary of ``date''
in the current directory.  To install the binary image, use the
install command as in
.DS
\fB#\fP install \-s date /bin/date
.DE
The \-s option will insure the installed version of date has
its symbol table stripped.  The install command should be used
instead of mv or cp as it understands how to install programs
even when the program is currently in use.
.PP
If you wish to recompile and install all programs in a particular
target area you can override the default target by doing:
.DS
\fB#\fP make
\fB#\fP make DESTDIR=\fIpathname\fP install
.DE
.PP
To regenerate all the system source you can do
.DS
\fB#\fP cd /usr/src
\fB#\fP make
.DE
.PP
If you modify the C library, say to change a system call,
and want to rebuild and install everything from scratch you
have to be a little careful.
You must insure that the libraries are installed before the
remainder of the source, otherwise the loaded images will not
contain the new routine from the library.  The following
sequence will accomplish this.
.DS
\fB#\fP cd /usr/src
\fB#\fP make clean
\fB#\fP make build
\fB#\fP make installsrc
.DE
The first \fImake\fP removes any existing binaries in the source trees
to insure that everything is reloaded.
The next \fImake\fP compiles and installs the libraries and compilers,
then compiles the remainder of the sources.
The final line installs all of the commands not installed in the first phase.
This will take about 18 hours on a reasonably configured 11/750.
.NH 2
Making local modifications
.PP
To keep track of changes to system source we migrate changed
versions of commands in /usr/src/bin, /usr/src/usr.bin, and /usr/src/ucb
in through the directory /usr/src/new
and out of the original directory into /usr/src/old for
a time before removing them.
(/usr/new is also used by default for the programs that constitute
the contributed software portion of the distribution.)
Locally written commands that aren't distributed are kept in /usr/src/local
and their binaries are kept in /usr/local.  This allows /usr/bin, /usr/ucb,
and /bin to correspond to the distribution tape (and to the manuals that
people can buy).  People wishing to use /usr/local commands are made
aware that they aren't in the base manual.  As manual updates incorporate
these commands they are moved to /usr/ucb.
.PP
A directory, /usr/junk, to throw garbage into, as well as binary directories,
/usr/old and /usr/new, are useful.  The man command supports manual
directories such as /usr/man/mano for old and /usr/man/manl for local
to make this or something similar practical.
.NH 2
Accounting
.PP
UNIX optionally records two kinds of accounting information:
connect time accounting and process resource accounting.  The connect
time accounting information is stored in the file \fI/usr/adm/wtmp\fP, which
is summarized by the program
.IR ac (8).
The process time accounting information is stored in the file
\fI/usr/adm/acct\fP after it is enabled by
.IR accton (8),
and is analyzed and summarized by the program
.IR sa (8).
.PP
If you need to recharge for computing time, you can develop
procedures based on the information provided by these commands.
A convenient way to do this is to give commands to the clock daemon
.I /etc/cron
to be executed every day at a specified time.  This is done by adding
lines to \fI/usr/adm/crontab\fP; see
.IR cron (8)
for details.
.NH 2
Resource control
.PP
Resource control in the current version of UNIX is more
elaborate than in most UNIX systems.  The disk quota
facilities developed at the University of Melbourne have
been incorporated in the system and allow control over the
number of files and amount of disk space each user may use
on each file system.  In addition, the resources consumed
by any single process can be limited by the mechanisms of
\fIsetrlimit\fP\|(2).  As distributed, the latter mechanism
is voluntary, though sites may choose to modify the login
mechanism to impose limits not covered with disk quotas.
.PP
To use the disk quota facilities, the system must be
configured with ``options QUOTA''.  File systems may then
be placed under the quota mechanism by creating a null file
.I quotas
at the root of the file system, running
.IR quotacheck (8),
and modifying \fI/etc/fstab\fP to show that the file system is read-write
with disk quotas (an ``rq'' type field).  The
.IR quotaon (8)
program may then be run to enable quotas.
.PP
Individual quotas are applied by using the quota editor
.IR edquota (8).
Users may view their quotas (but not those of other users) with the
.IR quota (1)
program.  The 
.IR repquota (8)
program may be used to summarize the quotas and current
space usage on a particular file system or file systems.
.PP
Quotas are enforced with 
.I soft
and
.I hard
limits.  When a user first reaches a soft limit on a resource, a
message is generated on his/her terminal.  If the user fails to
lower the resource usage below the soft limit the next time
they log in to the system the
.I login
program will generate a warning about excessive usage.  Should
three login sessions go by with the soft limit breached the
system then treats the soft limit as a
.I hard
limit and disallows any allocations until enough space is
reclaimed to bring the user back below the soft limit.  Hard
limits are enforced strictly resulting in errors when a user
tries to create or write a file.  Each time a hard limit is
exceeded the system will generate a message on the user's 
terminal.
.PP
Consult the auxiliary document, ``Disc Quotas in a UNIX Environment''
and the appropriate manual entries for more information.
.NH 2
Network troubleshooting
.PP
If you have anything more than a trivial network configuration,
from time to time you are bound to run into problems.  Before
blaming the software, first check your network connections.  On
networks such as the Ethernet a
loose cable tap or misplaced power cable can result in severely
deteriorated service.  The \fInetstat\fP\|(1) program may be of
aid in tracking down hardware malfunctions.  In particular, look
at the \fB\-i\fP and \fB\-s\fP options in the manual page.
.PP
Should you believe a communication protocol problem exists,
consult the protocol specifications and attempt to isolate the
problem in a packet trace.  The SO_DEBUG option may be supplied
before establishing a connection on a socket, in which case the
system will trace all traffic and internal actions (such as timers
expiring) in a circular trace buffer.  This buffer may then
be printed out with the \fItrpt\fP\|(8C) program.  Most of the
servers distributed with the system accept a \fB\-d\fP option forcing
all sockets to be created with debugging turned on.  Consult the
appropriate manual pages for more information.
.NH 2
Files that need periodic attention
.PP
We conclude the discussion of system operations by listing
the files that require periodic attention or are system specific
.de BP
.IP \fB\\$1\fP
.br
..
.TS
center;
lb a.
/etc/fstab	how disk partitions are used
/etc/disktab	disk partition sizes
/etc/printcap	printer data base
/etc/gettytab	terminal type definitions
/etc/remote	names and phone numbers of remote machines for \fItip\fP(1)
/etc/group	group memberships
/etc/motd	message of the day
/etc/passwd	password file; each account has a line
/etc/rc.local	local system restart script; runs reboot; starts daemons
/etc/inetd.conf	local internet servers
/etc/hosts	host name data base
/etc/networks	network name data base
/etc/services	network services data base
/etc/hosts.equiv	hosts under same administrative control
/etc/syslog.conf	error log configuration for \fIsyslogd\fP\|(8)
/etc/ttys	enables/disables ports
/usr/lib/crontab	commands that are run periodically
/usr/lib/aliases	mail forwarding and distribution groups
/usr/adm/acct	raw process account data
/usr/adm/messages	system error log
/usr/adm/shutdownlog	log of system reboots
/usr/adm/wtmp	login session accounting
.TE
