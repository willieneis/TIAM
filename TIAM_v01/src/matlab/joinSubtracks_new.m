function [datacell,key] = joinSubtracks_new(datacell)

% this function joins subtracks in datacell together by constructing a similarity matrix and carrying out the Hungarian algorithm
% key contains information about which subtracks were joined

% joinmatrix holds the "similarity metric" value between each two celltracks
joinmatrix = zeros(length(datacell));

% grab features from datacell and fill joinmatrix
for i = 1 : length(datacell)
    for j = 1 : length(datacell)
        % ----------------------------------------------
        % note: we are computing similarity for a celltrack j to be added to the end of celltrack i
        % ----------------------------------------------
        
        i_end = datacell{i}(1,2);
        j_start = datacell{j}(1,1);
        % sim begins equal to 1
        sim = 1;
        
        % positional similarity:
        temp = (datacell{i}(end, 3:4) - datacell{j}(1, 3:4));
        dist = sqrt(sum(temp.*temp));
        if dist==0
                sim = sim * 1;
        else
                sim = sim * (1/dist^2); % <--sim is inverse distance squared
        end

        % speed similarity
        if size(datacell{i},1)>10 && size(datacell{j},1)>10 && i~=j
                sim = sim + (1/(abs(mean(datacell{i}(:,11))-mean(datacell{j}(:,11))) * 100000));
        end
        % track shape similarity
        if size(datacell{i},1)>10 && size(datacell{j},1)>10 && i~=j
                vecA = datacell{i}(:,3)-mean(datacell{i}(:,3));
                vecB = datacell{j}(:,3)-mean(datacell{j}(:,3));
                if length(vecA)>length(vecB)
                        vecA = vecA(1:length(vecB));
                else
                        vecB = vecB(1:length(vecA));
                end
                vecC = datacell{i}(:,4)-mean(datacell{i}(:,4));
                vecD = datacell{j}(:,4)-mean(datacell{j}(:,4));
                if length(vecC)>length(vecD)
                        vecC = vecC(1:length(vecD));
                else
                        vecD = vecD(1:length(vecC));
                end
                sim = sim + (1/(norm(vecA-vecB) * 100000));
                sim = sim + (1/(norm(vecC-vecD) * 100000));
        end

        % track order feasibility (starttime / endtime compatibility)
        distThresh = 7;    % <--maximum allowable "gap" in time between celltracks
        if j_start > i_end && j_start < i_end+distThresh;
            sim = sim; % <--binary compatible value (this conditional is for clarity sake)
        else
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

% set a threshold (on cost of the returned optimal assignment: cost(i,j)) and decide which tracks to join
joinThresh = 300;
key = {};
rowsSum = sum(joinmatrix,2);
for i=1:length(datacell)
	if rowsSum(i) > 1/joinThresh & datacell{i}~=-1
		datacell{i} = combineSubtracks(datacell{i},datacell{assig(i)});
        datacell{assig(i)} = [-1];
        key{end+1} = [i,assig(i)];
	end
end

% remove all entries with -1
todel = [];
for i=1:length(datacell)
        if datacell{i}==[-1]
            todel(end+1) = i;
        end
end
datacell(todel) = [];

% RE-RUN: get_speed
datacell = get_speed_new(datacell);


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

end
