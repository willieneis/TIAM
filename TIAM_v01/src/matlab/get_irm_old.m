function datacell = get_irm(datacell,videocell_irm,cropsize_irm)

% for every frame in every cell path, get irm footprint pixels... add the number of them to datacell

% loop through each cellpath and each frame therein
% -------------------------------------------------

for cp = 1 : size(datacell, 2)	
	for f = 1 : size(datacell{cp}, 1)
		
		% crop cell into 'playpic' and then start irm extraction process
		% --------------------------------------------------------------

		num_irm_area_pixels = 0;
		frame = f + datacell{cp}(1,1)-1;
		center_x = datacell{cp}(f,3);
		center_y = datacell{cp}(f,4);
		halfcropsize = floor(cropsize_irm/2);
		% playpic is a grayscale crop from a specified frame in the video containing the specified cell path of size [cropsize_irm x cropsize_irm]
		if length(size(videocell_irm{1, frame})) == 3
			temp = rgb2gray(videocell_irm{1, frame});
		else
			temp = videocell_irm{1, frame};
		end
		playpic = imcrop(temp, [center_x-halfcropsize, center_y-halfcropsize, cropsize_irm, cropsize_irm]);
        % save playpic_init for later
        playpic_init = playpic;

		% smooth playpic and resize to 40 x 40
		% ------------------------------------

		playpic = medfilt2(playpic);
		playpic = medfilt2(playpic);
		playpic = imcrop(playpic, [2, 2, size(playpic, 1) - 3, size(playpic, 2) - 3]);


		% histogram and threshold filtering method
		% ----------------------------------------

		% test is the result of threshold filtering. It is initially set to all white pixels (value = 255 in uint8 representation)
		test = ones(size(playpic));
		test = im2uint8(test);
		hist = imhist(playpic);
		[throwaway, I] = max(hist);
		% h is the index of the maximum peak in the histogram (I is a potentially single-element vector that contains h)
		h = I(size(I,2));
		% nonZero holds the indices of the non-zero elements of hist (used to get h_min)
		nonZero = [];
		for histIndx = 2 : size(hist)  % I start at 2 becuase the 1st index in hist has a few random pixels
			if hist(histIndx) > 0
				nonZero = [nonZero; histIndx];
			end
		end
		% h_min is the index of the minimum non-zero pixel gray color (minimum of hist)
		if length(nonZero) > 0
			h_min = min(nonZero);
		else
			h_min = 1;
		end
		for k = 1 : size(playpic, 2)
			for l = 1 : size(playpic, 1)
				if  playpic(l, k) < h  &&  h - playpic(l, k)  <  (h - h_min)/3
					test(l, k) = 0;
				end
				% won't grab pixels of higher value than the max
				if playpic(l, k) >= h
					test(l, k) = 0;
				end
			end
		end
		bwtest = im2bw(test);

		% determine if playpic contains irm footprint or not
		% --------------------------------------------------

		crop_playpic = imcrop(playpic, [3*cropsize_irm/8, 3*cropsize_irm/8, cropsize_irm/4, cropsize_irm/4]);
		mean_playpic = mean(playpic(:));
		mean_crop_playpic = mean(crop_playpic(:));
		if mean_playpic - mean_crop_playpic > 2
			irm_exists = 1;
		else
			irm_exists = 0;
		end


		% carry out irm feature extraction if the irm footprint exists
		% ------------------------------------------------------------

		if irm_exists


			% get outline with coordinate manipulation
			% ----------------------------------------
			

			% Take bwtest and make it into coordinate points.
			% -----------------------------------------------
			
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
			% ---------------------------------------
			
			
			% threshold_r is used to remove nearby cells' outlines
			threshold_r = 19;
			mean_r = mean(r);
			sectionBins = cell(1, 12);
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
				markervar = 0;
				for j = 1 : length(sectionBins{k})
					if sectionBins{k}(j) > threshold_r
						markervar = 1;
						threshold_r = 15;
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
					% Here I decide to choose the max point of the section bin--other metrics could be chosen here instead.
					r_choiceArray(k) = max(sectionBins{k});
				else 
					% here, if there are no points in the section bin I decide to choose the mean r value (over the whole outline)
					r_choiceArray(k) = mean_r;
					% what about: mean(r>0); (mean of non-zero radius values)
					% or smallthresh = 4; smallthresh_vec = r>smallthresh; if length(smallthresh_vec) == 0, r_choiceArray(k) = 10;, else r_choiceArray(k) = mean(smallthresh_vec);, end					
				end
			end
			% I decided to put the max point in each sectionBin in the center of its sectionBin (as opposed to placing it at the angle where this max point actually occurs), the reason being, if I did the latter, it would affect the fourier mode technique which we desire to carry out, due to non-evenly spaced points).
			theta_choiceArray = [-(5.5*pi/6) : (pi/6) : (5.5*pi/6)]';
			% Now I have "clean", evenly spaced edge polar coordinates theta and r.
			theta = theta_choiceArray;
			r = r_choiceArray;
			% Convert back to cartesian
			x2 = r .* cos(theta);
			y2 = r .* sin(theta);
			% re-centering on playpic center
			% x2 = x2 + size(bwtest, 1)/2;
			% y2 = y2 + size(bwtest, 1)/2;
			

			% add irm info to datacell for given frame for given cell-path
			% -------------------------------------------------------------

			% if irm outline footprint is desired
			
			% datacell{cp}(f, 5:28) = [x2', y2'];
			
			

			% find num_irm_area_pixels
			% ------------------------	
		
			% x and y are the initial coordiant points I start with after threshold filtering
			z_new = complex(x,y);
			theta_new = angle(z_new);
			r_new = abs(z_new);
			for p_ind = 1 : size(z_new, 1)
				for k = -5 : 6
					if theta_new(p_ind) > (k-1)*pi/6   &&   theta_new(p_ind) <= k*pi/6
						p_section = k + 6;
					end
				end
				if r_new(p_ind) <= r(p_section)  % r(p_section) is the chosen outline value for p_section
					num_irm_area_pixels = num_irm_area_pixels + 1;
				end
			end


		else   % if irm does not exist

			x2 = zeros(12, 1);
			y2 = zeros(12, 1);

			% add irm info to datacell for given frame for given cell-path
			% ------------------------------------------------------------
			% if irm outline footprint is desired
			% datacell{cp}(f, 5:28) = [x2', y2'];
		
		end
		

		% update datacell
		% ---------------
		% if number of "irm pixels" is desired
		datacell{cp}(f, 5) = num_irm_area_pixels;
		
	end
	
	% display information
	% -------------------
	fprintf('irm extraction complete for cell-track: %d/%d \n',cp,size(datacell,2));
	
end
