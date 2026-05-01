
; ProTracker custom manual release 1
; © 1996 Mental Diseases
; By: Håvard "Howard/Mental Diseases" Pedersen
; Idea: Stein Engelsgjerd

; WARNING:

; This haven't been tested, and no warranties are neither implied or given.

; SAMPLES:

; All empty samples must have samplepointers pointing to one empty word,
; located in chipmem. And replen for these samples must be set to 1.

; SAMPLE POINTERS:

; In order to prevent the playroutine from building it's own samplepointers,
; you must delete everything from the label .SampleProc to (and including) the
; line "dbra d0,PT_loop3". This has the sideeffect that the playroutine no
; longer clears the first word of each sample in use. The caller must now do
; this himself.

; PATTERNS:

; To fetch a step from a pattern into D0, do this:

		lea.l	PT_MainData+PTm_PatternPtrs(pc),a0
		move.l	pnum*4(a0),a0
		move.l	step*16+channel*4(a0),d0

; pnum = pattern number (0-255)
; step = pattern step (0-63)
; channel = channel to fetch from (0-3)

; To get the samplerate:

		swap	d0
		and.l	#$fff,d0

; To get the samplenumber: (This may be optimized by combining with fetching
; the data from the pattern, since this allows byte accesses.)

		swap	d0
		move.w	d0,d1
		rol.w	#8,d1
		and.l	#$00f0,d1
		rol.l	#4,d0
		and.l	#$000f,d0
		or.l	d1,d0

; To get the effectcommand:

		and.l	#$fff,d0
		
; PATTERN POINTERS:

; For reserving space for samplepointers, insert the following right under
; PTm_SamplePtrs in the maindata structure:

PTm_PatternPtrs	rs.l	256

; If your application support less than 256 patterns, you can safely exchange
; 256 with the numbers of patterns your application support.

; Still, you'd need to generate your own patternpointers. You have to do this
; yourself and store them in the maindata structure. In order to make the
; replay use your patternpointers, exchange all code from PT_getnewnote to (and
; including "clr.w PTm_DMAConTemp(a4)" with:

PT_getnewnote	move.l	PTm_ModulePtr(a4),a0
		lea.l	12(a0),a3
		lea.l	952(a0),a2		;pattpo
		lea.l	PTm_PatternPtrs(a0),a0	;patternarray
		moveq.l	#0,d0
		moveq.l	#0,d1
		move.b	PTm_SongPos(a4),d0
		move.b	(a2,d0.w),d1
	ifeq PT__68020
		lsl.l	#2,d1
		move.l	(a0,d1.w),a0		; Fetch pointer
	else
		move.l	(a0,d1.w*4),a0		; Fetch pointer
	endc
		moveq.l	#0,d1			; clear offset
		add.w	PTm_PattPos(a4),d1
		clr.w	PTm_DMAConTemp(a4)

; GENERAL:

; All pointers must be built BEFORE calling PT_Init.

