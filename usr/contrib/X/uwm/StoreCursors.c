#ifndef lint
static char *rcsid_StoreCursors_c = "$Header: StoreCursors.c,v 10.3 86/02/01 16:23:56 tony Rel $";
#endif	lint

/************************************************************************
 *									*
 *			Copyright (c) 1986 by				*
 *		Digital Equipment Corporation, Maynard, MA		*
 *		         All Rights Reserved.				*
 *									*
 *	Permission to use, copy, modify, and distribute this software	*
 *	and its documentation is hereby granted only to licensees of 	*
 *	The Regents of the University of California pursuant to their	*
 *	license agreement for the Berkeley Software Distribution 	*
 *	provided that the following appears on all copies.		*
 *									*
 *            "LICENSED FROM DIGITAL EQUIPMENT CORPORATION		*
 *                      COPYRIGHT (C) 1986				*	
 *                 DIGITAL EQUIPMENT CORPORATION			*
 *                         MAYNARD, MA					*
 *                     ALL RIGHTS RESERVED.				*
 *									*
 *      THE INFORMATION IN THIS SOFTWARE IS SUBJECT TO CHANGE WITHOUT	* 
 *	NOTICE AND SHOULD NOT BE CONSTRUED AS A COMMITMENT BY DIGITAL	*
 *	EQUIPMENT CORPORATION.  DIGITAL MAKES NO REPRESENTATIONS	*
 *	ABOUT SUITABILITY OF THIS SOFTWARE FOR ANY PURPOSE. IT IS	*
 *	SUPPLIED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY.		*
 *									*	
 * 	IF THE UNIVERSITY OF CALIFORNIA OR ITS LICENSEES MODIFY 	*	
 *	THE SOFTWARE IN A MANNER CREATING DERIVATIVE COPYRIGHT 		*	
 *	RIGHTS APPROPRIATE COPYRIGHT LEGENDS MAY BE PLACED ON THE	*
 *	DERIVATIVE WORK IN ADDITION TO THAT SET FORTH ABOVE."		*	
 *									*
 ************************************************************************/
 

/*
 * MODIFICATION HISTORY
 *
 * 000 -- M. Gancarz, DEC Ultrix Engineering Group
 */

#ifndef lint
static char *sccsid = "@(#)StoreCursors.c	3.8	1/24/86";
#endif

#include "uwm.h"

/*
 * Include the cursor definition files.
 */
#include <X/cursors/arrow_cross.cursor>
#include <X/cursors/arrow_cross_mask.cursor>
#include <X/cursors/xterm.cursor>
#include <X/cursors/xterm_mask.cursor>
#include <X/cursors/icon.cursor>
#include <X/cursors/icon_mask.cursor>
#include "menu.cursor"
#include "menu_mask.cursor"
#include "leftbutton.cursor"
#include "middlebutton.cursor"
#include "rightbutton.cursor"
#include "button_mask.cursor"

/*
 * Store all the cursors into global variables.
 */
StoreCursors()
{
    /*
     * Main uwm cursor and movement cursor.
     */
    ArrowCrossCursor = XCreateCursor(
    	arrow_cross_width, arrow_cross_height, 
    	arrow_cross_bits, arrow_cross_mask_bits, 
	8, 8,
	BlackPixel, WhitePixel,
	CursorFunc
    );
    if (ArrowCrossCursor == FAILURE) {
	Error("StoreCursors -> Unable to store ArrowCrossCursor.");
    }

    /*
     * Text cursor used in icons.
     */
    TextCursor = XCreateCursor(
    	xterm_width, xterm_height, 
    	xterm_bits, xterm_mask_bits, 
	8, 8,
	BlackPixel, WhitePixel,
	CursorFunc
    );	
    if (TextCursor == FAILURE) {
	Error("StoreCursors -> Unable to store TextCursor.");
    }

    /*
     * Icon cursor used to iconify windows.
     */
    IconCursor = XCreateCursor(
    	icon_width, icon_height, 
    	icon_bits, icon_mask_bits, 
	8, 8,
	ITextForground, ITextBackground,
	IconCursorFunc
    );	
    if (IconCursor == FAILURE) {
	Error("StoreCursors -> Unable to store IconCursor.");
    }

    /*
     * Menu cursor.
     */
    MenuCursor = XCreateCursor(
    	menu_width, menu_height, 
    	menu_bits, menu_mask_bits, 
	0, 8,
	ITextForground, ITextBackground,
	IconCursorFunc
    );	
    if (MenuCursor == FAILURE) {
	Error("StoreCursors -> Unable to store MenuCursor.");
    }

    /*
     * Left button main cursor.
     */
    LeftButtonCursor = XCreateCursor(
    	leftbutton_width, leftbutton_height, 
    	leftbutton_bits, button_mask_bits, 
	8, 8,
	WhitePixel, BlackPixel,
	CursorFunc
    );	
    if (LeftButtonCursor == FAILURE) {
	Error("StoreCursors -> Unable to store LeftButtonCursor.");
    }

    /*
     * Middle button main cursor.
     */
    MiddleButtonCursor = XCreateCursor(
    	middlebutton_width, middlebutton_height, 
    	middlebutton_bits, button_mask_bits, 
	8, 8,
	WhitePixel, BlackPixel,
	CursorFunc
    );	
    if (MiddleButtonCursor == FAILURE) {
	Error("StoreCursors -> Unable to store MiddleButtonCursor.");
    }

    /*
     * Right button main cursor.
     */
    RightButtonCursor = XCreateCursor(
    	rightbutton_width, rightbutton_height, 
    	rightbutton_bits, button_mask_bits, 
	8, 8,
	WhitePixel, BlackPixel,
	CursorFunc
    );	
    if (RightButtonCursor == FAILURE) {
	Error("StoreCursors -> Unable to store RightButtonCursor.");
    }
}
