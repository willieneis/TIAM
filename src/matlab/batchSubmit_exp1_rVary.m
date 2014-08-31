function batchSubmit_exp1_rVary()

% set up batch jobs in this file (this calls tcmatBatchScript.m at the end)
addpath(genpath('~/proj/TIAM/TIAM_v01/src/'));

% jobs is constructed and passed as a parameter to tcmatBatchScript.m
jobs = {};



% *************************************************
%                    Job Form
% *************************************************

expName = '100frames_bmc_exp1_r10';
dirString = '~/Downloads/tcellStuff/exp1_100frames/'; % relative to home i.e. tcmat/tcmat_v1/src
numChannels = 3;
numFrames = 110;

% assign numbers 1-4 for each of the below. if channel does not exist, write 0 (there must be a non-zero for startimg_dic).
startimg_dic = 3;
startimg_irm = 0;
startimg_memory = 0;
startimg_naive = 0;

% assign one of the non-zero channels above from which to extract outline information. if no outline information is desired, write 0.
outline_channel = 0;

% params for detection
imageScale = 1.2;
edgeValue = 0.1;
radiusMin = 5;
radiusMax = 15;
gradientThresh = 10;
searchRadius = 15;
minCellSeparation = 5;
darkImage = 0; % 0 or 1
params = [imageScale, edgeValue, radiusMin, radiusMax, gradientThresh, searchRadius, minCellSeparation, darkImage];

% conversion and other specifications
numSecondsBetweenFrames_convert = 33.3;
numUmPerPix_convert = 0.439;
arrestCoefficientThreshold = 0.3;

% save only irm-attached cells (0 for all cells, 1 for irm-attached only)
wantIrmOnly = 0;

% remove paths shorter than a given threshold (set threshold to 0 to leave datacell untouched; otherwise, this removes all paths of length shorter than threshold)
removeShortPaths_threshold = 5;

% max tracking jump threshold
maxTrackingJump = 10;

nextJob = {expName, dirString, numChannels, numFrames, startimg_dic, startimg_irm, startimg_memory, startimg_naive, params, numSecondsBetweenFrames_convert, numUmPerPix_convert, arrestCoefficientThreshold, outline_channel, wantIrmOnly, removeShortPaths_threshold, maxTrackingJump};
jobs{end+1} = nextJob; 
% *************************************************

nextJob{1} = '100frames_bmc_exp1_r20';
nextJob{end} = 20;
jobs{end+1} = nextJob;

nextJob{1} = '100frames_bmc_exp1_r30';
nextJob{end} = 30;
jobs{end+1} = nextJob;

nextJob{1} = '100frames_bmc_exp1_r40';
nextJob{end} = 40;
jobs{end+1} = nextJob;

nextJob{1} = '100frames_bmc_exp1_r50';
nextJob{end} = 50;
jobs{end+1} = nextJob;


% call tcmatBatchScript.m
tcmatBatchScript(jobs);
