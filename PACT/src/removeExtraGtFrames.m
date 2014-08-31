function gtcell = removeExtraGtFrames(gtcell, framevec)

	% this function removes all extra frames (indexed in framevec) from gtcell

	% loop through each celltrack in gtcell
	for i = 1 : length(gtcell)
		framerange = [gtcell{i}(1,1), gtcell{i}(1,2)];
		todel = [];  % todel holds indices to remove from this gtcell{i}
		for r = 1 : length(framevec)
			if framevec(r) >= framerange(1)  &&  framevec(r) <= framerange(2)  % if frame to delete is in this gtcell{i}
				todel(end+1) = framevec(r);
			end
		end
		% todelRow contains rows of gtcell{i} corresponding with the frames in todel
		todelRow = todel - gtcell{i}(1,1) + 1;
		gtcell{i}(todelRow,:) = [];  % delete rows
		gtcell{i}(:,2) = size(gtcell{i},1) + gtcell{i}(1,1) - 1;
		% also need to move start and end frames back if extraGtFrames occur before the celltrack
		for r = 1 : length(framevec)
			if framevec(r) < framerange(1)  % if frame to delete is in this gtcell{i}
				gtcell{i}(:,1) = gtcell{i}(:,1)-1;
				gtcell{i}(:,2) = gtcell{i}(:,2)-1;
			end
		end

	end
