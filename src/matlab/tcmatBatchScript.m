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

    % prepare for sub-track joining
	datacell = remove_shortpaths(datacell,4); % remove really shortpaths from datacell (treated as noise)
    datacell = get_speed_new(datacell); % speed is used in making decision to join subtracks or not

    % save state of datacell before subtrack joining, feature extractions & unit conversions
    % ----------------------------------------------
    datacell2 = datacell;
    resultsFile = [pathToDir,'ws/', expName,'_results.mat'];
    save(resultsFile,'datacell','datacell2');

	% subtrack joining
	% ----------------
	[datacell,link] = joinSubtracks_new2(datacell);
    % speed is recalculated after sub-track joining as part of the joinSubtracks_new2 function

    % remove shortpaths from datacell (user-specified clipping) (10/22/13: earlier this was before joining sub-tracks)
    % ---------------------------------------------------------
    removeShortPaths_threshold = jobSetup{15};
    if removeShortPaths_threshold > 0
        datacell = remove_shortpaths(datacell,removeShortPaths_threshold);
    end
    
    % notify user: feature extraction starting
    % ----------------------------------------
    disp('...Performing feature extraction.')
    halfCropSize=20; %crop-size for feature extractions; 15 works well for exp5 (25x, 710); 20 works well otherwise
    
    % add polarity to datacell
    %datacell = get_polarity_new(datacell, videocell, halfCropSize, params);
    datacell = get_polarity_default(datacell);
    
    % irm extraction [if irm channel included (ie if startimg_irm>0)]
    if startimg_irm>0
        datacell = get_irmArea(datacell,videocell_irm,halfCropSize);
    end

    % fluor channel extraction
    if startimg_memory>0 % 1st flur channel
        % get 1st fluor values [if 1st fluor channel included: (ie if startimg_memory>0)]
        datacell = get_flurInt(datacell, videocell_memory, halfCropSize, 1);

        if startimg_naive>0 % 2nd flur channel
            % get 2nd fluor values [if 2nd fluor channel included: (ie if startimg_naive>0)] 
            datacell = get_flurInt(datacell, videocell_naive, halfCropSize, 2);
            % get cell type (decision between memory and naive)
            datacell = get_celltype_new(datacell);
        end
    end
    
    % notify user: feature extraction complete
    disp('Feature extraction complete.')
    
    % cell outline extraction
    % -----------------------
    if outline_channel > 0
        if outline_channel == startimg, datacell = get_outline_new(datacell, videocell, halfCropSize, 4, params, pathToDir, expName);
        elseif outline_channel == startimg_irm, datacell = get_outline_new(datacell, videocell_irm, halfCropSize, 1, params, pathToDir, expName);
        elseif outline_channel == startimg_memory, datacell = get_outline_new(datacell, videocell_memory, halfCropSize, 2, params, pathToDir, expName);
        elseif outline_channel == startimg_naive, datacell = get_outline_new(datacell, videocell_naive, halfCropSize, 3, params, pathToDir, expName);
        end
        disp('Outline image extraction complete.')    
    end
    
    % save matlab .mat files
    resultsFile = [pathToDir,'ws/', expName,'_results.mat'];
    save(resultsFile,'datacell','datacell2'); %overwrites the previous one
    
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
    resultDataType = 2; %value of 2 would save csv files having both per-frame and per-track data
    makeResultCsvs_batch(datacell,resultDataType,expName,wantIrmOnly,params,arrestCoefThresh);
    disp('The CSV files were constructed. They are stored in the csv directory.')

    % save matlab .mat file again (overwrites the previous .mat file written before)
    timeSoFar = toc;
    resultsFile = [pathToDir,'ws/', expName,'_results.mat'];
    save(resultsFile,'datacell','datacell2','timeSoFar');
    disp(['Analysis finished. Results saved as: ', resultsFile]);

end
