function datacell = get_outline_new(datacell,videocell,cropsize,histparam1,histparam2)
% update the datacell with information about the outlines of cells at each frame of videocell

    % default params
    if nargin < 3, cropsize = 51; end
    cropsize_irm = cropsize;
    if nargin < 4, histparam1 = 3; histparam2 = 5; end

    % loop through each cellpath and each frame therein
    % -------------------------------------------------
    for cp = 1:size(datacell,2)
        for f = 1:size(datacell{cp},1)
            % crop cell into 'playpic' and then start outline extraction process
            frame = f+datacell{cp}(f,1)-1;
            center_x = datacell{cp}(f,3);
            center_y = datacell{cp}(f,4);
            halfcropsize = floor(cropsize/2);
            % check if color image, and otherwise don't convert to gray
            if length(size(videocell{1,frame}))==3, videocell{frame} = rgb2gray(videocell{frame}); end
            playpic = imcrop(videocell{frame}, [center_x-halfcropsize, center_y-halfcropsize, cropsize, cropsize]);
            playpic_init = playpic;
            playpic = medfilt2(playpic);
            playpic = imcrop(playpic,[2,2,size(playpic,1)-3,size(playpic,2)-3]);
            level_playpic = graythresh(playpic);
            bwtest = im2bw(playpic,level_playpic);
            bwtest = not(bwtest);
            
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
            % determine if playpic contains irm footprint or not
            % --------------------------------------------------
            crop_playpic = imcrop(playpic,[3*cropsize_irm/8, 3*cropsize_irm/8, cropsize_irm/4, cropsize_irm/4]);
            mean_playpic = mean(playpic(:));
            mean_crop_playpic = mean(crop_playpic(:));
            if mean_playpic-mean_crop_playpic > 0
                irm_exists = 1;
            else
                irm_exists = 0;
            end
            if irm_exists
            %if length(coordMatrix)>10
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
                threshold_r = 19;
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
                            threshold_r = 13;  %%%%% make into a parameter
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
                % Convert back to cartesian
                x2 = r.* cos(theta);
                y2 = r.* sin(theta);
                % add outline info to datacell for given frame for given cell-path
                datacell{cp}(f,17:40) = [x2',y2'];
            else
                datacell{cp}(f,17:40) = 0;
            end

        end
        
        % display information
        % -------------------
        fprintf('outline extraction complete for cell-track: %d/%d \n',cp,size(datacell,2));
        
    end
