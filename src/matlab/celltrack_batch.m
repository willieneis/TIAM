
function datacell = celltrack_batch(statscell, max_trackingjump)

% this function performs tracking of T cells (given detection data)
% -----------------------------------------------------------------


tic

datacell = {};

if length(statscell) > 5 % 10 is default
	finalStartFrame = length(statscell)-5; % 10 is default
else
	finalStartFrame = 1;
end

for startframe = 1 : finalStartFrame  % look for new cells at each startframe

	datacell = celltrack_combinedmethods(datacell, statscell, startframe, length(statscell), max_trackingjump);

	% display progress
	disp('tracking startframe:');
	disp(startframe);

	% display on TC-MAT Gui
	algoString = ['Cell tracking complete for frame ', int2str(startframe)];
	if startframe < finalStartFrame
		disp(algoString)
	else
		disp('Cell tracking complete for all frames.')
	end

end

toc