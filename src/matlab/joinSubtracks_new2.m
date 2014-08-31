function [datacell,key] = joinSubtracks_new2(datacell)

% this function joins subtracks in datacell together by constructing a similarity matrix and carrying out the Hungarian algorithm
% key contains information about which subtracks were joined

% joinmatrix holds the "similarity metric" value between each two celltracks and is set to zero initially
joinmatrix = zeros(length(datacell));

% grab features from datacell and fill joinmatrix
for i = 1 : length(datacell)
    for j = i+1 : length(datacell) % the second track to be considered for joining can't be before the first track
        % ----------------------------------------------
        % note: we are computing similarity for a celltrack j to be added to the end of celltrack i
        % ----------------------------------------------
        
        % sim begins equal to 1
        sim = 1;
        
        % track order feasibility (starttime / endtime compatibility)
        gap = datacell{j}(1,1)-datacell{i}(1,2); % gap between first frame of j and last frame of i
        gapThresh = 7;    % <--maximum allowable "gap" in time between celltracks
        temp = (datacell{i}(end, 3:4) - datacell{j}(1, 3:4));
        eucDist = sqrt(sum(temp.*temp)); % distance between the end of track i and begnning of track j
            
        if gap>=1 && gap<gapThresh && eucDist<70 && size(datacell{i},1)>=4 && size(datacell{j},1)>=4 
        %if within the allowed gap and close-enough and tracks are long-enough consider positional similarity    
                   
            % positional similarity
            if eucDist<10
                sim = 1/(10*gap);
            else
                sim = 1/(eucDist*gap); % earlier this was inverse distance squared
                % 10,50 pixel distance will give sim of 0.1,0.05 for gap 1 and 0.05, 0.004 for gap 5 
            end
            
            % speed-1 similarity
            if size(datacell{i},1)>6
                speed_i = mean(datacell{i}(end-5:end,9));
            else speed_i = mean(datacell{i}(:,9));
            end
            if size(datacell{j},1)>6
                speed_j = mean(datacell{j}(end-5:end,9));
            else speed_j = mean(datacell{j}(:,9));
            end
            if abs(speed_i-speed_j)>1  
                sim = sim + (1/(abs(speed_i-speed_j) * 100));
                % difference of 1,3 in speed will add a sim of 0.01,0.0033
            else sim = sim + (1/100);
            end
                
            % direction similarity (angles between the ending and beginning segments are compared)
            linfit_i = polyfit(datacell{i}(end-3:end,3), datacell{i}(end-3:end,4), 1); % linear fit of the last 4 positions gives the average direction
            linfit_j = polyfit(datacell{j}(1:4,3), datacell{j}(1:4,4), 1);% linear fit of the first 4 positions gives the average direction
            x_i= datacell{i}(end,3)-datacell{i}(end-3,3); % centers the x-value
            y_i= x_i * linfit_i(1,1); % best-fit slope is used get the y-value of movement
            x_j= datacell{j}(4,3)-datacell{j}(1,3);
            y_j= x_j * linfit_j(1,1);
            [theta_i, r_i] = cart2pol(x_i, y_i); % provides the average angle (direction of movement) of track i 
            [theta_j, r_j] = cart2pol(x_j, y_j); % theta is closed between [-pi,pi]
            [theta_ij,r_ij] = cart2pol(datacell{j}(1,3)-datacell{i}(end,3), datacell{j}(1,4)-datacell{i}(end,4));% angle of joining segment
            angleDiff1 = normalizeAngle(theta_i-theta_ij,0); % angle difference between track i and joining segment expressed between -pi and pi
            angleDiff1 = radtodeg(abs(angleDiff1)); 
            angleDiff2 = normalizeAngle(theta_i-theta_j, 0); % angle difference between track i and track j expressed between -pi and pi 
            angleDiff2 = radtodeg(abs(angleDiff2));
            if gap<=2
                sim = sim - (angleDiff1*0.0001/gap) - (angleDiff2*0.00005/gap); % penalize if the segments require a lot turning within fewer steps
                % 180 angleDiff1,2 will remove 0.018,0.009 from sim without a gap
            else
                sim = sim - (angleDiff1*0.0002/gap) - (angleDiff2*0.0001/gap);
            end    
            
            % consistency/discrepancy between speed and distance
            %speedConsistency = abs( (mean([speed_i,speed_j])*gap) - eucDist ); % difference between the actual distance and the distance covered by the existing speed
            speedConsistency = eucDist - (mean([speed_i,speed_j])*gap);
            if speedConsistency>0
                sim = sim - (speedConsistency*0.001); %penalized if the speed does not allow to reach the actual distance
                % difference of 10 pixel units will remove 0.01 from sim
            elseif speedConsistency<0 && gap==1
                sim = sim - (abs(speedConsistency)*0.001);
            else
                sim = sim - (abs(speedConsistency)*0.001/degtorad(angleDiff2)); % if the speed covers more distance than actual distance adjust the discrepancy by the angle of turn
            end    
         
        else % if the gap is more than the max allowed gap or less than 1 or if the eucDistance is too much
            sim = 0; % <--binary incompatible value
        end

        % add value to join matrix:
        joinmatrix(i, j) = sim;			
    end
end

% ---------------------------------------------------------------
% new plan: grab only a subset of joinmatrix to run hungarian algorithm on 
% i.e only i's and j's that pass some threshold, fix the max size of this matrix allows, then run hungarian algorithm on this subset
% 		and join all results of the hungarian algorithm? no need for heuristics below?
% (this is not implemented yet)
% ---------------------------------------------------------------

% make joinmat with a low value between similiar things and a high value between dissimilar things (ie a distance matrix as opposed to similarity matrix)
joinmat = max(joinmatrix(:)) - joinmatrix;
[assig, cost] = munkres(joinmat);
%save('subtrackSet', 'assig', 'cost', 'joinmatrix'); 

% set a threshold (on cost of the returned optimal assignment: cost(i,j)) and decide which tracks to join
joinThresh = 0.015; 
key = {};
linked = zeros(1,length(datacell));
joinCount = zeros(1,length(datacell)); % holds the count of number of sub-tracks that have been included


for j=length(datacell):-1:1
   if max(joinmatrix(:,j))>joinThresh
       for i=j-1:-1:1
           if assig(i) == j
               key{end+1} = [i,j,joinmatrix(i,j),datacell{i}(1,2)]; % for reference
               %holds the two trackIDs and frame info where linked and similarity score
               datacell{i} = combineSubtracks(datacell{i},datacell{j});
               linked(j) = 1;
               joinCount(i) = joinCount(j) + 1; 
               break
           end
       end   
   end
end  

%remove track segments that were linked 
todel = [];
for i=1:length(datacell)
        if linked(i) == 1
            todel(end+1) = i;
        end
end
datacell(todel) = []; % null assignment will delete it

% RE-RUN: get_speed
datacell = get_speed_new(datacell);

%save('subtrackSet', 'assig', 'joinmatrix', 'key', 'linked', 'joinCount'); 

% called functions combineSubtracks and normalizeAngle
    function newmat = combineSubtracks(cellmat1,cellmat2)
        gapwidth = cellmat2(1,1)-cellmat1(1,2)-1;
        if gapwidth<0
            fprintf('ERROR: track-sections to join are inconsistent. cellmat2(1,1) = %d, cellmat1(1,2) = %d. Skipping. \n', cellmat2(1,1), cellmat1(1,2) );
            newmat = [-1];
        else
            if gapwidth>0
                xpos = linspace(cellmat1(end,3),cellmat2(1,3),gapwidth+2); xpos = xpos(2:end-1);
                ypos = linspace(cellmat1(end,4),cellmat2(1,4),gapwidth+2); ypos = ypos(2:end-1);
                gapmat = repmat(cellmat1(end,:),gapwidth,1);
                gapmat(:,3) = xpos;
                gapmat(:,4) = ypos;
            else
                gapmat = zeros(0,size(cellmat1,2)); 
            end
            newmat = [cellmat1; gapmat; cellmat2]; 
            newmat(:,1) = newmat(1,1);
            newmat(:,2) = newmat(1,1)+size(newmat,1)-1;
        end
    end

    function alpha = normalizeAngle(alpha, varargin) % from Author: David Legland
    %   ALPHA2 = normalizeAngle(ALPHA);
    %   ALPHA2 is the same as ALPHA modulo 2*PI and is positive.

    %   ALPHA2 = normalizeAngle(ALPHA, CENTER);
    %   Specifies the center of the angle interval.
    %   If CENTER==0, the interval is [-pi ; +pi]
    %   If CENTER==PI, the interval is [0 ; 2*pi] (default).
        center = pi;
        if ~isempty(varargin)
            center = varargin{1};
        end
        alpha = mod(alpha-center+pi, 2*pi) + center-pi;
    end    
end