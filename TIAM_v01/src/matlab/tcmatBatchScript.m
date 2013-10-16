function tcmatBatchScript(batchSetupCell)

nameLength = 27; % length of: src/matlab/tcmatBatchScript
pathToFn = mfilename('fullpath');
pathToDir = pathToFn(1:end-nameLength);


for job=1:length(batchSetupCell)
    tic

    % Run general algorithm on all frames in video
    % --------------------------------------------

    % parse batchSetupCell
    jobSetup = batchSetupCell{job};


    % reading images into videocell, videocell_irm, videocell_memory, and videocell_naive
    % -----------------------------------------------------------------------------------
    expName = jobSetup{1}
    dirstring = jobSetup{2};
    cyclesize = jobSetup{3};
    numimgs = jobSetup{4};
    % image order
    startimg = jobSetup{5};
    startimg_irm = jobSetup{6};
    startimg_memory = jobSetup{7};
    startimg_naive = jobSetup{8};
    % outline channel
    outline_channel = jobSetup{13};
    % params
    params = jobSetup{9};
    % other specifications
    numSecondsBetweenFrames_convert = jobSetup{10};
    numUmPerPix_convert = jobSetup{11};
    arrestCoefficientThreshold = jobSetup{12};

    disp('Loading images...')

    videocell = imgfolder2videocell(dirstring, startimg, cyclesize, numimgs);
    if startimg_irm>0, videocell_irm = imgfolder2videocell(dirstring, startimg_irm, cyclesize, numimgs); end;
    if startimg_memory>0, videocell_memory = imgfolder2videocell(dirstring, startimg_memory, cyclesize, numimgs); end;
    if startimg_naive>0, videocell_naive = imgfolder2videocell(dirstring, startimg_naive, cyclesize, numimgs); end;

    disp('All images from all channels loaded.')

    % cell detection
    % --------------
    disp('...Starting cell detection.')
    statscell = celldetect_batch(videocell, params);

    % cell tracking
    % -------------
    disp('...Starting cell tracking.')
    max_trackingjump = jobSetup{16};
    datacell = celltrack_batch(statscell, max_trackingjump);

    % notify user: feature extraction starting
    % ----------------------------------------
    disp('...Performing feature extraction.')

    % get speed (for different time steps)
    % ------------------------------------
    datacell = get_speed_new(datacell); 

	% remove shortpaths from datacell
	% ----------------------------------------------
	datacell = remove_shortpaths(datacell,1); % remove cell tracks of zero length
	%if numFrames > 10
		%datacell = remove_shortpaths(datacell, 9);  % path length to remove
	%end

    % remove shortpaths from datacell (user-specified clipping)
    % ---------------------------------------------------------
    removeShortPaths_threshold = jobSetup{15};
    if removeShortPaths_threshold > 0
        datacell = remove_shortpaths(datacell,removeShortPaths_threshold);
    end

    % save state of datacell before subtrack joining
    % ----------------------------------------------
    datacell2 = datacell;

    % quick save
    % ----------
    resultsFile = [pathToDir,'ws/', expName,'_results.mat'];
    save(resultsFile,'datacell','datacell2');

	% subtrack joining
	% ----------------
	[datacell,todel] = joinSubtracks_new(datacell);
	datacell = remove_shortpaths(datacell,1); % remove cell tracks of zero or one length

    % irm extraction [if irm channel included (ie if startimg_irm>0)]
    % ---------------------------------------------------------------
    if startimg_irm>0
        cropsize_irm = 81;
        datacell = get_irm(datacell,videocell_irm,cropsize_irm);
    end

    % fluor channel extraction
    % ------------------------
    if startimg_memory>0
        % get 1st fluor values [if 1st fluor channel included: (ie if startimg_memory>0)]
        cropsize_fluor = 5;
        fluor_adj_param1 = 0.0035;
        fluor_adj_param2 = 0.165;
        datacell = get_fluor(datacell, videocell_memory, videocell, 1);

        if startimg_naive>0
            % get 2nd fluor values [if 2nd fluor channel included: (ie if startimg_naive>0)] 
            datacell = get_fluor(datacell, videocell_naive, videocell, 2);
            % get cell type (decision between memory and naive)
            datacell = get_celltype_new(datacell);
        end
    end

    % cell outline extraction
    % -----------------------
    % specify which videocell to use for outline extraction
    if outline_channel > 0
        if outline_channel == startimg_irm, datacell = get_outline_new(datacell, videocell_irm);
        elseif outline_channel == startimg, datacell = get_outline_new(datacell, videocell);
        elseif outline_channel == startimg_memory, datacell = get_outline_new(datacell, videocell_memory);
        elseif outline_channel == startimg_naive, datacell = get_outline_new(datacell, videocell_naive);
        end
    end 

    % notify user: feature extraction complete
    % ----------------------------------------
    disp('Feature extraction complete.')

    % save matlab .mat files
    % ----------------------
    resultsFile = [pathToDir,'ws/', expName,'_results.mat'];
    save(resultsFile,'datacell','datacell2');
    disp(['Analysis finished. Results saved as: ', resultsFile]);



    % ask user which type of data to return (per cell track vs per frame)
        %resultDataType = tcmat.showConfirmCancelMessage('Would you like results for each cell track (click Yes), for each video frame (click No), or both (click Cancel)');
        %if resultDataType == -1, resultDataType = 2; end
    resultDataType = 2;

    % ask user for conversion factors (lengthConvert and timeConvert)
        %timeConvert = NaN;
        %while isnan(timeConvert)==1
            %timeConvertString = tcmat.getUserInput('To convert to correct units, please enter the number of seconds between consecutive frames in the video.');
            %timeConvertString = char(timeConvertString);
            %timeConvert = str2double(timeConvertString);
            %timeConvert = real(timeConvert) + imag(timeConvert); % stops imag numbers in string
        %end
        %lengthConvert = NaN;
        %while isnan(lengthConvert)==1
            %lengthConvertString = tcmat.getUserInput('To convert to corrent units, please enter the micrometers per pixel conversion factor for this video.');
            %lengthConvertString = char(lengthConvertString);
            %lengthConvert = str2double(lengthConvertString);
            %lengthConvert = real(lengthConvert) + imag(lengthConvert); % stops imag numbers in string
        %end

    % get arrest coefficient threshold from user
        %arrestCoefThresh = NaN;
        %while isnan(arrestCoefThresh)==1
            %arrestCoefThreshString = tcmat.getUserInput('Enter a threshold (in micrometers/minute) for computing the arrest coefficient.');
            %arrestCoefThreshString = char(arrestCoefThreshString);
            %arrestCoefThresh = str2double(arrestCoefThreshString);
            %arrestCoefThresh = real(arrestCoefThresh) + imag(arrestCoefThresh); % stops imag numbers in string
        %end

    % add polarity to datacell
    datacell = get_polarity_new(datacell);
    
    % add corrected confinement index to datacell (note: must be added before convertUnits)
    datacell = get_correctedConfinementIndex(datacell);

    % convert to correct units (micrometers and minutes)
    timeConvert = numSecondsBetweenFrames_convert;
    lengthConvert = numUmPerPix_convert;
    datacell = convertUnits(datacell,timeConvert,lengthConvert);

    % add extra computed features to datacell (note: these must be added after convertUnits)
    arrestCoefThresh = arrestCoefficientThreshold;
    datacell = get_arrestCoefficient(datacell,arrestCoefThresh,10);
    datacell = get_turnAngle(datacell);

    % make CSVs
    wantIrmOnly = jobSetup{14};
    makeResultCsvs_batch(datacell,resultDataType,expName,wantIrmOnly,params,arrestCoefThresh);
    disp('The CSV files were constructed. They are stored in the csv directory.')

    % save matlab .mat file again (overwrites the previous .mat file written before)
    % ------------------------------------------------------------------------------
    timeSoFar = toc;
    resultsFile = [pathToDir,'ws/', expName,'_results.mat'];
    save(resultsFile,'datacell','datacell2','timeSoFar');

end
