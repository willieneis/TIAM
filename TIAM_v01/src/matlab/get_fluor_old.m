
function datacell = get_fluor(datacell, videocell_fluor, videocell, whichFluorChannel)

% this function returns fluorescence data from channel whichFluorChannel within the footprint of each cell.

% default fixed params for getting outline
cropsize_fluor = 41;
cropsize = 41;
histparam1 = 3;
histparam2 = 5;

% make sure videocell_fluor is of right type; convert if not
%  ---------------------------------------------------------
for f = 1 : length(videocell_fluor)
	if length(size(videocell_fluor{f}))==3   % if fluor channel rgb
		vc_fluor{f} = rgb2gray(videocell_fluor{f});
		% vc_fluor{f} = rgb2gray(im2double(videocell_fluor{f}));
	else   % if fluor channel already gray
		vc_fluor{f} = videocell_fluor{f};
		% vc_fluor{f} = im2double(videocell_fluor{f});
	end
end

% for every frame in every cell path, get fluor value for given cell
% ------------------------------------------------------------------
for cp = 1:size(datacell,2)	
	for f = 1:size(datacell{cp},1)
		% f is row in datacell, frame is true frame number
		frame = f + datacell{cp}(f,1) - 1;
		center_x = datacell{cp}(f,3);
		center_y = datacell{cp}(f,4);
		halfcropsize = floor(cropsize/2);
		% playpic is a grayscale crop from a specified frame in the video containing the specified cell path of size [cropsize x cropsize]
		if length(size(videocell{frame})) == 3
			playpic = imcrop(rgb2gray(videocell{frame}), [center_x-halfcropsize, center_y-halfcropsize, cropsize, cropsize]);
		else
			playpic = imcrop(videocell{frame}, [center_x-halfcropsize, center_y-halfcropsize, cropsize, cropsize]);
		end
        % keep playpic_init for later
        playpic_init = playpic;
		% smooth playpic -- good to do?
		playpic = medfilt2(playpic);
		playpic = medfilt2(playpic);
		playpic = imcrop(playpic, [2, 2, size(playpic, 1) - 3, size(playpic, 2) - 3]);
		% histogram and threshold filtering method
		% note: test is the result of threshold filtering. It is initially set to all white pixels (value = 255 in uint8 representation)
		test = ones(size(playpic));
		test = im2uint8(test);
		% take imhist of playpic
		hist = imhist(playpic);
		[throwaway, I] = max(hist);
		% h is the index of the maximum peak in the histogram (I is a potentially single-element vector that contains h)
		h = I(size(I,2));
		% nonZero holds the indices of the non-zero elements of hist (used to get h_min and h_max)
		nonZero = [];
		for histIndx = 2 : size(hist)  %%%%% I start at 2 because the 1st index in hist has a few random pixels	
			if hist(histIndx) > 0
				nonZero = [nonZero; histIndx];
			end
		end
		% h_min is the index of the minimum non-zero pixel gray color (minimum of hist)
		% h_max is the index of the maximum non-zero pixel gray color (maximum of hist)
		h_min = min(nonZero);
		h_max = max(nonZero);
		for k = 1 : size(playpic, 2)  % better variable names then k and l ?
			for l = 1 : size(playpic, 1)
				if  playpic(l, k) <= h  &&  h - playpic(l, k)  <  (h - h_min)/histparam1
					test(l, k) = 0;
				end
				if playpic(l, k) > h  &&  playpic(l,k) - h  <  (h_max - h)/histparam2
					test(l, k) = 0;
				end
			end
		end
		% convert to binary
		bwtest= im2bw(test);
		% getting outline with coordinate manipulation
		% Take bwtest and make it into coordinate points.
		coordMatrix = [];
		for x_i = 1 : size(bwtest, 2)
			for y_i = 1 : size(bwtest, 1)
				if bwtest(y_i, x_i) == 1
					coordMatrix = [coordMatrix; x_i, y_i];
				end
			end
		end
		x = coordMatrix(:, 1);
		y = coordMatrix(:, 2);
		% center vectors around the origin
		x = x - size(bwtest, 1)/2;
		y = y - size(bwtest, 2)/2;
		% Converting to complex then polar:
		z=complex(x,y);
		theta = angle(z);
		r = abs(z);
		% Section-bins method for finding outline
		% note: threshold_r is used to remove nearby cells' outlines
		threshold_r = 17;
		mean_r = mean(r);
		sectionBins = cell(1, 12);  %%%%%% can't yet make # of bins into a param because i am inconsistent with sizes throughout
		r_choiceArray = zeros(length(sectionBins), 1);
		% fill up sectionBins with r values of coordinate points
		for i = 1 : size(r, 1)	
			for k = -5 : 6
				if theta(i) > (k-1)*pi/6   &&   theta(i) <= k*pi/6
					sectionBins{1, k+6} = [sectionBins{1, k+6}; r(i)];
				end
			end
		end
		% for each sectionBin carry out outline-section algorithm
		for k = 1 : length(sectionBins)
			% modify threshold_r if there is nearby cell
			for j = 1 : length(sectionBins{k})	
				if sectionBins{k}(j) > threshold_r
					threshold_r = 11;
				end
			end
			% remove coordinate points with an r value > threshold_r
			indexToKeep = [];
			for j = 1 : length(sectionBins{k})
				if sectionBins{k}(j) < threshold_r
					indexToKeep = [indexToKeep, j];
				end
			end
			sectionBins{k} = sectionBins{k}(indexToKeep);
			% pick outline point from each sectionBin
			if length(sectionBins{k}) ~= 0
				% Here I decide to choose the max point of the section bin.
				r_choiceArray(k) = max(sectionBins{k});
			else 
				% here, if there are no points in the section bin I decide to choose the mean r value (over the whole outline).
				r_choiceArray(k) = mean_r;
			end
		end
		theta_choiceArray = [-(5.5*pi/6) : (pi/6) : (5.5*pi/6)]';
		% Now I have "clean", evenly spaced edge polar coordinates theta and r.
		theta = theta_choiceArray;
		r = r_choiceArray;
		
		% Convert back to cartesian
		% x2 = r .* cos(theta);
		% y2 = r .* sin(theta);
		% x2 and y2 are vectors containing the x and y points of the boundary of cellpath cp at frame 'frame' (row 'f').
		% % add ouline info to datacell for given frame for given cell-path
		% datacell{cp}(f, 17:40) = [x2', y2'];

		center_x = datacell{cp}(f,3);
		center_y = datacell{cp}(f,4);
		halfcropsize = floor(cropsize_fluor/2);
		% playpic is a grayscale crop from a specified frame in the video containing the specified cell path.  playpic is of size [cropsize_fluor x cropsize_fluor]
		playpic = imcrop(vc_fluor{frame}, [center_x-halfcropsize, center_y-halfcropsize, cropsize_fluor, cropsize_fluor]);
		% mask defines the cell-footprint-points within playpic over which the fluor average should be taken
		mask = zeros(size(playpic,1),size(playpic,2));
		for i=1:size(mask,1) % iterate through each row
			for j=1:size(mask,2) % iterate through each column
				z_pt=complex(j-(size(playpic,2)/2),i-(size(playpic,1)/2)); % notice: columns correspond with x vals, rows correspond with y vals
				theta_pt = angle(z_pt);
				r_pt = abs(z_pt);
				whichThetaInd = findWhichThetaInd(theta_pt);
				if r_pt <= r(whichThetaInd)-1
					mask(i,j) = 1;
				end
			end
		end
		% fluor_ratio = mean(playpic(:));
		% convert mask from double to binary
		mask = im2bw(mask);
		fluor_ratio = mean(playpic(mask));
        %%%%
		%fluor_ratio = mean(playpic_init(mask));
        %%%%
		if whichFluorChannel==1
			datacell{cp}(f,6) = fluor_ratio;
		elseif whichFluorChannel==2
			datacell{cp}(f,7) = fluor_ratio;
		else
			fprintf('Neither whichFluorChannel=1 nor whichFluorChannel=2 was specified. Datacell not updated.\n');
		end
	end
	fprintf('fluorescence extraction complete for cell-track: %d/%d \n',cp,size(datacell,2));
end


function ind = findWhichThetaInd(theta)
	% find the ind in which theta resides (out of 12 theta sections)
	ind = -1; % will produce error if unassigned
	for k = -5 : 6
		if theta > (k-1)*pi/6   &   theta <= k*pi/6
			ind = k+6;
		end
	end
