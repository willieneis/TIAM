function tcmatAnalyzeVideo()

% the following is matlab code that makes java objects / calls java methods (including the tcmat gui).

% basic process:
% 0.) asks user which frame number to use (out of possible frames). loads that single frame.
% 1.) allows user to resize image (in case of varying cell sizes).
% 2.) allows user to adjust image brightness (in case of dark images).
% 3.) allows user to adjust the amount of edge edges extracted (ie adjust the canny filter)
% 4.) allows user to adjust accumulation array (a product of the hough transform)
% 5.) show detects overlayed on initial image
%		allows user to adjust size of blobs in search




% construct TcMatGui (and video objects
% ----------------------------------------
nameLength = 28; % length of: src/matlab/tcmatAnalyzeVideo
pathToFn = mfilename('fullpath');
pathToDir = pathToFn(1:end-nameLength);
tcmat = TcMatGui(pathToDir);
video = tcmat.getVideo();


% the following the main loop that the program follows
% ----------------------------------------------------
newloop = 0;
while newloop==0

	% get information about video
	% ---------------------------
	dirString = char(video.getDir());
	imgFiles = dir(dirString);
	numChannels = video.getNumChannels();
	numFrames = (size(imgFiles,1)-2)/numChannels;

	% get user response about detection parameter tuning process
	% ----------------------------------------------------------
	doDetectionParameterTuning = tcmat.showConfirmMessage('Would you like to tune detection parameters for this video? If not, default parameters will be chosen.');

	if doDetectionParameterTuning == 0
		% choose frame number on which to tune
		% ------------------------------------
		whichFrame = tcmat.askWhichFrameForTuner(numFrames);

		% load image and display on tcmat
		% -------------------------------
		% the following returns the whichFrame_th DIC image (and handles the . and .. files)
		videoimg = imread([dirString, '/', imgFiles(((whichFrame-1)*numChannels)+2+video.getDicChannel()).name]);

		% we store the initial image before any changes (this is displayed at the end)
		initimg = videoimg;

		% convert to java Image and display on tcmat
		javaimg = im2java(videoimg);
		tcmat.showImage(javaimg);

		% if videoimg three-dimensional (has color), make grayscale
		% ---------------------------------------------------------
		if length(size(videoimg)) == 3
			videoimg = rgb2gray(videoimg);
		end

		% adjust image size
		% -----------------
		nextloop = 0;
		resize = 1;
		resize_range = [0.3, 1.7];
		while(nextloop == 0)
			javaimg = im2java(imresize(videoimg, resize));
			whichOpt = tcmat.getUserResponse('Make image bigger.', 'Make image smaller.', 'Choose current image size.', 'Resize the image so that cells are the same size as those in the sample images.', javaimg);

			if whichOpt == 3
				nextloop = 1;
			elseif whichOpt == 1
				if resize <= resize_range(2)-0.1;
					resize = resize + 0.1;
				else
					tcmat.showMessage('Cannot resize any larger! Either make image smaller or accept current size.');
				end
			elseif whichOpt == 2
				if resize >= resize_range(1)+0.1;
					resize = resize - 0.1;
				else
					tcmat.showMessage('Cannot resize any smaller! Either make image larger or accept current size.');
				end
			else
				tcmat.showMessage('You have to choose to make image bigger, smaller, or accept its current size!');
			end
		end
		videoimg = imresize(videoimg, resize);


		% adjust image darkness
		% ---------------------

		nextloop = 0;
		isdark = 0;
		test = videoimg;
		while(nextloop == 0)
			javaimg = im2java(test); 
			whichOpt = tcmat.getUserResponse('Make image lighter.', 'Revert to original image.', 'Choose current image.', 'Is the image too dark? Look at sample images for reference. Lighter is usually better, as darkness hurts accuracy.', javaimg);
			if whichOpt == 3
				nextloop = 1;
			elseif whichOpt == 1
				load histobob_mid
				% test = histeq(test, histobob_mid);
				test = imadjust(histeq(test, histobob_mid), [0.1, 0.5], []);
				isdark = 1;
				tcmat.showMessage('Note: the image will be made lighter. If it looks washed out, that is often ok for decent detection.');
			elseif whichOpt == 2
				test = videoimg;
				isdark = 0;
			else
				tcmat.showMessage('You have to choose to make image lighter or accept its original darkness!');
			end
		end
		videoimg = test;


		% adjust edge value
		% -----------------

		nextloop = 0;
		edgevalue = 0.2;
		edgevalue_range = [0.05, 0.5];
		while(nextloop == 0)

			% compute edge image
			canny = edge(videoimg, 'canny', edgevalue);
			logfilt = edge(videoimg, 'log', 0.001);
			for i = 1 : size(logfilt, 1)
				for l = 1 : size(logfilt, 2)
					if logfilt(i, l) == 1
						canny(i, l) = 1;
					end
				end
			end
			test = im2uint8(canny);

			% make test2 to overlay on white background
			test2 = test;
			test2(:) = 1;
			avepixel = 65 / 255; 
			test2 = imoverlay(test2, canny, [avepixel, avepixel, avepixel]);  % canned function
			test2 = rgb2gray(test2);
			test2 = im2uint8(test2);
			javaimg1 = im2java(test2);

			whichOpt = tcmat.getUserResponse('Increase edge density.', 'Decrease edge density.', 'Choose current edge density.', 'Increase the edge density until the edges of each cell can be clearly seen (noisy edges within and around cells is ok).', javaimg1);
			if whichOpt == 3
				nextloop = 1;
			elseif whichOpt == 2
				if edgevalue <= edgevalue_range(2)-0.05;
					edgevalue = edgevalue + 0.05;
				else
					tcmat.showMessage('Cannot decrease edge more! Either increase edge density or accept current edge density.');
				end
			elseif whichOpt == 1
				if edgevalue >= edgevalue_range(1)+0.05;
					edgevalue = edgevalue - 0.05;
				else
					tcmat.showMessage('Cannot increase edge more! Either decrease edge density or accept current edge density.');
				end
			else
				disp('You have to either increase the edge density, decrease the edge density, or keep the current density.');
			end
		end



		% ---------------------------------------------------------
		% note: test is now the main image that we are working with
		% ---------------------------------------------------------
		% videoimg is the initial (resized) image that we show final results on top of


		% adjust accum array / radius range
		% ---------------------------------

		nextloop = 0;
		radrange = [5,15];
		radrange_range = [3,10];  % this is range for lowerbound of radrange
		chtparam1 = 5; chtparam2 = 15; % these are default values---chosen actually in next section.
		while(nextloop == 0)

			% show accum image

			[accum, circen, cirrad] = CircularHough_Grd(test, radrange, chtparam1, chtparam2);  % canned function
			javaimg = im2java(uint8(accum));

			%tcmat.showImage(javaimg);
			% userinput = input('Type m for larger blobs, l for smaller blobs, y to accept current value.\n', 's');

			whichOpt = tcmat.getUserResponse('Increase hough accum array blob size.', 'Decrease hough accum array blob size.', 'Choose current hough accum array blob size.', 'Try to have roughly one blob per cell.', javaimg);

			if whichOpt == 3
				nextloop = 1;
			elseif whichOpt == 1
				if radrange(1) <= radrange_range(2)-1;
					radrange(1) = radrange(1) + 1;
					radrange(2) = radrange(2) + 1;
				else
					tcmat.showMessage('Cannot make blobs bigger! Either decrease blob size or accept the current value.');
				end
			elseif whichOpt == 2
				if radrange(1) >= radrange_range(1)+1;
					radrange(1) = radrange(1) - 1;
					radrange(2) = radrange(2) - 1;
				else
					tcmat.showMessage('Cannot make blobs smaller! Either decrease blob size or accept the current value.');
				end
			else
				tcmat.showMessage('You have to either increase blob size, decrease blob size, or accept the current blob size.');
			end
		end


		% adjust search radius
		% --------------------

		nextloop = 0;
		searchrad = 15;
		searchrad_range = [5,25];
		gradthresh = 10; % default gradient thresh value
		min_cell_sep = 5; % default minimum cell separation
		while(nextloop == 0)

			% detect cells
			[accum, circen, cirrad] = CircularHough_Grd(test, radrange, gradthresh, searchrad);  % canned function

			% Remove duplicate/overlapping/too-close centers
			circen = sortrows(circen);
			circlesToKeep = [1];
			for i = 2 : size(circen, 1)
				toadd = 1;
				for k = 1 : i-1	
					if (norm(circen(i,:) - circen(k,:)) < min_cell_sep)
						toadd = 0;
					end
				end
				if toadd == 1
					circlesToKeep = [circlesToKeep; i];
				end
			end
			circen = circen(circlesToKeep, :);	
			centers = circen;

			% remove bad centers via blobcheck (cross reference)
			se90 = strel('line', 6, 90);
			se0 = strel('line', 6, 0);
			diam = strel('diamond', 9);
			disk = strel('diamond', 3);
			% take canny image and dilate, fill, erode, and dilate
			dil = imdilate(canny, [se90, se0]);
			fill = imfill(dil, 'holes');
			rawimg = im2uint8(fill);
			for b = 1 : 1
				rawimg = imerode(rawimg, diam);
				rawimg = imdilate(rawimg, disk);
			end
			% Remove centers over black space
			tokeep = [];
			for i = 1 : size(centers, 1)
				xpos = floor(centers(i, 1));
				ypos = floor(centers(i, 2));
				center = rawimg(ypos, xpos);
				up = rawimg(ypos+1, xpos);
				down = rawimg(ypos-1, xpos);
				left = rawimg(ypos-1, xpos);
				right = rawimg(ypos, xpos+1);
				centerColor = (center/5) + (up/5) + (down/5) + (left/5) + (right/5);
				if (centerColor > 153) % value found by inspection
					tokeep = [tokeep; i];
				end
			end
			centers = centers(tokeep, :);

			% resize x and y positions of centers based on initial resize
			centers(:,1) = centers(:,1)/resize;
			centers(:,2) = centers(:,2)/resize;

			% make mask and overlay detected points
			mask = makeCentersMask(initimg,centers);
			javaimg = im2java(imoverlay(initimg, mask', [1,0,0]));

			whichOpt = tcmat.getUserResponse('Increase search radius (look for larger hough peaks).', 'Decrease search radius (look for smaller hough peaks).', 'Choose current search radius value.', 'Use the search radius that visually seems to give a good detection result.', javaimg);

			if whichOpt == 3
				nextloop = 1;
			elseif whichOpt == 1
				if searchrad <= searchrad_range(2)-1;
					searchrad = searchrad + 1;
				else
					tcmat.showMessage('Cannot search for bigger blob peaks. Either search for smaller blob peaks or accept current search radius value.');
				end
			elseif whichOpt == 2
				if searchrad >= searchrad_range(1)+1;
					searchrad = searchrad - 1;
				else
					tcmat.showMessage('Cannot search for bigger blob peaks. Either search for smaller blob peaks or accept current search radius value.');
				end
			else
				tcmat.showMessage('You have to either search for bigger blob peaks, smaller blob peaks, or accept the current search radius value.');
			end
		end


		% make params vector
		% ------------------
		params = [resize, edgevalue, radrange(1), radrange(2), gradthresh, searchrad, min_cell_sep, isdark];
		disp('Detection params:');
		disp(params);

	else

		% set default parameters
		% ----------------------
		resize = 1.7; edgevalue = 0.2; radrange(1) = 5; radrange(2) = 15; gradthresh = 10; searchrad = 15; min_cell_sep = 5; isdark = 1;
		params = [resize, edgevalue, radrange(1), radrange(2), gradthresh, searchrad, min_cell_sep, isdark];
		disp('Detection params:');
		disp(params);

	end

	% detection tuning finished. ask user to "ok" algorithm on entire video
	% ---------------------------------------------------------------------
	tcmat.showMessage('Press ok to run detection, tracking, and feature extraction algorithm on all frames.');









	% Run general algorithm on all frames in video
	% --------------------------------------------

	% reading images into videocell, videocell_irm, videocell_memory, and videocell_naive
	% -----------------------------------------------------------------------------------
	dirstring = dirString;
	cyclesize = numChannels;
	numimgs = numFrames;
	startimg_irm = video.getIrmChannel();
	startimg_memory = video.getFluorChannel1();
	startimg_naive = video.getFluorChannel2();
	startimg = video.getDicChannel();

	tcmat.displayAlgorithmMessage('Loading images...', 1);
	videocell = imgfolder2videocell(dirstring, startimg, cyclesize, numimgs);
	if startimg_irm>0, videocell_irm = imgfolder2videocell(dirstring, startimg_irm, cyclesize, numimgs); end;
	if startimg_memory>0, videocell_memory = imgfolder2videocell(dirstring, startimg_memory, cyclesize, numimgs); end;
	if startimg_naive>0, videocell_naive = imgfolder2videocell(dirstring, startimg_naive, cyclesize, numimgs); end;
	tcmat.displayAlgorithmMessage('All images from all channels loaded.', 0);

	% cell detection
	% --------------
	tcmat.displayAlgorithmMessage('...Starting cell detection.', 1);
	statscell = celldetect_new(videocell, params, tcmat);

	% cell tracking
	% -------------
	tcmat.displayAlgorithmMessage('...Starting cell tracking.', 1);
	max_trackingjump = 28;
	datacell = celltrack(statscell, max_trackingjump, tcmat);

	% notify user: feature extraction starting
	% ----------------------------------------
	tcmat.displayAlgorithmMessage('...Performing feature extraction.',1);

	% get speed (for different time steps)
	% ------------------------------------
	datacell = get_speed_new(datacell);

	% remove shortpaths from datacell
	% ----------------------------------------------
	datacell = remove_shortpaths(datacell,1); % remove cell tracks of zero length
    if numFrames > 10
        datacell = remove_shortpaths(datacell, 5);  % path length to remove
    end

    % save state of datacell before subtrack joining
    % ----------------------------------------------
    datacell2 = datacell;

	% save matlab .mat files
	% ----------------------
	resultsFile = [pathToDir,'ws/', char(video.getName()),'_results.mat'];
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
	if video.getOutlineChannel() > 0
		if video.getOutlineChannel() == video.getIrmChannel(), datacell = get_outline_new(datacell, videocell_irm);
		elseif video.getOutlineChannel() == video.getDicChannel(), datacell = get_outline_new(datacell, videocell);
		elseif video.getOutlineChannel() == video.getFluorChannel1(), datacell = get_outline_new(datacell, videocell_memory);
		elseif video.getOutlineChannel() == video.getFluorChannel2(), datacell = get_outline_new(datacell, videocell_naive);
		end
	end	

	% notify user: feature extraction complete
	% ----------------------------------------
	tcmat.displayAlgorithmMessage('Feature extraction complete.',0);

	% save matlab .mat files
	% ----------------------
	resultsFile = [pathToDir,'ws/', char(video.getName()),'_results.mat'];
	save(resultsFile,'datacell','datacell2');
	tcmat.displayAlgorithmMessage(['Analysis finished. Results saved as: ', resultsFile], 1);



	% ask user which type of data to return (per cell track vs per frame)
	resultDataType = tcmat.showConfirmCancelMessage('Would you like results for each cell track (click Yes), for each video frame (click No), or both (click Cancel)');
	if resultDataType == -1, resultDataType = 2; end

	% ask user for conversion factors (lengthConvert and timeConvert)
	timeConvert = NaN;
	while isnan(timeConvert)==1
		timeConvertString = tcmat.getUserInput('To convert to correct units, please enter the number of seconds between consecutive frames in the video.');
		timeConvertString = char(timeConvertString);
		timeConvert = str2double(timeConvertString);
		timeConvert = real(timeConvert) + imag(timeConvert); % stops imag numbers in string
	end
	lengthConvert = NaN;
	while isnan(lengthConvert)==1
		lengthConvertString = tcmat.getUserInput('To convert to corrent units, please enter the micrometers per pixel conversion factor for this video.');
		lengthConvertString = char(lengthConvertString);
		lengthConvert = str2double(lengthConvertString);
		lengthConvert = real(lengthConvert) + imag(lengthConvert); % stops imag numbers in string
	end

	% get arrest coefficient threshold from user
	arrestCoefThresh = NaN;
	while isnan(arrestCoefThresh)==1
		arrestCoefThreshString = tcmat.getUserInput('Enter a threshold (in micrometers/minute) for computing the arrest coefficient.');
		arrestCoefThreshString = char(arrestCoefThreshString);
		arrestCoefThresh = str2double(arrestCoefThreshString);
		arrestCoefThresh = real(arrestCoefThresh) + imag(arrestCoefThresh); % stops imag numbers in string
	end

	% add polarity to datacell
	datacell = get_polarity_new(datacell);
	
    % add corrected confinement index to datacell (note: must be added before convertUnits)
	datacell = get_correctedConfinementIndex(datacell);

	% convert to correct units (micrometers and minutes)
	datacell = convertUnits(datacell,timeConvert,lengthConvert);

	% add extra computed features to datacell (note: these must be added after convertUnits)
	datacell = get_arrestCoefficient(datacell,arrestCoefThresh,10);
	datacell = get_turnAngle(datacell);

	% ask about only irmOn data
	wantIrmOnly = tcmat.showConfirmMessage('Would you like results for all cells (click Yes), or only for attached cells (click No)?');
	if wantIrmOnly == -1, wantIrmOnly = 0; end

	% make CSVs
	if wantIrmOnly==0  % i.e. user says no to irm only
		makeResultCsvs(datacell,resultDataType,video,0,params);
	else
		makeResultCsvs(datacell,resultDataType,video,1,params,arrestCoefThresh);
	end

	tcmat.displayAlgorithmMessage('CSV results saved in csv directory.', 1);
	tcmat.showMessage('The CSV files were constructed. They are stored in the csv directory.');



	% save matlab .mat file again (overwrites the previous .mat file written before)
	% ------------------------------------------------------------------------------
	resultsFile = [pathToDir,'ws/', char(video.getName()),'_results.mat'];
	save(resultsFile,'datacell','datacell2');


	newloop = tcmat.repeatOrQuit();

	if newloop == 0
		tcmat.displayAlgorithmMessage('------------------------------------------------------------------------', 1);
		tcmat.makeVideo(pathToDir);
		video = tcmat.getVideo();
	end

end

