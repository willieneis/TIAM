
function tcmatMain()

% this function carries out the T Cell Motility Analysis Tool (TC-MAT) GUI



% add java and matlab paths
nameLength = 9; % length of this function name
pathToFn = mfilename('fullpath');
pathToDir = pathToFn(1:end-nameLength);
javaaddpath([pathToDir,'java']);
addpath(genpath([pathToDir,'matlab']));

% carry out algorithm to analyze video
tcmatAnalyzeVideo()


