include ../NonWordTranscription/modules/segment_features.praat

# Values for .result_node$
node_quit$ = "quit"
node_next$ = "next"
node_back$ = "back"

#######################################################################
# PROCEDURE definitions start here


#### PROCEDURE to count NWR wordlist structures for each of the three structure types.
# This should work for RWR wordlist structures, too, when those are modified so that 
# the 24 (or 26?) real words that are matched with nonwords for the lexicality effect
# are transcribed, if we make sure that the TargetStructure column is in the same 
# place and includes "CV" only for those 24 (or 26?) rows. 
procedure count_nwr_wordlist_structures(.wordList_table$, .targetStructure$)
	# Get the number of CV-trials in the Word List table.
	selectObject(.wordList_table$)
	Extract rows where column (text): .targetStructure$, "is equal to", "CV"
	.nTrialsCV = Get number of rows

	# Get the number of VC-trials in the Word List table.
	selectObject(.wordList_table$)
	Extract rows where column (text): .targetStructure$, "is equal to", "VC"
	.nTrialsVC = Get number of rows

	# Get the number of CC-trials in the Word List table.
	selectObject(.wordList_table$)
	Extract rows where column (text): .targetStructure$, "is equal to", "CC"
	.nTrialsCC = Get number of rows
endproc


#######################################################################
# TIER-SPECIFIC PROCEDURE definitions start here

#### PROCEDURE to transcribe attributes of prosodic structure on tier for prosody points 
# Prompt the transcriber to transcribe the target sequence prosodically.
procedure transcribe_prosody(.targetNonword$, .target1$, .transcription1$, .target2$, .transcription2$)
	beginPause("Prosodic Transcription for '.targetNonword$'")
		comment("Is prosody /'.target1$'/ transcribed as ['.transcription1$'] in its target position?")
		choice("Target1 correct", 1)
			option("1")
 			option("0")
 			option("NA")
		comment("Is prosody /'.target2$'/ transcribed as ['.transcription2$'] in its target position?")
		choice("Target2 correct", 1)
			option("1")
 			option("0")
 			option("NA")
		comment("Does the production of '.targetNonword$' have at least the target number of syllables?")
		boolean ("Frame not shortened", 1)
	button = endPause("Quit (without saving this trial)", "Rate Prosody", 2, 1)
	if button == 1
		.result_node$ = node_quit$
	else
		.result_node$ = node_next$
	endif
endproc


#### PROCEDURE to transcribe a segment on tiers for target segment 1 and target segment 2 
procedure transcribe_segment(.trial_number$, .word$, .target1$, .target2$, .target_number)
	# Dispatch based on vowel status
	@is_vowel(.target'.target_number'$)
	.vowel_status$ = is_vowel.name$

	if .vowel_status$ == "vowel"
		@transcribe_vowel(.trial_number$, .word$, .target1$, .target2$, .target_number)
		.result_node$ = transcribe_vowel.result_node$
	else
		@transcribe_consonant(.trial_number$, .word$, .target1$, .target2$, .target_number)
		.result_node$ = transcribe_consonant.result_node$
	endif

	# Store the transcription if it exists
	if .result_node$ != node_quit$
		.segmentTranscription$ = '.vowel_status$'Symbol$
		.transcription$ = transcribe_'.vowel_status$'.transcription$
	endif
endproc


####  PROCEDURE : outer wrapper for nodes to prompt stages of VOWEL transcription
# Vowels involve multiple prompts/procedures contained in an event loop
procedure transcribe_vowel(.trial_number$, .word$, .target1$, .target2$, .target_number)
	.target_v$ = .target'.target_number'$

	# Prompt user for [LENGTH] then prompt for a  worldbet [VOWEL SYMBOL] of English or
	# for a potentially free-form symbolic worldbet representation of some [OTHER] sound(s).
	# [SCORE] vowel, and continue to the [NEXT] step. At any point, the user may [QUIT].
	vowel_node_length$ = "length"
	vowel_node_symbol$ = "symbol"
	vowel_node_height_frontness$ = "height_frontness"
	vowel_node_score$ = "score"
	vowel_node_quit$ = "quit"
	vowel_node_next$ = "next"

	vowel_node$ = vowel_node_length$

	while (vowel_node$ != vowel_node_quit$) and (vowel_node$ != vowel_node_next$)
		# [LENGTH]
		if vowel_node$ == vowel_node_length$
			@transcribe_vowel_length(.trial_number$, .word$, .target1$, .target2$, .target_number)

			@next_back_quit(transcribe_vowel_length.result_node$, vowel_node_symbol$, "", vowel_node_quit$)
			vowel_node$ = next_back_quit.result$
		endif

		# [SYMBOL]
		if vowel_node$ == vowel_node_symbol$
			vowelLength$ = transcribe_vowel_length.length$
			# Skip ahead to scoring node if vowel was omitted.
			if vowelLength$ == omitted$
				vowelSymbol$ = omitted$
				vowelLength$ = omitted$
				vowelHeight$ = omitted$
				vowelFrontness$ = omitted$
				vowelOffglide$ = omitted$
				vowel_node$ = vowel_node_score$

			# Skip ahead to scoring node also if vowel was unclassifiable.
			elsif vowelLength$ == unclassifiable$
				vowelSymbol$ = unclassifiable$
				vowelLength$ = unclassifiable$
				vowelHeight$ = unclassifiable$
				vowelFrontness$ = unclassifiable$
				vowelOffglide$ = unclassifiable$
				vowel_node$ = vowel_node_score$

			# Skip ahead to scoring node also if token could not be transcribed because of noise.
			elsif vowelLength$ == noise$
				vowelSymbol$ = noise$
				vowelLength$ = missing_data$
				vowelHeight$ = missing_data$
				vowelFrontness$ = missing_data$
				vowelOffglide$ = missing_data$
				vowel_node$ = vowel_node_score$

			# Otherwise, user chooses a worldbet symbol
			else
				@transcribe_vowel_symbol(.trial_number$, .word$, .target1$, .target2$, .target_number, vowelLength$)

				@next_back_quit(transcribe_vowel_symbol.result_node$, vowel_node_height_frontness$, vowel_node_length$, vowel_node_quit$)
				vowel_node$ = next_back_quit.result$
			endif
		endif

		# [HEIGHT AND FRONTNESS]
		if vowel_node$ == vowel_node_height_frontness$
			vowelSymbol$ = transcribe_vowel_symbol.symbol$
			@transcribe_vowel_height_frontness(.trial_number$, .word$, .target1$, .target2$, .target_number, vowelSymbol$)

			# Export symbol to namespace
			if transcribe_vowel_height_frontness.result_node$ == node_next$
				vowelLength$ = transcribe_vowel_height_frontness.length$
				vowelHeight$ = transcribe_vowel_height_frontness.height$
				vowelFrontness$ = transcribe_vowel_height_frontness.frontness$
				vowelOffglide$ = transcribe_vowel_height_frontness.offglide$
			endif

			@next_back_quit(transcribe_vowel_height_frontness.result_node$, vowel_node_score$, vowel_node_symbol$, vowel_node_quit$)
			vowel_node$ = next_back_quit.result$
		endif

		# [SCORE VOWEL]
		if vowel_node$ == vowel_node_score$
			# Compute the vowel's segmental score.
			@score_vowel(.target_v$, vowelSymbol$, vowelLength$, vowelHeight$, vowelFrontness$, vowelOffglide$)
			.transcription$ = score_vowel.transcription$
			vowel_node$ = vowel_node_next$
		endif
	endwhile

	.result_node$ = if (vowel_node$ == vowel_node_next$) then node_next$ else node_quit$ endif
endproc

#### PROCEDURE for [VOWEL LENGTH]
procedure transcribe_vowel_length(.trial_number$, .word$, .target1$, .target2$, .target_number)
	.target$ = .target'.target_number'$

	beginPause("Vowel Transcription")
		@trial_header(.trial_number$, .word$, .target1$, .target2$, "", "", .target_number)
		comment("Does the production match the target /'.target$'/?")
		choice("Correct", 1)
			option("Yes")
			option("No")
		comment("If not, choose from the following 3 sets of English vowel phones:")
		comment("    diphthongs : /aI/, /aU/, /oI/") 
		comment("    tense or long vowels : /i/, /e/, /ae/, /a/, /o/, /u/")
		comment("    short or lax vowels : /I/, /E/, /3r/, /6/, /V/, /U/")
		comment("or specify how the production does not fit into these sets.") 
		choice("Vowel length", 2)
			option(diphthong$)
			option(tense$)
			option(lax$)
			option(omitted$)
			option(other$)
			option(unclassifiable$)
			option(noise$)
	button = endPause("Quit", "Transcribe it!", 2, 1)

	if button == 1
		.result_node$ = vowel_node_quit$
	else
		.result_node$ = vowel_node_next$
		if correct$ == "Yes"
			.length$ = "skip"
		else
			.length$ = vowel_length$
		endif
	endif
endproc

#### PROCEDURE for [VOWEL SYMBOL] if production is one of 14 vowels of target dialects or a know.
procedure transcribe_vowel_symbol(.trial_number$, .word$, .target1$, .target2$, .target_number, .length$)
	# If the vowel was not omitted or unclassifiable, then prompt the transcriber to select the vowel's
	# transcription from a list of WorldBet symbols for the 14 vowel phonemes or some other already
	# attested and analyzed transcription for a vowel.
	if .length$ == "skip"
		.result_node$ = vowel_node_next$
		.symbol$ = .target'.target_number'$
	else
		beginPause("Vowel Transcription")
			@trial_header(.trial_number$, .word$, .target1$, .target2$, "", "", .target_number)

			choice("Vowel transcription", 1)
				if .length$ == diphthong$
					option("aI")
					option("aU")
					option("oI")
				elsif .length$ == tense$
					option("i")
					option("e")
					option("ae")
					option("a")
					option("o")
					option("u")
				elsif .length$ == lax$
					option("I")
					option("E")
					option("3r")
					option("6")
					option("V")
					option("U")
				elsif .length$ == other$
					option("or")
					option("ar")
					option(other$)
				endif
		button = endPause("Back", "Quit", "Transcribe it!", 3)

		if button == 1
			.result_node$ = vowel_node_back$
		elsif button == 2
			.result_node$ = vowel_node_quit$
		else
			.result_node$ = vowel_node_next$
			.symbol$ = vowel_transcription$
		endif
	endif
endproc

#### PROCEDURE for parsing the features for a VOWEL from its symbol.
procedure transcribe_vowel_height_frontness(.trial_number$, .word$, .target1$, .target2$, .target_number, .symbol$)
	# If the transcriber selected a WorldBet symbol, then parse its features.
	if .symbol$ != "Other"
		.key$ = .symbol$

		# If the transcriber selected a WorldBet symbol from the list of transcribed substitutions of something
		# other than an English vowel phoneme, we need to use the '.key$' to look up the Length feature,
		# so may as well redundantly do that for all.
		.length$ = length_'.key$'$

		# Use the '.key$' to look up the Height and Frontness features.
		.height$ = height_'.key$'$
		.frontness$ = frontness_'.key$'$
		.offglide$ = offglide_'.key$'$
		.result_node$ = vowel_node_next$

	else
	# If the transcriber did not select a WorldBet symbol from either the 14 English vowels or from the
	# already added set of other substitutions, then prompt her to provide a worldbet symbolization.
		beginPause("")
			@trial_header(.trial_number$, .word$, .target1$, .target2$, "", "", 0)

			comment("Enter the worldbet for this (non-English?) syllable nucleus: ")
			text("Vowel transcription", "")
	
		button = endPause("Back", "Quit", "Transcribe it!", 3)

		if button == 1
			.result_node$ = vowel_node_back$
		elsif button == 2
			.result_node$ = vowel_node_quit$
		else
#			.result_node$ = vowel_node_next$
			.symbol$ = vowel_transcription$
#			.length$ = to_be_determined$
#			.height$ = to_be_determined$
#			.frontness$ = to_be_determined$
#			.offglide$ = to_be_determined$

		# If the transcriber selected a WorldBet symbol from the list of transcribed substitutions of something
		# other than an English vowel phoneme, we need to use the '.key$' to look up the Manner feature,
		# so may as well redundantly do that for all.
		.length$ = length_'.symbol$'$
		.height$ = height_'.symbol$'$
		.frontness$ = frontness_'.symbol$'$
		.offglide$ = offglide_'.symbol$'$
		vowelSymbol$ = .symbol$

		.result_node$ = vowel_node_next$
		endif

	endif

endproc


#### PROCEDURE to [SCORE VOWEL].
procedure score_vowel(.target_v$, .symbol$, .length$, .height$, .frontness$, .offglide$)
	if .symbol$ == noise$
		if (.length$ == diphthong$)
			.transcription$ = "'.symbol$';'.length$','.height$','.frontness$','offglide$';'missing_data$'"
		else
			.transcription$ = "'.symbol$';'.length$','.height$','.frontness$';'missing_data$'"
		endif
	else
		# True = 1, False = 0, so we just add the truth values to the score
		.score = 0
		.score = .score + (length_'.target_v$'$ == .length$)
		.score = .score + (height_'.target_v$'$ == .height$)
		.score = .score + (frontness_'.target_v$'$ == .frontness$)
		if (.length$ == diphthong$) 
       			.score = .score + (offglide_'.target_v$'$ == .offglide$)
			.transcription$ = "'.symbol$';'.length$','.height$','.frontness$','.offglide$';'.score'"
		else
			.transcription$ = "'.symbol$';'.length$','.height$','.frontness$';'.score'"
		endif		
	endif
endproc

####  PROCEDURE : outer wrapper for nodes to prompt stages of CONSONANT transcription
# Consonants involve multiple prompts/procedures contained in an event loop
procedure transcribe_consonant(.trial_number$, .word$, .target1$, .target2$, .target_number)
	.target_c$ = .target'.target_number'$

	# Prompt user for [manner] then prompt for a  worldbet [symbol].
	# Determine [place_voice] features for consonant. [score] consonant, and
	# continue to the [next] step. At any point, the user may [quit].
	cons_node_manner$ = "manner"
	cons_node_symbol$ = "symbol"
	cons_node_place_voice$ = "place_voice"
	cons_node_score$ = "score"
	cons_node_quit$ = "quit"
	cons_node_next$ = "next"

	cons_node$ = cons_node_manner$

	while (cons_node$ != cons_node_quit$) and (cons_node$ != cons_node_next$)
		# [MANNER]
		if cons_node$ == cons_node_manner$
			@transcribe_cons_manner(.trial_number$, .word$, .target1$, .target2$, .target_number)

			@next_back_quit(transcribe_cons_manner.result_node$, cons_node_symbol$, "", cons_node_quit$)
			cons_node$ = next_back_quit.result$
		endif

		# [SYMBOL]
		if cons_node$ == cons_node_symbol$
			consonantManner$ = transcribe_cons_manner.manner$
			# Skip ahead to scoring node if consonant was omitted.
			if consonantManner$ == omitted$
				consonantSymbol$ = omitted$
				consonantManner$ = omitted$
				consonantPlace$ = omitted$
				consonantVoicing$ = omitted$
				cons_node$ = cons_node_score$

			# Skip ahead to scoring node also if consonant was unclassifiable.
			elsif consonantManner$ == unclassifiable$
				consonantSymbol$ = unclassifiable$
				consonantManner$ = unclassifiable$
				consonantPlace$ = unclassifiable$
				consonantVoicing$ = unclassifiable$
				cons_node$ = cons_node_score$

			# Skip ahead to scoring node also if consonant could not be transcribed 
			# because of noise or the like.
			elsif consonantManner$ == noise$
				consonantSymbol$ = noise$
				consonantManner$ = missing_data$
				consonantPlace$ = missing_data$
				consonantVoicing$ = missing_data$
				cons_node$ = cons_node_score$

			# Otherwise, user chooses a WorldBet symbol from among those offered 
			# for the 24 consonant phonemes of the target dialects of English, etc.. 
			else
				@transcribe_cons_symbol(.trial_number$, .word$, .target1$, .target2$, .target_number, consonantManner$)

				@next_back_quit(transcribe_cons_symbol.result_node$, cons_node_place_voice$, cons_node_manner$, cons_node_quit$)
				cons_node$ = next_back_quit.result$
			endif
		endif

		# [PLACE AND VOICING]
		if cons_node$ == cons_node_place_voice$
			consonantSymbol$ = transcribe_cons_symbol.symbol$
			@transcribe_cons_place_voice(.trial_number$, .word$, .target1$, .target2$, .target_number, consonantSymbol$)

			# Export place and voicing features to namespace
			if transcribe_cons_place_voice.result_node$ == node_next$
				consonantManner$ = transcribe_cons_place_voice.manner$
				consonantPlace$ = transcribe_cons_place_voice.place$
				consonantVoicing$ = transcribe_cons_place_voice.voicing$
			endif

			@next_back_quit(transcribe_cons_place_voice.result_node$, cons_node_score$, cons_node_symbol$, cons_node_quit$)
			cons_node$ = next_back_quit.result$
		endif

		# [SCORE CONSONANT]
		if cons_node$ == cons_node_score$
			# Compute the consonant's segmental score.
			@score_consonant(.target_c$, consonantSymbol$, consonantManner$, consonantPlace$, consonantVoicing$)
			.transcription$ = score_consonant.transcription$
			cons_node$ = cons_node_next$
		endif
	endwhile

	.result_node$ = if (cons_node$ == cons_node_next$) then node_next$ else node_quit$ endif
endproc

#### PROCEDURE for [CONSONANT MANNER]
procedure transcribe_cons_manner(.trial_number$, .word$, .target1$, .target2$, .target_number)
	.target$ = .target'.target_number'$

	beginPause("Consonant Transcription")
		@trial_header(.trial_number$, .word$, .target1$, .target2$, "", "", .target_number)
		comment("Does the production match the target /'.target$'/?")
		choice("Correct", 1)
			option("Yes")
			option("No")
		comment("If not, choose from the following 5 sets of English consonants:")
		comment("   stops : /p/, /t/, /k/, /b/, /d/, /g/")
		comment("   affricates : /tS/, /dZ/")
		comment("   fricatives : /f/, /T/, /s/, /S/, /h/, /v/, /D/, /z/, /Z/")
		comment("   nasals : /m/, /n/, /N")
		comment("   glides : /w/, /j/, /r/, /l/")
		comment("or specify how the production does not fit into any of the sets.") 
		choice("Consonant manner", 1)
			option(stop$)
			option(affricate$)
			option(fricative$)
			option(nasal$)
			option(glide$)
			option(omitted$)
			option(other$)
			option(unclassifiable$)
			option(noise$)
	button = endPause("Quit", "Transcribe it!", 2)

	if button == 1
		.result_node$ = cons_node_quit$
	else
		.result_node$ = cons_node_next$
		if correct$ == "Yes"
			.manner$ = "skip"
		else
			.manner$ = consonant_manner$
		endif
	endif
endproc

#### PROCEDURE for [CONSONANT SYMBOL]
procedure transcribe_cons_symbol(.trial_number$, .word$, .target1$, .target2$, .target_number, .manner$)

	if .manner$ == "skip"
		.result_node$ = node_next$
		.symbol$ = .target'.target_number'$
	else
		# If the consonant is one of the 24 consonant phonemes (or some other symbolizable sound),
		# then prompt the transcriber to select the consonant's transcription from the list of WorldBet 
		# symbols for the 24 phonemes (or from the list of other recognized sounds).
		beginPause("Consonant Transcription")
		@trial_header(.trial_number$, .word$, .target1$, .target2$, "", "", .target_number)

			choice("Consonant transcription", 1)
				if .manner$ == stop$
					option("p")
					option("t")
					option("k")
					option("b")
					option("d")
					option("g")
				elsif .manner$ == affricate$
					option("tS")
					option("dZ")
				elsif .manner$ == fricative$
					option("f")
					option("T")
					option("s")
					option("S")
					option("h")
					option("v")
					option("D")
					option("z")
					option("Z")
				elsif .manner$ == nasal$
					option("m")
					option("n")
					option("N")
				elsif .manner$ == glide$
					option("j")
					option("w")
					option("l")
					option("r")
				elsif .manner$ == other$
					option("hl")
					option("?")
					option(other$)
				endif
		button = endPause("Back", "Quit", "Transcribe it!", 3)

		if button == 1
			.result_node$ = cons_node_back$
		elsif button == 2
			.result_node$ = cons_node_quit$
		else
			.result_node$ = cons_node_next$
			.symbol$ = consonant_transcription$
		endif
	endif
endproc


#### PROCEDURE for parsing the features for a CONSONANT from its symbol.
procedure transcribe_cons_place_voice(.trial_number$, .word$, .target1$, .target2$, .target_number, .symbol$)
	# If the transcriber selected a WorldBet symbol, then parse its features.
	if .symbol$ != "Other"
		# Translate the '.symbol$' to a character key that can be used to look up the Place and Voicing features.
		if .symbol$ == "t("
			.key$ = "tFlap"
		elsif .symbol$ == "d("
			.key$ = "dFlap"
		elsif .symbol$ == "?"
			.key$ = "glotStop"
		else
			.key$ = .symbol$
		endif

		# If the transcriber selected a WorldBet symbol from the list of transcribed substitutions of something
		# other than an English consonant phoneme, we need to use the '.key$' to look up the Manner feature,
		# so may as well redundantly do that for all.
		.manner$ = manner_'.key$'$

		# Use the '.key$' to look up the Place and Voicing features.
		.place$ = place_'.key$'$
		.voicing$ = voicing_'.key$'$
		.result_node$ = node_next$

	else
	# If the transcriber did not select a WorldBet symbol from either the 24 English consonants or from the
	# already added set of other sounds, then prompt her to provide a worldbet symbolization.
		beginPause("")
			@trial_header(.trial_number$, .word$, .target1$, .target2$, "", "", 0)

			comment("Enter the worldbet for this non-English consonant: ")
			text("Consonant transcription", "")
	
		button = endPause("Back", "Quit", "Transcribe it!", 3)

		if button == 1
			.result_node$ = node_back$
		elsif button == 2
			.result_node$ = node_quit$
		else
#			.result_node$ = node_next$
			.symbol$ = consonant_transcription$
#			.manner$ = to_be_determined$
#			.place$ = to_be_determined$
#			.voicing$ = to_be_determined$


		# If the transcriber selected a WorldBet symbol from the list of transcribed substitutions of something
		# other than an English consonant phoneme, we need to use the '.key$' to look up the Manner feature,
		# so may as well redundantly do that for all.
		.manner$ = manner_'.symbol$'$

		# Use the '.key$' to look up the Place and Voicing features.
		.place$ = place_'.symbol$'$
		.voicing$ = voicing_'.symbol$'$
		consonantSymbol$ = .symbol$
		.result_node$ = node_next$
		endif
	endif

endproc

#### PROCEDURE for scoring a CONSONANT
procedure score_consonant(.target_c$, .symbol$, .manner$, .place$, .voicing$)
	if .symbol$ == noise$
		.transcription$ = "'.symbol$';'.manner$','.place$','.voicing$';'missing_data$'"
	else
		# True = 1, False = 0, so we just add the truth values to the score
		.score = 0
		.score = .score + (manner_'.target_c$'$ == .manner$)
		.score = .score + (place_'.target_c$'$ == .place$)
		.score = .score + (voicing_'.target_c$'$ == .voicing$)
		.transcription$ = "'.symbol$';'.manner$','.place$','.voicing$';'.score'"
	endif
endproc


#### PROCEDURE for entering a NOTE on the notes tier
# Prompt the user to enter notes about the transcription and / or to extract a snippet
# of the Sound Object and the transcription and segmentation TextGrid Objects to 
# save in the ExtractedSnippets directory. 
procedure transcribe_notes(.trial_number$, .word$, .target1$, .target2$, .transcription1$, .transcription2$)
	beginPause("Transcription Notes")
		@trial_header(.trial_number$, .word$, .target1$, .target2$, .transcription1$, .transcription2$, 0)

		comment("You may enter any notes about this transcription below: ")
		text("transcriber_notes", "")

		comment("Should an audio and textgrid snippet be extracted for this trial?")
		boolean("Extract snippet", 0)
		
	button = endPause("Quit (without saving this trial)", "Transcribe it!", 2, 1)

	if button == 1
		.result_node$ = node_quit$
	else
		.notes$ = transcriber_notes$
		.no_notes = length(.notes$) == 0
		.snippet = extract_snippet
		.result_node$ = node_next$
	endif
endproc

### Procedures for checking/correcting NWRTranscription textgrids
procedure checkTarget(.targetNum)
	selectObject(transBasename$)
	.targetScore$ = Get label of interval: .targetNum, currentInterval
	.transcriptionEndpoint = index (.targetScore$, ";")
	.transcription$ = left$ (.targetScore$, .transcriptionEndpoint - 1)
	.target$ = target'.targetNum'$

	beginPause("Target'.targetNum' Transcription for 'targetNonword$'")
		comment("Is /'.target$'/ transcribed correctly as ['.transcription$']?")
 	button = endPause("Yes", "NO", "Quit", 1)

	if button == 2
		Set interval text: .targetNum, currentInterval, ""
		# [RETRANSCRIBE Target]
		@transcribe_segment(trialNumber$, targetNonword$, target1$, target2$, .targetNum)

		# [SCORE Target]
		selectObject(transBasename$)
		segmentInterval = Get interval at time: transcription_textgrid.target'.targetNum'_seg, segmentXMid
		Set interval text: transcription_textgrid.target'.targetNum'_seg, segmentInterval, transcribe_segment.transcription$
	elsif button == 3
		goto abort
	endif
endproc

procedure checkProsody
	selectObject(transBasename$)
	beginPause("Prosody Transcription for 'targetNonword$'")
		comment("Is the prosody transcribed correctly?")
 	button = endPause("Yes", "NO", "Quit", 1)

	if button == 2
		Set interval text: 3, currentInterval, ""

		# [SCORE Prosody]
		@transcribe_prosody(targetNonword$, target1$, transcription1$, target2$, transcription2$)
		prosodyInterval = Get interval at time: transcription_textgrid.prosody, segmentXMid
		@check_worldBet(targetNonword$, transcribe_prosody.target1_correct$, transcribe_prosody.target2_correct$, transcribe_prosody.frame_not_shortened)
		Set interval text: transcription_textgrid.prosody, prosodyInterval, check_worldBet.text$
	elsif button == 3
		goto abort
	endif
endproc

#### PROCEDURE for FORMAT of PROMPT
# These lines appear in every transcription prompt
procedure trial_header(.trial_number$, .word$, .target1$, .target2$, .transcription1$, .transcription2$, .target_number)
	# Neither sound is currently being transcribed by default
	target1_is_current$ = ""
	target2_is_current$ = ""

	if .target_number = 1
		target1_is_current$ = " (currently transcribing)"
	elsif .target_number = 2
		target2_is_current$ = " (currently transcribing)"
	endif

	@is_vowel(.target1$)
	.type1$ = is_vowel.name$
	@is_vowel(.target2$)
	.type2$ = is_vowel.name$

	line_3$ = "Target " + .type1$ + target1_is_current$ + ": /" + .target1$ + "/"
	line_4$ = "Target " + .type2$ + target2_is_current$ + ": /" + .target2$ + "/"

	if .transcription1$ != ""
		line_3$ =  line_3$ + ", transcribed as ['.transcription1$']"
	endif

	if .transcription2$ != ""
		line_4$ =  line_4$ + ", transcribed as ['.transcription2$']"
	endif

	comment("Trial number: '.trial_number$'")
	comment("Target nonword: '.word$'")
	comment(line_3$)
	comment(line_4$)
endproc

procedure check_worldBet(.word$)
	if (target1_correct$ == "0") || (target2_correct$ == "0") || !(frame_not_shortened)
		beginPause("Adjust Transcription")
		comment("Please alter the WorldBet transcription to conform with your prosody rating")
			text("transcription", .word$)
			button = endPause("Quit (without saving this trial)", "Transcribe it!", 2, 1)

		if button == 1
			.result_node$ = node_quit$
		else
			.result_node$ = node_next$
			.text$ = transcription$ + ";" +  target1_correct$ + ";" + target2_correct$ + ";" + string$ (frame_not_shortened)
		endif
	else
		.result_node$ = node_next$
		.text$ = target1_correct$ + ";" + target2_correct$ + ";" + string$ (frame_not_shortened)
	endif
endproc

# Map a .result_node$ value onto the name of node in the wizard.
procedure next_back_quit(.status$, .next_step$, .last_step$, .quit$) 
	if .status$ == node_next$
		.result$ = .next_step$
	elsif .status$ == node_back$
		.result$ = .last_step$
	else
		.result$ = .quit$
	endif
endproc