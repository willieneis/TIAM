function datacell = get_fluor(datacell,videocell_fluor,videocell,whichFluorChannel)

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
	else   % if fluor channel already gray
		vc_fluor{f} = videocell_fluor{f};
	end
end

% for every frame in every cell path, get fluor value for given cell
% ------------------------------------------------------------------
for cp = 1:size(datacell,2)	
	for f = 1:size(datacell{cp},1)
        % crop cell into 'playpic' and then start outline extraction process
        frame = f+datacell{cp}(f,1)-1;
        center_x = datacell{cp}(f,3);
        center_y = datacell{cp}(f,4);
        halfcropsize = floor(cropsize/2);
        % check if color image, and otherwise don't convert to gray
        %if length(size(videocell_fluor{1,frame}))==3, videocell{frame} = rgb2gray(videocell{frame}); end
        %videocell = vc_fluor;
        playpic = imcrop(videocell{frame},[center_x-halfcropsize,center_y-halfcropsize,cropsize,cropsize]);
        playpic = medfilt2(playpic);
        playpic = imcrop(playpic,[2,2,size(playpic,1)-3,size(playpic,2)-3]);
        level_playpic = graythresh(playpic);
        bwtest = im2bw(playpic,level_playpic);

        % get outline with coordinate manipulation
        % ----------------------------------------
        % Take bwtest and make it into coordinate points.
        coordMatrix = [];
        for x_i = 1:size(bwtest, 2)
            for y_i = 1 : size(bwtest, 1)
                if bwtest(y_i, x_i) == 1
                    coordMatrix = [coordMatrix; x_i, y_i];
                end
            end
        end
        if length(coordMatrix)>10
            x = coordMatrix(:,1);
            y = coordMatrix(:,2);
            % center vectors around the origin
            % note: this only shifts points over by size of playpic/2. I could shift over based on the 
            %   farthest-left and farthest-right non-zero pixel.
            x = x-size(bwtest,1)/2;
            y = y-size(bwtest,2)/2;
            % Converting to complex then polar:
            z=complex(x,y);
            theta = angle(z);
            r = abs(z);

            % Section-bins method for finding outline
            % ---------------------------------------
            % threshold_r is used to remove nearby cells' outlines
            threshold_r = 11;
            mean_r = mean(r);
            sectionBins = cell(1,12);
            r_choiceArray = zeros(length(sectionBins),1);
            for i = 1 : size(r, 1)	
                for k = -5 : 6
                    if theta(i) > (k-1)*pi/6 && theta(i) <= k*pi/6
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
                        markervar = 1;  %%%%% probably don't need this... was used in a previous hack (in the next section)
                        threshold_r = 11;  %%%%% make into a parameter
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
                if length(sectionBins{k}) ~= 0
                    r_choiceArray(k) = max(sectionBins{k});
                else
                    r_choiceArray(k) = mean_r;
                end
            end
            theta_choiceArray = [-(5.5*pi/6):(pi/6):(5.5*pi/6)]' ;
            % Now I have "clean", evenly spaced edge polar coordinates theta and r.
            theta = theta_choiceArray;
            r = r_choiceArray;

            halfcropsize = floor(cropsize_fluor/2);
            % playpic is a grayscale crop from a specified frame in the video containing the specified cell path.  playpic is of size [cropsize_fluor x cropsize_fluor]
            playpic = imcrop(vc_fluor{frame},[center_x-halfcropsize,center_y-halfcropsize,cropsize_fluor,cropsize_fluor]);
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
            % convert mask from double to binary
            mask = im2bw(mask);
            fluor_ratio = mean(playpic(mask));
        else
            fluor_ratio = 0;
        end
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


function ind = findWhichThetaInd(th)
	% find the ind in which theta, th, resides (out of 12 theta sections)
	ind = -1; % will produce error if unassigned
	for k = -5 : 6
		if th>(k-1)*pi/6 & th<=k*pi/6
			ind = k+6;
		end
	end
