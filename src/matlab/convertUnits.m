
function datacell = convertUnits(datacell,timeConvert,lengthConvert)

% this function converts the units of relevant fields in the datacell

% input: timeConvert, seconds-between-frames time factor
% input: lengthConver, micrometers-per-pixel length factor

% output: datacell, updated datacell with correct units




for i = 1:length(datacell)

	% update position
	datacell{i}(:,3) = datacell{i}(:,3)*lengthConvert;
	datacell{i}(:,4) = datacell{i}(:,4)*lengthConvert;

	% update irm area
	datacell{i}(:,5) = datacell{i}(:,5)*lengthConvert*lengthConvert;

	% update speeds
	datacell{i}(:,9) = datacell{i}(:,9)*60*lengthConvert/timeConvert;
	datacell{i}(:,10) = datacell{i}(:,10)*60*lengthConvert/timeConvert;
	datacell{i}(:,11) = datacell{i}(:,11)*60*lengthConvert/timeConvert;
	datacell{i}(:,12) = datacell{i}(:,12)*60*lengthConvert/timeConvert;

	% update displacement
	datacell{i}(:,13) = datacell{i}(:,13)*lengthConvert;

	% update corrected confinement index
	datacell{i}(:,16) = datacell{i}(:,16)*sqrt(timeConvert/60);

end
