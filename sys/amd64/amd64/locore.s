/*-
 * Copyright (c) 1990 The Regents of the University of California.
 * All rights reserved.
 *
 * This code is derived from software contributed to Berkeley by
 * William Jolitz.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. All advertising materials mentioning features or use of this software
 *    must display the following acknowledgement:
 *	This product includes software developed by the University of
 *	California, Berkeley and its contributors.
 * 4. Neither the name of the University nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *	from: @(#)locore.s	7.3 (Berkeley) 5/13/91
 *	$Id: locore.s,v 1.65 1996/04/26 13:47:37 phk Exp $
 *
 *		originally from: locore.s, by William F. Jolitz
 *
 *		Substantially rewritten by David Greenman, Rod Grimes,
 *			Bruce Evans, Wolfgang Solfrank, Poul-Henning Kamp
 *			and many others.
 */

#include "apm.h"
#include "opt_ddb.h"

#include <sys/errno.h>
#include <sys/syscall.h>
#include <sys/reboot.h>

#include <machine/asmacros.h>
#include <machine/cputypes.h>
#include <machine/psl.h>
#include <machine/pte.h>
#include <machine/specialreg.h>

#include "assym.s"

/*
 *	XXX
 *
 * Note: This version greatly munged to avoid various assembler errors
 * that may be fixed in newer versions of gas. Perhaps newer versions
 * will have more pleasant appearance.
 */

/*
 * PTmap is recursive pagemap at top of virtual address space.
 * Within PTmap, the page directory can be found (third indirection).
 */
	.globl	_PTmap,_PTD,_PTDpde
	.set	_PTmap,PTDPTDI << PDRSHIFT
	.set	_PTD,_PTmap + (PTDPTDI * NBPG)
	.set	_PTDpde,_PTD + (PTDPTDI * PDESIZE)

/*
 * Sysmap is the base address of the kernel page tables.
 * It is a bogus interface for kgdb and isn't used by the kernel itself.
 */
	.set	_Sysmap,_PTmap + (KPTDI * NBPG)

/*
 * APTmap, APTD is the alternate recursive pagemap.
 * It's used when modifying another process's page tables.
 */
	.globl	_APTmap,_APTD,_APTDpde
	.set	_APTmap,APTDPTDI << PDRSHIFT
	.set	_APTD,_APTmap + (APTDPTDI * NBPG)
	.set	_APTDpde,_PTD + (APTDPTDI * PDESIZE)

/*
 * Access to each processes kernel stack is via a region of
 * per-process address space (at the beginning), immediatly above
 * the user process stack.
 */
	.set	_kstack,USRSTACK
	.globl	_kstack

/*
 * Globals
 */
	.data
	ALIGN_DATA		/* just to be sure */

	.globl	tmpstk
	.space	0x2000		/* space for tmpstk - temporary stack */
tmpstk:

	.globl	_boothowto,_bootdev

	.globl	_cpu,_atdevbase,_cpu_vendor,_cpu_id,_bootinfo
	.globl	_cpu_high, _cpu_feature

_cpu:	.long	0				/* are we 386, 386sx, or 486 */
_cpu_id:	.long	0			/* stepping ID */
_cpu_high:	.long	0			/* highest arg to CPUID */
_cpu_feature:	.long	0			/* features */
_cpu_vendor:	.space	20			/* CPU origin code */
_bootinfo:	.space	BOOTINFO_SIZE		/* bootinfo that we can handle */
_atdevbase:	.long	0			/* location of start of iomem in virtual */

_KERNend:	.long	0			/* phys addr end of kernel (just after bss) */
physfree:	.long	0			/* phys addr end of kernel (just after bss) */
upa:	.long	0			/* phys addr end of kernel (just after bss) */
p0s:	.long	0			/* phys addr end of kernel (just after bss) */

	.globl	_IdlePTD
_IdlePTD:	.long	0			/* phys addr of kernel PTD */

_KPTphys:	.long	0			/* phys addr of kernel page tables */

	.globl	_proc0paddr
_proc0paddr:	.long	0			/* address of proc 0 address space */


/**********************************************************************
 *
 * Some handy macros
 *
 */

#define R(foo) ((foo)-KERNBASE)

#define ROUND2PAGE(foo) addl $NBPG-1, foo; andl $~(NBPG-1), foo

#define ALLOCPAGES(foo) \
	movl	R(physfree), %esi ; \
	movl	$((foo)*NBPG), %eax ; \
	addl	%esi, %eax ; \
	movl	%eax, R(physfree) ; \
	movl	%esi, %edi ; \
	movl	$((foo)*NBPG),%ecx ; \
	xorl	%eax,%eax ; \
	cld ; rep ; stosb

/*
 * fillkpt
 *	eax = (page frame address | control | status) == pte
 *	ebx = address of page table
 *	ecx = how many pages to map
 */
#define	fillkpt		\
1:	movl	%eax,(%ebx)	; \
	addl	$NBPG,%eax	; /* increment physical address */ \
	addl	$4,%ebx		; /* next pte */ \
	loop	1b		;

	.text
/**********************************************************************
 *
 * This is where the bootblocks start us, set the ball rolling...
 *
 */
NON_GPROF_ENTRY(btext)

/* Tell the bios to warmboot next time */
	movw	$0x1234,0x472

/* Set up a real frame, some day we may be doing returns */
	pushl	%ebp
	movl	%esp, %ebp

/* Don't trust what the BIOS gives for eflags. */
	pushl	$PSL_KERNEL
	popfl
	mov	%ds, %ax	/* ... or segment registers */
	mov	%ax, %es
	mov	%ax, %fs
	mov	%ax, %gs

	call	recover_bootinfo

/* get onto a stack we know the size of */
	movl	$R(tmpstk),%esp
	mov	%ds, %ax
	mov	%ax, %ss

	call	identify_cpu

/* clear bss */
	movl	$R(_end),%ecx
	movl	$R(_edata),%edi
	subl	%edi,%ecx
	xorl	%eax,%eax
	cld ; rep ; stosb

#if NAPM > 0
	call	_apm_setup	/* ... in i386/apm/apm_setup.s */
#endif /* NAPM */

	call	create_pagetables

/* Now enable paging */
	movl	R(_IdlePTD), %eax
	movl	%eax,%cr3			/* load ptd addr into mmu */
	movl	%cr0,%eax			/* get control word */
	orl	$CR0_PE|CR0_PG,%eax		/* enable paging */
	movl	%eax,%cr0			/* and let's page NOW! */

	pushl	$begin				/* jump to high mem */
	ret

/* now running relocated at KERNBASE where the system is linked to run */
begin:
	/* set up bootstrap stack */
	movl	$_kstack+UPAGES*NBPG,%esp	/* bootstrap stack end location */
	xorl	%eax,%eax			/* mark end of frames */
	movl	%eax,%ebp
	movl	_proc0paddr,%eax
	movl	_IdlePTD, %esi
	movl	%esi,PCB_CR3(%eax)

	/*
	 * Prepare "first" - physical address of first available page
	 * after the kernel+pdir+upages+p0stack+page tables
	 */
	movl	physfree, %esi
	pushl	%esi				/* value of first for init386(first) */
	call	_init386			/* wire 386 chip for unix operation */
	popl	%esi

	.globl	__ucodesel,__udatasel

	pushl	$0				/* unused */
	pushl	__udatasel			/* ss */
	pushl	$0				/* esp - filled in by execve() */
	pushl	$PSL_USER			/* eflags (IOPL 0, int enab) */
	pushl	__ucodesel			/* cs */
	pushl	$0				/* eip - filled in by execve() */
	subl	$(12*4),%esp			/* space for rest of registers */

	pushl	%esp				/* call main with frame pointer */
	call	_main				/* autoconfiguration, mountroot etc */

	addl	$(13*4),%esp			/* back to a frame we can return with */

	/*
	 * now we've run main() and determined what cpu-type we are, we can
	 * enable write protection and alignment checking on i486 cpus and
	 * above.
	 */
#if defined(I486_CPU) || defined(I586_CPU) || defined(I686_CPU)
	cmpl    $CPUCLASS_386,_cpu_class
	je	1f
	movl	%cr0,%eax			/* get control word */
	orl	$CR0_WP|CR0_AM,%eax		/* enable i486 features */
	movl	%eax,%cr0			/* and do it */
#endif
	/*
	 * on return from main(), we are process 1
	 * set up address space and stack so that we can 'return' to user mode
	 */
1:
	movl	__ucodesel,%eax
	movl	__udatasel,%ecx

	movl	%cx,%ds
	movl	%cx,%es
	movl	%ax,%fs				/* double map cs to fs */
	movl	%cx,%gs				/* and ds to gs */
	iret					/* goto user! */

#define LCALL(x,y)	.byte 0x9a ; .long y ; .word x

/*
 * Signal trampoline, copied to top of user stack
 */
NON_GPROF_ENTRY(sigcode)
	call	SIGF_HANDLER(%esp)
	lea	SIGF_SC(%esp),%eax		/* scp (the call may have clobbered the */
						/* copy at 8(%esp)) */
	pushl	%eax
	pushl	%eax				/* junk to fake return address */
	movl	$SYS_sigreturn,%eax		/* sigreturn() */
	LCALL(0x7,0)				/* enter kernel with args on stack */
	hlt					/* never gets here */
	.align	2,0x90				/* long word text-align */
_esigcode:

	.data
	.globl	_szsigcode
_szsigcode:
	.long	_esigcode-_sigcode

/**********************************************************************
 *
 * Recover the bootinfo passed to us from the boot program
 *
 */
recover_bootinfo:
	/*
	 * This code is called in different ways depending on what loaded
	 * and started the kernel.  This is used to detect how we get the
	 * arguments from the other code and what we do with them.
	 *
	 * Old disk boot blocks:
	 *	(*btext)(howto, bootdev, cyloffset, esym);
	 *	[return address == 0, and can NOT be returned to]
	 *	[cyloffset was not supported by the FreeBSD boot code
	 *	 and always passed in as 0]
	 *	[esym is also known as total in the boot code, and
	 *	 was never properly supported by the FreeBSD boot code]
	 *
	 * Old diskless netboot code:
	 *	(*btext)(0,0,0,0,&nfsdiskless,0,0,0);
	 *	[return address != 0, and can NOT be returned to]
	 *	If we are being booted by this code it will NOT work,
	 *	so we are just going to halt if we find this case.
	 *
	 * New uniform boot code:
	 *	(*btext)(howto, bootdev, 0, 0, 0, &bootinfo)
	 *	[return address != 0, and can be returned to]
	 *
	 * There may seem to be a lot of wasted arguments in here, but
	 * that is so the newer boot code can still load very old kernels
	 * and old boot code can load new kernels.
	 */

	/*
	 * The old style disk boot blocks fake a frame on the stack and
	 * did an lret to get here.  The frame on the stack has a return
	 * address of 0.
	 */
	cmpl	$0,4(%ebp)
	je	olddiskboot

	/*
	 * We have some form of return address, so this is either the
	 * old diskless netboot code, or the new uniform code.  That can
	 * be detected by looking at the 5th argument, it if is 0 we
	 * we are being booted by the new unifrom boot code.
	 */
	cmpl	$0,24(%ebp)
	je	newboot

	/*
	 * Seems we have been loaded by the old diskless boot code, we
	 * don't stand a chance of running as the diskless structure
	 * changed considerably between the two, so just halt.
	 */
	 hlt

	/*
	 * We have been loaded by the new uniform boot code.
	 * Lets check the bootinfo version, and if we do not understand
	 * it we return to the loader with a status of 1 to indicate this error
	 */
newboot:
	movl	28(%ebp),%ebx		/* &bootinfo.version */
	movl	BI_VERSION(%ebx),%eax
	cmpl	$1,%eax			/* We only understand version 1 */
	je	1f
	movl	$1,%eax			/* Return status */
	add	$4, %esp		/* pop recover_bootinfo's retaddr */
	leave
	ret

1:
	/*
	 * If we have a kernelname copy it in
	 */
	movl	BI_KERNELNAME(%ebx),%esi
	cmpl	$0,%esi
	je	2f			/* No kernelname */
	movl	$MAXPATHLEN,%ecx	/* Brute force!!! */
	lea	_kernelname-KERNBASE,%edi
	cmpb	$'/',(%esi)		/* Make sure it starts with a slash */
	je	1f
	movb	$'/',(%edi)
	incl	%edi
	decl	%ecx
1:
	cld
	rep
	movsb

2:
	/* 
	 * Determine the size of the boot loader's copy of the bootinfo
	 * struct.  This is impossible to do properly because old versions
	 * of the struct don't contain a size field and there are 2 old
	 * versions with the same version number.
	 */
	movl	$BI_ENDCOMMON,%ecx	/* prepare for sizeless version */
	testl	$RB_BOOTINFO,8(%ebp)	/* bi_size (and bootinfo) valid? */
	je	got_bi_size		/* no, sizeless version */
	movl	BI_SIZE(%ebx),%ecx
got_bi_size:

	/* 
	 * Copy the common part of the bootinfo struct
	 */
	movl	%ebx,%esi
	movl	$_bootinfo-KERNBASE,%edi
	cmpl	$BOOTINFO_SIZE,%ecx
	jbe	got_common_bi_size
	movl	$BOOTINFO_SIZE,%ecx
got_common_bi_size:
	cld
	rep
	movsb

#ifdef NFS
	/*
	 * If we have a nfs_diskless structure copy it in
	 */
	movl	BI_NFS_DISKLESS(%ebx),%esi
	cmpl	$0,%esi
	je	2f
	lea	_nfs_diskless-KERNBASE,%edi
	movl	$NFSDISKLESS_SIZE,%ecx
	cld
	rep
	movsb
	lea	_nfs_diskless_valid-KERNBASE,%edi
	movl	$1,(%edi)
#endif

	/*
	 * The old style disk boot.
	 *	(*btext)(howto, bootdev, cyloffset, esym);
	 * Note that the newer boot code just falls into here to pick
	 * up howto and bootdev, cyloffset and esym are no longer used
	 */
olddiskboot:
	movl	8(%ebp),%eax
	movl	%eax,_boothowto-KERNBASE
	movl	12(%ebp),%eax
	movl	%eax,_bootdev-KERNBASE

	ret


/**********************************************************************
 *
 * Identify the CPU and initialize anything special about it
 *
 */
identify_cpu:

	/* Try to toggle alignment check flag; does not exist on 386. */
	pushfl
	popl	%eax
	movl	%eax,%ecx
	orl	$PSL_AC,%eax
	pushl	%eax
	popfl
	pushfl
	popl	%eax
	xorl	%ecx,%eax
	andl	$PSL_AC,%eax
	pushl	%ecx
	popfl

	testl	%eax,%eax
	jnz	1f
	movl	$CPU_386,_cpu-KERNBASE
	jmp	3f

1:	/* Try to toggle identification flag; does not exist on early 486s. */
	pushfl
	popl	%eax
	movl	%eax,%ecx
	xorl	$PSL_ID,%eax
	pushl	%eax
	popfl
	pushfl
	popl	%eax
	xorl	%ecx,%eax
	andl	$PSL_ID,%eax
	pushl	%ecx
	popfl

	testl	%eax,%eax
	jnz	1f
	movl	$CPU_486,_cpu-KERNBASE

	/* check for Cyrix 486DLC -- based on check routine  */
	/* documented in "Cx486SLC/e SMM Programmer's Guide" */
	xorw	%dx,%dx
	cmpw	%dx,%dx			# set flags to known state
	pushfw
	popw	%cx			# store flags in ecx
	movw	$0xffff,%ax
	movw	$0x0004,%bx
	divw	%bx
	pushfw
	popw	%ax
	andw	$0x08d5,%ax		# mask off important bits
	andw	$0x08d5,%cx
	cmpw	%ax,%cx

	jnz	3f			# if flags changed, Intel chip

	movl	$CPU_486DLC,_cpu-KERNBASE # set CPU value for Cyrix
	movl	$0x69727943,_cpu_vendor-KERNBASE	# store vendor string
	movw	$0x0078,_cpu_vendor-KERNBASE+4

#ifndef CYRIX_CACHE_WORKS
	/* Disable caching of the ISA hole only. */
	invd
	movb	$CCR0,%al		# Configuration Register index (CCR0)
	outb	%al,$0x22
	inb	$0x23,%al
	orb	$(CCR0_NC1|CCR0_BARB),%al
	movb	%al,%ah
	movb	$CCR0,%al
	outb	%al,$0x22
	movb	%ah,%al
	outb	%al,$0x23
	invd
#else /* CYRIX_CACHE_WORKS */
	/* Set cache parameters */
	invd				# Start with guaranteed clean cache
	movb	$CCR0,%al		# Configuration Register index (CCR0)
	outb	%al,$0x22
	inb	$0x23,%al
	andb	$~CCR0_NC0,%al
#ifndef CYRIX_CACHE_REALLY_WORKS
	orb	$(CCR0_NC1|CCR0_BARB),%al
#else /* !CYRIX_CACHE_REALLY_WORKS */
	orb	$CCR0_NC1,%al
#endif /* CYRIX_CACHE_REALLY_WORKS */
	movb	%al,%ah
	movb	$CCR0,%al
	outb	%al,$0x22
	movb	%ah,%al
	outb	%al,$0x23
	/* clear non-cacheable region 1	*/
	movb	$(NCR1+2),%al
	outb	%al,$0x22
	movb	$NCR_SIZE_0K,%al
	outb	%al,$0x23
	/* clear non-cacheable region 2	*/
	movb	$(NCR2+2),%al
	outb	%al,$0x22
	movb	$NCR_SIZE_0K,%al
	outb	%al,$0x23
	/* clear non-cacheable region 3	*/
	movb	$(NCR3+2),%al
	outb	%al,$0x22
	movb	$NCR_SIZE_0K,%al
	outb	%al,$0x23
	/* clear non-cacheable region 4	*/
	movb	$(NCR4+2),%al
	outb	%al,$0x22
	movb	$NCR_SIZE_0K,%al
	outb	%al,$0x23
	/* enable caching in CR0 */
	movl	%cr0,%eax
	andl	$~(CR0_CD|CR0_NW),%eax
	movl	%eax,%cr0
	invd
#endif /* CYRIX_CACHE_WORKS */
	jmp	3f

1:	/* Use the `cpuid' instruction. */
	xorl	%eax,%eax
	.byte	0x0f,0xa2			# cpuid 0
	movl	%eax,_cpu_high-KERNBASE		# highest capability
	movl	%ebx,_cpu_vendor-KERNBASE	# store vendor string
	movl	%edx,_cpu_vendor+4-KERNBASE
	movl	%ecx,_cpu_vendor+8-KERNBASE
	movb	$0,_cpu_vendor+12-KERNBASE

	movl	$1,%eax
	.byte	0x0f,0xa2			# cpuid 1
	movl	%eax,_cpu_id-KERNBASE		# store cpu_id
	movl	%edx,_cpu_feature-KERNBASE	# store cpu_feature
	rorl	$8,%eax				# extract family type
	andl	$15,%eax
	cmpl	$5,%eax
	jae	1f

	/* less than Pentium; must be 486 */
	movl	$CPU_486,_cpu-KERNBASE
	jmp	3f
1:
	/* a Pentium? */
	cmpl	$5,%eax
	jne	2f
	movl	$CPU_586,_cpu-KERNBASE
	jmp	3f
2:
	/* Greater than Pentium...call it a Pentium Pro */
	movl	$CPU_686,_cpu-KERNBASE
3:
	ret


/**********************************************************************
 *
 * Create the first page directory and it's page tables
 *
 */

create_pagetables:

/* find end of kernel image */
	movl	$R(_end),%esi

/* include symbols in "kernel image" if they are loaded and useful */
#ifdef DDB
	movl	R(_bootinfo+BI_ESYMTAB),%edi
	testl	%edi,%edi
	je	1f
	movl	%edi,%esi
	movl	$KERNBASE,%edi
	addl	%edi,R(_bootinfo+BI_SYMTAB)
	addl	%edi,R(_bootinfo+BI_ESYMTAB)
1:
#endif

	ROUND2PAGE(%esi)
	movl	%esi,R(_KERNend)	/* save end of kernel */
	movl	%esi,R(physfree)	/* save end of kernel */

/* Allocate Kernel Page Tables */
	ALLOCPAGES(NKPT)
	movl	%esi,R(_KPTphys)

/* Allocate Page Table Directory */
	ALLOCPAGES(1)
	movl	%esi,R(_IdlePTD)

/* Allocate UPAGES */
	ALLOCPAGES(UPAGES)
	movl	%esi,R(upa);
	addl	$KERNBASE, %esi
	movl	%esi, R(_proc0paddr)

/* Allocate P0 Stack */
	ALLOCPAGES(1)
	movl	%esi,R(p0s);

/* Map read-only from zero to the end of the kernel text section */
	movl	R(_KPTphys), %esi
	movl	$R(_etext),%ecx
	addl	$NBPG-1,%ecx
	shrl	$PGSHIFT,%ecx
	movl	$PG_V|PG_KR,%eax
	movl	%esi, %ebx
	fillkpt

/* Map read-write, data, bss and symbols */
	andl	$PG_FRAME,%eax 
	movl	R(_KERNend),%ecx
	subl	%eax,%ecx
	shrl	$PGSHIFT,%ecx
	orl	$PG_V|PG_KW,%eax
	fillkpt

/* Map PD */
	movl	R(_IdlePTD), %eax
	movl	$1, %ecx
	movl	%eax, %ebx
	shrl	$PGSHIFT-2, %ebx
	addl	R(_KPTphys), %ebx
	orl	$PG_V|PG_KW, %eax
	fillkpt

/* Map Proc 0 kernel stack */
	movl	R(p0s), %eax
	movl	$1, %ecx
	movl	%eax, %ebx
	shrl	$PGSHIFT-2, %ebx
	addl	R(_KPTphys), %ebx
	orl	$PG_V|PG_KW, %eax
	fillkpt

/* ... also in user page table page */
	movl	R(p0s), %eax
	movl	$1, %ecx
	orl	$PG_V|PG_KW, %eax
	movl	R(_KPTphys), %ebx
	addl	$(KSTKPTEOFF * PTESIZE), %ebx
	fillkpt

/* Map UPAGES */
	movl	R(upa), %eax
	movl	$UPAGES, %ecx
	movl	%eax, %ebx
	shrl	$PGSHIFT-2, %ebx
	addl	R(_KPTphys), %ebx
	orl	$PG_V|PG_KW, %eax
	fillkpt

/* ... also in user page table page */
	movl	R(upa), %eax
	movl	$UPAGES, %ecx
	orl	$PG_V|PG_KW, %eax
	movl	R(p0s), %ebx
	addl	$(KSTKPTEOFF * PTESIZE), %ebx
	fillkpt

/* and a pde entry too */
	movl	R(p0s), %eax
	movl	R(_IdlePTD), %esi
	orl	$PG_V|PG_KW,%eax
	movl	%eax,KSTKPTDI*PDESIZE(%esi)

/* Map ISA hole */
#define ISA_HOLE_START	  0xa0000
#define ISA_HOLE_LENGTH (0x100000-ISA_HOLE_START)
	movl	$ISA_HOLE_LENGTH>>PGSHIFT, %ecx
	movl	$ISA_HOLE_START, %eax
	movl	%eax, %ebx
	shrl	$PGSHIFT-2, %ebx
	addl	R(_KPTphys), %ebx
	orl	$PG_V|PG_KW|PG_N, %eax
	fillkpt
	movl	$ISA_HOLE_START, %eax
	addl	$KERNBASE, %eax
	movl	%eax, R(_atdevbase)

/* install a pde for temporary double map of bottom of VA */
	movl	R(_IdlePTD), %esi
	movl	R(_KPTphys), %eax
	orl     $PG_V|PG_KW, %eax
	movl	%eax, (%esi)

/* install pde's for pt's */
	movl	R(_IdlePTD), %esi
	movl	R(_KPTphys), %eax
	orl     $PG_V|PG_KW, %eax
	movl	$(NKPT), %ecx
	lea	(KPTDI*PDESIZE)(%esi), %ebx
	fillkpt

/* install a pde recursively mapping page directory as a page table */
	movl	R(_IdlePTD), %esi
	movl	%esi,%eax
	orl	$PG_V|PG_KW,%eax
	movl	%eax,PTDPTDI*PDESIZE(%esi)

	ret
