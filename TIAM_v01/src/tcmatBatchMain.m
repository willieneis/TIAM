
function tcmatBatchMain()

% this function carries out the T Cell Motility Analysis Tool (TC-MAT) in batch on a number of experiments

% add java and matlab paths
nameLength = 14; % length of this function name
pathToFn = mfilename('fullpath');
pathToDir = pathToFn(1:end-nameLength);
javaaddpath([pathToDir,'java']);
addpath(genpath([pathToDir,'matlab']));

% carry out algorithm to analyze video
jobs = batchSetup();
tcmatBatchScript(jobs);
