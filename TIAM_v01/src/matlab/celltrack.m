
function datacell = celltrack(statscell, max_trackingjump, tcmat)

% this function performs tracking of T cells (given detection data)
% -----------------------------------------------------------------


tic

datacell = {};

if length(statscell) > 10
	finalStartFrame = length(statscell)-10;
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
		tcmat.displayAlgorithmMessage(algoString, 0);
	else
		tcmat.displayAlgorithmMessage('Cell tracking complete for all frames.', 0);
	end

end

toc