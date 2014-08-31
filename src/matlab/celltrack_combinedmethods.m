
function datacell = celltrack_combinedmethods(datacell, statscell, startframe, endframe, max_trackingjump)

% this function carries out tracking by combining a few different strategies



tic

% find unique centers at startframe
% ---------------------------------

startframe_centers = statscell{startframe};
toremove = [];
for cp = 1 : length(datacell)
	if datacell{cp}(1, 1) <= startframe  &&  datacell{cp}(1, 2) >= startframe
		f = startframe - datacell{cp}(1, 1) + 1;
		for i = 1 : size(startframe_centers, 1)
			if abs(startframe_centers(i, 1) - datacell{cp}(f, 3)) < 6  &&  abs(startframe_centers(i, 2) - datacell{cp}(f, 4)) < 6
				toremove = [toremove, i];
			end
		end
	end
end
startframe_centers(toremove, :) = [];


% for each unique startframe center, do modified NN tracking until video ends / path breaks
% -----------------------------------------------------------------------------------------

for pcp = 1 : size(startframe_centers, 1)
	% for debugging purposes
	numjumps = 0;

	% specify first position on path
	track = [];
	track(1, 1:2) = startframe_centers(pcp, :);

	% find unique next_centers (frame = startframe + 1)
	frame = startframe + 1; 
	next_centers = statscell{frame};
	toremove = [];
	for cp = 1 : length(datacell)
		if datacell{cp}(1, 1) <= frame  &&  datacell{cp}(1, 2) >= frame
			f = frame - datacell{cp}(1, 1) + 1;
			for i = 1 : size(next_centers, 1)
				if abs(next_centers(i, 1) - datacell{cp}(f, 3)) < 6  &&  abs(next_centers(i, 2) - datacell{cp}(f, 4)) < 6
					toremove = [toremove, i];
				end
			end
		end
	end
	next_centers(toremove, :) = [];
	
	% find unique next_next_centers
	next_next_centers = statscell{(frame + 1)};
	toremove = [];
	for cp = 1 : length(datacell)
		if datacell{cp}(1, 1) <= (frame + 1)  &&  datacell{cp}(1, 2) >= (frame + 1)
			f = (frame + 1) - datacell{cp}(1, 1) + 1;
			for i = 1 : size(next_next_centers, 1)
				if abs(next_next_centers(i, 1) - datacell{cp}(f, 3)) < 6  &&  abs(next_next_centers(i, 2) - datacell{cp}(f, 4)) < 6
					toremove = [toremove, i];
				end
			end
		end
	end
	next_next_centers(toremove, :) = [];
	

	% select the successive center and repeat process [until end of video or until cell-path breaks]
	% ----------------------------------------------------------------------------------------------

	while  size(next_centers, 1) > 0   ||   size(next_next_centers, 1) > 0
		% select nearest unique-potential and add to track
		
		% specify current center of cell
		current_center = track(size(track, 1), :);

        % add a little momentum
        if size(track,1)>1
            current_center = current_center + (1/2)*(current_center-track(end-1,:));
        end

		maxdist = max_trackingjump;
		existnext = 0;
		whichnext = 0;
		
		% look through next_centers for closest
		for j = 1 : size(next_centers, 1)
			if norm( next_centers(j, :) - current_center ) < maxdist
				maxdist = norm( next_centers(j, :) - current_center );
				whichnext = 1;
				existnext = 1;
				closest = j;
			end
		end
		
		% look through next_next_centers for closest
		for j = 1 : size(next_next_centers, 1)
			if norm( next_next_centers(j, :) - current_center ) < maxdist
				maxdist = norm(next_next_centers(j, :) - current_center);
				whichnext = 2;
				existnext = 1;
				closest = j;
			end
		end
		
		% add closest found center to track
		if existnext == 1
			if whichnext == 1
				track = [track; next_centers(closest, :)];
			else
				intermediate = [(current_center(1) + next_next_centers(closest, 1))/2,   (current_center(2) + next_next_centers(closest, 2))/2];
				track = [track; intermediate; next_next_centers(closest, :)];
				numjumps = numjumps + 1;  %%%%% % for de-bugging purposes
			end
		end
		
		% set   frame = frame + 1   or   frame = frame + 2
		if whichnext == 1
			frame = frame + 1;
		else
			frame = frame + 2;
		end		
		
		% if there was a new center added to the path, collect [unique] centers for next_center and next_next_center
		if existnext == 1  &&  frame <= endframe-1  % &&  length(track) < 10
			
			% find unique next_centers
			next_centers = statscell{frame};
			toremove = [];
			for cp = 1 : length(datacell)
				if datacell{cp}(1, 1) <= frame  &&  datacell{cp}(1, 2) >= frame
					f = frame - datacell{cp}(1, 1) + 1;
					for i = 1 : size(next_centers, 1)
						if abs(next_centers(i, 1) - datacell{cp}(f, 3)) < 6  &&  (next_centers(i, 2) - datacell{cp}(f, 4)) < 6
							toremove = [toremove, i];
						end
					end
				end
			end
			next_centers(toremove, :) = [];
		
			% find unique next_next_centers
			next_next_centers = statscell{(frame + 1)};
			toremove = [];
			for cp = 1 : length(datacell)
				if datacell{cp}(1, 1) <= (frame + 1)  &&  datacell{cp}(1, 2) >= (frame + 1)
					f = (frame + 1) - datacell{cp}(1, 1) + 1;
					for i = 1 : size(next_next_centers, 1)
						if abs(next_next_centers(i, 1) - datacell{cp}(f, 3)) < 6  &&  abs(next_next_centers(i, 2) - datacell{cp}(f, 4)) < 6
							toremove = [toremove, i];
						end
					end
				end
			end
			next_next_centers(toremove, :) = [];

		elseif existnext == 1  &&  frame == endframe

			% find unique next_centers
			next_centers = statscell{frame};
			toremove = [];
			for cp = 1 : length(datacell)
				if datacell{cp}(1, 1) <= frame  &&  datacell{cp}(1, 2) >= frame
					f = frame - datacell{cp}(1, 1) + 1;
					for i = 1 : size(next_centers, 1)
						if abs(next_centers(i, 1) - datacell{cp}(f, 3)) < 6  &&  (next_centers(i, 2) - datacell{cp}(f, 4)) < 6
							toremove = [toremove, i];
						end
					end
				end
			end
			next_centers(toremove, :) = [];
			% set next_next_centers to empty
			next_next_centers = [];
			
		else 
			next_centers = [];
			next_next_centers = [];
		end
	end
	
	
	% add tracking information to datacell
	% ------------------------------------

	if size(track, 1) >= 1
		% add track, and start/end of path to datacell
			% for a given cell path, columns 1 and 2 are the path's startframe and endframe, and columns 3 and 4 are the x and y positions of the path
		track(:, 3:4) = track;
		track(:, 1) = startframe;
		track(:, 2) = startframe + size(track, 1) - 1;
		datacell{1, length(datacell) + 1} = track;
	end
	
	% % for debugging purposes:
	% disp('number of jumps for start-frame center:');
	% disp(pcp);
	% disp(':');
	% disp(numjumps);
	
end

toc
