# NonWordTranscription.praat
# Version 1
# Author: Patrick Reidy
# Date: 10 August 2013

# NonWordTranscription.praat
# Version 2
# Author: Tristan Mahr
# Date: 16-18 April 2014
# 1) Most of the code is now encapsulated in procedures. 
# 2) CV trial type has been generalized so VC and CV trials are now supported.
# 3) Start-up wizard now re-uses code from segmentation start-up.
# 4) Minimum version of praat is now enforced, so can use "Command: [args]" notation.
# 5) Procedures are also used to contain or (hide) related variables in a common namespace. 
# 6) Multistep transcription wizards (consonants, prosody) support a back-button.
# 7) Functionality is now broken up over multiple files.
# 8) Script can now transition to next type of trial when finished with CV

# NonWordTranscription.praat
# Version 3
# Author: Mary Beckman
# Date: 01 May 2014
# 09) vowel transcription changed to parallel consonant transcription
# 10) transcription and scoring separated for non-canonical substitutions
# 11) category of "unclassifiable" added to both C and V transcription (and then later
#       (on 06 May 2014) added "noise" to both, for noise or TOS or the like.
# Left to do:
# If we decide to adopt this strategy, should add way of making the correct transcription
# be the default choice at each of the two steps.

# NonWordTranscription.praat
# Version 4
# Author: Franzo Law II
# Date: 02 October 2014
#  12)  Restructured prosody scoring, such that transcriber is prompted to assign prosody score
#       after transcribing each segment, then prompted to score a frame prosody score for the
#       frame involving the two transcribed segments.
#  12a) Transcriber is prompted to include a WorldBet transcription that is reflective
#       of the production if the frame prosody score is transcribed as incorrect (0)
#  13)  Transcriber is able to more easily transcribe if the target matches the production
#       through the inclusion of a default prompt.
#  14)  Cosmetic changes added, such as phonemic slashes (//) and reminders of the target and
#       and how it has been transcribed, wherever appropriate.
#  15)  Experiment exits gracefully.
#  16) Update to allow for 4-point diphthong offglide scoring 

#######################################################################
# Controls whether the @log_[...] procedures write to the InfoLines.
# debug_mode = 1
debug_mode = 0
abort = 0

# Include the other files mentioned in change 7 of version 2.
include modules/check_version.praat
include modules/NWRProcedures.praat
include ../L2T-utilities/L2T-Utilities.praat
include ../L2T-Audio/L2T-Audio.praat
include ../L2T-StartupForm/L2T-StartupForm.praat
include ../L2T-WordList/L2T-WordList.praat
include ../L2T-SegmentationTextGrid/L2T-SegmentationTextGrid.praat
include ../L2T-Transcription/L2T-Transcription.praat

# Values for .result_node$
node_quit$ = "quit"
node_next$ = "next"
node_back$ = "back"

# Set the session parameters.
defaultExpTask = 1
defaultTestwave = 1
defaultActivity = 3
@session_parameters: defaultExpTask, defaultTestwave, defaultActivity

# Load the audio file
@audio

# Load the WordList.
@wordlist

# Load the checked segmented TextGrid.
@segmentation_textgrid

# Set the transcription-specific parameters.
@transcription_parameters

# Numeric and string constants for the Word List Table.
wordListBasename$ = wordlist.praat_obj$
wordListTrialNumber$ = wordlist_columns.trial_number$
wordListWorldBet$ = wordlist_columns.worldbet$
wordListTarget1$ = wordlist_columns.target1$
wordListTarget2$ = wordlist_columns.target2$
wordListTargetStructure$ = wordlist_columns.target_structure$

# Column numbers from the segmented textgrid
segTextGridTrial = segmentation_textgrid_tiers.trial
segTextGridContext = segmentation_textgrid_tiers.context

# Count the trials of structure type
@count_nwr_wordlist_structures(wordListBasename$, wordListTargetStructure$)
nTrialsCV = count_nwr_wordlist_structures.nTrialsCV
nTrialsVC = count_nwr_wordlist_structures.nTrialsVC
nTrialsCC = count_nwr_wordlist_structures.nTrialsCC

@participant: audio.read_from$, session_parameters.participant_number$

# Check whether the log and textgrid exist already
@transcription_log("check", session_parameters.experimental_task$,  participant.id$, session_parameters.initials$, transcription_parameters.logDirectory$, nTrialsCV, nTrialsVC, nTrialsCC)
@transcription_textgrid("check", session_parameters.experimental_task$,  participant.id$, session_parameters.initials$, transcription_parameters.textGridDirectory$))

# Load or initialize the transcription log/textgrid iff
# the log/textgrid both exist already or both need to be created.
if transcription_log.exists == transcription_textgrid.exists
	@transcription_log("load", session_parameters.experimental_task$, participant.id$, session_parameters.initials$, transcription_parameters.logDirectory$, nTrialsCV, nTrialsVC, nTrialsCC)
	@transcription_textgrid("load", session_parameters.experimental_task$, participant.id$, session_parameters.initials$, transcription_parameters.textGridDirectory$)
# Otherwise exit with an error message
else
	log_part$ = "Log " + transcription_log.filename$
	grid_part$ = "TextGrid " + transcription_textgrid.filename$
	if transcription_log.exists
		msg$ = "Initialization error: " + log_part$ + " was found, but " + grid_part$ + " was not."
	else
		msg$ = "Initialization error: " + grid_part$ + " was found, but " + log_part$ + " was not."
	endif
	exitScript: msg$
endif

# Export values to global namespace
segmentBasename$ = segmentation_textgrid.praat_obj$
segmentTableBasename$ = segmentation_textgrid.tablePraat_obj$
audioBasename$ = audio.praat_obj$
transBasename$ = transcription_textgrid.praat_obj$
transLogBasename$ = transcription_log.praat_obj$

# These are column names
transLogCVs$ = transcription_log.cvs$
transLogCVsTranscribed$ = transcription_log.cvs_transcribed$
transLogVCs$ = transcription_log.vcs$
transLogVCsTranscribed$ = transcription_log.vcs_transcribed$
transLogCCs$ = transcription_log.ccs$
transLogCCsTranscribed$ = transcription_log.ccs_transcribed$
transLogEndTime$ = transcription_log.end$

#######################################################################
# Open an Edit window with the segmentation textgrid, so that the transcriber can examine
# the larger segmentation context to recoup from infelicitous segmenting of false starts
# and the like. 
selectObject(segmentBasename$)
Edit

# Open a separate Editor window with the transcription textgrid object and audio file.
selectObject(transBasename$)
plusObject(audioBasename$)
Edit
# Set the Spectrogram settings, etc., here.

#######################################################################
# Loop through the trial types
trial_type1$ = "CV"
trial_type2$ = "VC"
trial_type3$ = "CC"
current_type = 1
current_type_limit = 4

# [TRIAL TYPE LOOP]
while current_type < current_type_limit & !abort
	trial_type$ = trial_type'current_type'$

	# Check if there are any trials to transcribe for this trial type.
	trials_col$ = transLog'trial_type$'s$
	done_col$ = transLog'trial_type$'sTranscribed$

	@count_remaining_trials(transLogBasename$, 1, trials_col$, done_col$)
	n_trials = count_remaining_trials.n_trials
	n_transcribed = count_remaining_trials.n_transcribed
	n_remaining = count_remaining_trials.n_remaining

	# Jump to next type if there are no remaining trials to transcribe
	if n_remaining == 0
		current_type = current_type + 1
	# If there are still trials to transcribe, ask the transcriber if she would like to transcribe them.
	elsif n_transcribed < n_trials
		beginPause("Transcribe 'trial_type$'-trials")
			comment("There are 'n_remaining' 'trial_type$'-trials to transcribe.")
			comment("Would you like to transcribe them?")
		button = endPause("No", "Yes", 2, 1)	
		
		# Trial numbers here refer to rows in the Word List table
		trial = n_transcribed + 1

		# If the user chooses no, skip the transcription loop and break out of this loop.
		if button == 1
			trial = n_trials + 1
			current_type = current_type_limit
		endif

		# Loop through the trials of the current type
		while trial <= n_trials & !abort
			# Get the Trial Number (a string value) of the current trial.
			selectObject(wordListBasename$ + "_" + trial_type$)
			trialNumber$ = Get value: trial, wordListTrialNumber$

			# Look up trial number in segmentation table. Compute trial midpoint from table.
			selectObject(segmentTableBasename$)
			segTableRow = Search column: "text", trialNumber$

			@get_xbounds_from_table(segmentTableBasename$, segTableRow)
			trialXMid = get_xbounds_from_table.xmid

			# Find bounds of the textgrid interval containing the trial midpoint
			@get_xbounds_in_textgrid_interval(segmentBasename$, segTextGridTrial, trialXMid)

			# Use the XMin and XMax of the current trial to extract that portion of the segmented 
			# TextGrid, preserving the times. The TextGrid Object that this operation creates will 
			# have the name:
			# ::ExperimentalTask::_::ExperimentalID::_::SegmentersInitials::segm_part
			selectObject(segmentBasename$)
			Extract part: get_xbounds_in_textgrid_interval.xmin, get_xbounds_in_textgrid_interval.xmax, "yes"

			# Convert the (extracted) TextGrid to a Table, which has the
			# same name as the TextGrid from which it was created.
			selectObject(segmentBasename$ + "_part")
			Down to Table: "no", 6, "yes", "no"
			selectObject(segmentBasename$ + "_part")
			Remove

			# Subset the 'segmentBasename$'_part Table to just the intervals on the Context Tier.
			selectObject(segmentTableBasename$ + "_part")
			Extract rows where column (text): "tier", "is equal to", "Context"
			selectObject(segmentTableBasename$ + "_part")
			Remove

			# Count the number of segmented intervals.
			selectObject(segmentTableBasename$ + "_part_Context")
			numResponses = Get number of rows
			# If there is more than one segmented interval, ...
			if numResponses > 1
				# Zoom to the entire trial in the segmentation TextGrid object and 
				# invite the transcriber to select the interval to transcribe.
				editor 'segmentBasename$'
					Zoom: get_xbounds_in_textgrid_interval.xmin, get_xbounds_in_textgrid_interval.xmax
				endeditor
				beginPause("Choose repetition number to transcribe")
					choice("Repetition number", numResponses)
						for repnum from 1 to 'numResponses'
							option("'repnum'")
						endfor
				button = endPause("Back", "Quit", "Choose repetition number", 3)
			else
				repetition_number = 1
			endif

			# Get the Context label of the chosen segmented interval of this trial and also then
			# mark it off in the transcription textgrid ready to transcribe or skip as a NonResponse.
			selectObject(segmentTableBasename$ + "_part_Context")
			contextLabel$ = Get value: repetition_number, "text"

			# Determine the XMin and XMax of the segmented interval.
			@get_xbounds_from_table(segmentTableBasename$ + "_part_Context", repetition_number)
			segmentXMid = get_xbounds_from_table.xmid

			@get_xbounds_in_textgrid_interval(segmentBasename$, segTextGridContext, segmentXMid)
			segmentXMin = get_xbounds_in_textgrid_interval.xmin
			segmentXMax = get_xbounds_in_textgrid_interval.xmax

			# Add interval boundaries on each tier.
			selectObject(transBasename$)
			Insert boundary: transcription_textgrid.target1_seg, segmentXMin
			Insert boundary: transcription_textgrid.target1_seg, segmentXMax
			Insert boundary: transcription_textgrid.target2_seg, segmentXMin
			Insert boundary: transcription_textgrid.target2_seg, segmentXMax
			Insert boundary: transcription_textgrid.prosody, segmentXMin
			Insert boundary: transcription_textgrid.prosody, segmentXMax

			# Determine the target word and target segments. 
			selectObject(wordListBasename$ + "_" + trial_type$)
			targetNonword$ = Get value: trial, wordListWorldBet$
			target1$ = Get value: trial, wordListTarget1$
			target2$ = Get value: trial, wordListTarget2$

			# [TRANSCRIPTION EVENT LOOP]

			# If the trial [context] is a Response or UnpromptedResponse, [zoom] into the interval
			# to be transcribed. Prompt user to transcribe [t1]. Determine [t1_score].
			# Prompt user to transcribe [t2]. Determine [t2_score].
			# Prompt user for [prosody] features. Determine [prosody_score], record [notes], 
			# [save] and move onto [next_trial]. At any point, the user may [quit].
			trans_node_context$ = "context"
			trans_node_zoom$ = "zoom"
			trans_node_t1$ = "t1"
			trans_node_t1_score$ = "t1_score"
			trans_node_t2$ = "t2"
			trans_node_t2_score$ = "t2_score"
			trans_node_prosody$ = "prosody"
			trans_node_prosody_score$ = "prosody_score"
			trans_node_notes_prompt$ = "notes_prompt"
			trans_node_notes_save$ = "notes_save"
			trans_node_extract_snippet$ = "extract_snippet"
			trans_node_save$ = "save"
			trans_node_next_trial$ = "next_trial"
			trans_node_quit$ = "quit"

			trans_node$ = trans_node_context$
			transcriptionNecessary = 0

			while (trans_node$ != trans_node_quit$) & (trans_node$ != trans_node_next_trial$)


				# [CHECK IF RESPONSE, ETC.]
				if trans_node$ == trans_node_context$
					if (contextLabel$ == "Response") or (contextLabel$=="UnpromptedResponse")
					# If chosen interval is either of the transcribable types of response, proceed to transcription. 
						trans_node$ = trans_node_zoom$
					elsif (contextLabel$ == "NonResponse") or (contextLabel$=="Perseveration")
						# If chosen interval is a non-response of some kind, assign it a score of 0 on each tier
						# and invite the transcriber to insert a note. 
						transcription$ = "NonResponse; ;0"
						selectObject(transBasename$)
						segmentInterval = Get interval at time: transcription_textgrid.target1_seg, segmentXMid
						Set interval text: transcription_textgrid.target1_seg, segmentInterval, transcription$
						segmentInterval = Get interval at time: transcription_textgrid.target2_seg, segmentXMid
						Set interval text: transcription_textgrid.target2_seg, segmentInterval, transcription$
						segmentInterval = Get interval at time: transcription_textgrid.prosody, segmentXMid
						Set interval text: transcription_textgrid.prosody, segmentInterval, transcription$

						#target1$, target2$
						transcription1$ = ""
						transcription2$ = ""
						trans_node$ = trans_node_notes_prompt$
					else
						# Otherwise, assume something is wrong and just invite the transcriber to insert a note. 
						#target1$, target2$
						transcription1$ = ""
						transcription2$ = ""						
						trans_node$ = trans_node_notes_prompt$
					endif
				endif

				# [ZOOM TO SEGMENTED INTERVAL AND CHECK IT]
				if trans_node$ == trans_node_zoom$
					# Zoom to the segmented interval in the editor window.
					editor 'transBasename$'
						Zoom: segmentXMin - 0.25, segmentXMax + 0.25
					endeditor

					trans_node$ = trans_node_t1$

				endif
			
				# [TRANSCRIBE T1]
				if trans_node$ == trans_node_t1$
					@transcribe_segment(trialNumber$, targetNonword$, target1$, target2$, 1)
					@next_back_quit(transcribe_segment.result_node$, trans_node_t1_score$, "", trans_node_quit$)
					trans_node$ = next_back_quit.result$
					if trans_node$ != trans_node_quit$
						transcription1$ = transcribe_segment.segmentTranscription$
					endif
				endif

				# [SCORE T1]
				if trans_node$ == trans_node_t1_score$
					selectObject(transBasename$)
					segmentInterval = Get interval at time: transcription_textgrid.target1_seg, segmentXMid
					Set interval text: transcription_textgrid.target1_seg, segmentInterval, transcribe_segment.transcription$
					trans_node$ = trans_node_t2$
				endif

				# [TRANSCRIBE T2]
				if trans_node$ == trans_node_t2$
					@transcribe_segment(trialNumber$, targetNonword$, target1$, target2$, 2)
					@next_back_quit(transcribe_segment.result_node$, trans_node_t2_score$, "", trans_node_quit$)				
					trans_node$ = next_back_quit.result$
					if trans_node$ != trans_node_quit$
						transcription2$ = transcribe_segment.segmentTranscription$
					endif
				endif

				# [SCORE T2]
				if trans_node$ == trans_node_t2_score$
					selectObject(transBasename$)
					segmentInterval = Get interval at time: transcription_textgrid.target2_seg, segmentXMid
					Set interval text: transcription_textgrid.target2_seg, segmentInterval, transcribe_segment.transcription$
					trans_node$ = trans_node_prosody$
				endif

				# [TRANSCRIBE PROSODY]
				if trans_node$ == trans_node_prosody$
					@transcribe_prosody(targetNonword$, target1$, transcription1$, target2$, transcription2$)
					prosodyInterval = Get interval at time: transcription_textgrid.prosody, segmentXMid
					@check_worldBet(targetNonword$, transcribe_prosody.target1_correct$, transcribe_prosody.target2_correct$, transcribe_prosody.frame_not_shortened)
					Set interval text: transcription_textgrid.prosody, prosodyInterval, check_worldBet.text$
					@next_back_quit(check_worldBet.result_node$, trans_node_notes_prompt$, "", trans_node_quit$)
					trans_node$ = next_back_quit.result$
				endif

				# [PROMPT FOR NOTES]
				if trans_node$ == trans_node_notes_prompt$
					@transcribe_notes(trialNumber$, targetNonword$, target1$, target2$, transcription1$, transcription2$)
	
					@next_back_quit(transcribe_notes.result_node$, trans_node_notes_save$, "", trans_node_quit$)
					trans_node$ = next_back_quit.result$
				endif

				# [WRITE NOTES]
				if trans_node$ == trans_node_notes_save$
				
					# Add a point only if there are notes to write down
					if !transcribe_notes.no_notes
						selectObject(transBasename$)
						Insert point: transcription_textgrid.notes, segmentXMid, transcribe_notes.notes$
					endif
					trans_node$ = trans_node_extract_snippet$
				endif

				# [EXTRACT AND SAVE SNIPPET]
#### Issue: As soon as Mary or Pat has the time, this maybe should be rewritten as a call to a proc  
####    that is stored in a separate file, for use in other scripts such as the segmentation script.
				if trans_node$ == trans_node_extract_snippet$
					# Extract and save a snippet only if the extract_snippet box was checked.
					if transcribe_notes.snippet
						selectObject(audioBasename$)
						Extract part: segmentXMin, segmentXMax, "rectangular", 1, "yes"
						selectObject(transBasename$)
						Extract part: segmentXMin, segmentXMax, "yes"
						selectObject(segmentBasename$)
						Extract part: segmentXMin, segmentXMax, "yes"
						# The extracted snippet collection will be named by the basename for the transcription
						# TextGrid plus the orthographic form for the nonword plus the repetition number.

						selectObject(transBasename$)
						.basename$ = selected$ ("TextGrid")
						snippet_pathname$ = transcription_parameters.transSnippetDirectory$ + "/" + .basename$ + "_" + targetNonword$ + "_" + "'repetition_number'" + ".Collection"

						# It will be saved as a binary praat .Collection file. 
						selectObject(audioBasename$ + "_part")
						plusObject(transBasename$ + "_part")
						plusObject(segmentBasename$ + "_part")
						Save as binary file: snippet_pathname$
						# The three extracted bits are removed from the Objects: window afterwards. 
						selectObject(audioBasename$ + "_part")
						plusObject(transBasename$ + "_part")
						plusObject(segmentBasename$ + "_part")
						Remove
					endif
					trans_node$ = trans_node_save$
				endif
	
				# [SAVE RESULTS]
				if trans_node$ == trans_node_save$
					selectObject(transBasename$)
					Save as text file: transcription_textgrid.filepath$

					# Update the number of CV-trials that have been transcribed.
					selectObject(transLogBasename$)
					log_col$ = transLog'trial_type$'sTranscribed$
					Set numeric value: 1, log_col$, trial
					@timestamp
					Set string value: 1, transLogEndTime$, timestamp.time$
					Save as tab-separated file: transcription_log.filepath$

					trans_node$ = trans_node_next_trial$
				endif
			endwhile

			# [QUIT]
			if trans_node$ == trans_node_quit$
				# If the transcriber decided to quit, then set the 'trial'
				# variable so that the script breaks out of the while-loop.
				trial = nTrialsCV + 1
				abort = 1
			endif
##### This results in a very ungraceful way to quit midstream.  Figure out a better way.

			# [NEXT TRIAL]
			if trans_node$ == trans_node_next_trial$
				# Increment the 'trial'.
				trial = trial + 1
				# Remove the segmented interval's Table from the Praat Object list.
				selectObject(segmentTableBasename$ + "_part_Context")
				Remove
			endif
		endwhile
	endif
endwhile

select all 
Remove