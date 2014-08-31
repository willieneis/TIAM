

function jobs = batchSetup()


% set up batch jobs in this file
jobs = {};


% *************************************************
%                    Job Form 2
% *************************************************

expName = 'fc2_control';
dirString = '../../../data/LSM710/2011/091611_motility/last60frames/fc2_control/'; % relative to home i.e. tcmat/tcmat_v1/src
numChannels = 1;
numFrames = 61;

% assign numbers 1-4 for each of the below. if channel does not exist, write 0 (there must be a non-zero for startimg_dic).
startimg_dic = 1;
startimg_irm = 0;
startimg_memory = 0;
startimg_naive = 0;

% assign one of the non-zero channels above from which to extract outline information. if no outline information is desired, write 0.
outline_channel = 1;

% params for detection
imageScale = 1.5;
edgeValue = 0.05;
radiusMin = 5;
radiusMax = 15;
gradientThresh = 10;
searchRadius = 15;
minCellSeparation = 5;
darkImage = 0; % 0 or 1
params = [imageScale, edgeValue, radiusMin, radiusMax, gradientThresh, searchRadius, minCellSeparation, darkImage];

% conversion and other specifications
numSecondsBetweenFrames_convert = 20;
numUmPerPix_convert = 0.664;
arrestCoefficientThreshold = 2.0;

% save only irm-attached cells (0 for all cells, 1 for irm-attached only)
wantIrmOnly = 0;

% remove paths shorter than a given threshold (set threshold to 0 to leave datacell untouched; otherwise, this removes all paths of length shorter than threshold)
removeShortPaths_threshold =  5;

% max tracking jump threshold
maxTrackingJump = 20;

nextJob = {expName, dirString, numChannels, numFrames, startimg_dic, startimg_irm, startimg_memory, startimg_naive, params, numSecondsBetweenFrames_convert, numUmPerPix_convert, arrestCoefficientThreshold, outline_channel, wantIrmOnly, removeShortPaths_threshold, maxTrackingJump};
jobs{end+1} = nextJob; 
% *************************************************


% *************************************************
%                    Job Form 3
% *************************************************

expName = 'fc5_C20';
dirString = '../../../data/LSM710/2011/091611_motility/last60frames/fc5_C20/'; % relative to home i.e. tcmat/tcmat_v1/src
numChannels = 1;
numFrames = 61;

% assign numbers 1-4 for each of the below. if channel does not exist, write 0 (there must be a non-zero for startimg_dic).
startimg_dic = 1;
startimg_irm = 0;
startimg_memory = 0;
startimg_naive = 0;

% assign one of the non-zero channels above from which to extract outline information. if no outline information is desired, write 0.
outline_channel = 1;

% params for detection
imageScale = 1.5;
edgeValue = 0.05;
radiusMin = 5;
radiusMax = 15;
gradientThresh = 10;
searchRadius = 15;
minCellSeparation = 5;
darkImage = 0; % 0 or 1
params = [imageScale, edgeValue, radiusMin, radiusMax, gradientThresh, searchRadius, minCellSeparation, darkImage];

% conversion and other specifications
numSecondsBetweenFrames_convert = 20;
numUmPerPix_convert = 0.664;
arrestCoefficientThreshold = 2.0;

% save only irm-attached cells (0 for all cells, 1 for irm-attached only)
wantIrmOnly = 0;

% remove paths shorter than a given threshold (set threshold to 0 to leave datacell untouched; otherwise, this removes all paths of length shorter than threshold)
removeShortPaths_threshold = 5;

% max tracking jump threshold
maxTrackingJump = 20;

nextJob = {expName, dirString, numChannels, numFrames, startimg_dic, startimg_irm, startimg_memory, startimg_naive, params, numSecondsBetweenFrames_convert, numUmPerPix_convert, arrestCoefficientThreshold, outline_channel, wantIrmOnly, removeShortPaths_threshold, maxTrackingJump};
jobs{end+1} = nextJob; 
% *************************************************


% *************************************************
%                    Job Form 4
% *************************************************

expName = 'fc6_PKCtPseudo';
dirString = '../../../data/LSM710/2011/091611_motility/last60frames/fc6_PKCtPseudo/'; % relative to home i.e. tcmat/tcmat_v1/src
numChannels = 1;
numFrames = 61;

% assign numbers 1-4 for each of the below. if channel does not exist, write 0 (there must be a non-zero for startimg_dic).
startimg_dic = 1;
startimg_irm = 0;
startimg_memory = 0;
startimg_naive = 0;

% assign one of the non-zero channels above from which to extract outline information. if no outline information is desired, write 0.
outline_channel = 1;

% params for detection
imageScale = 1.5;
edgeValue = 0.05;
radiusMin = 5;
radiusMax = 15;
gradientThresh = 10;
searchRadius = 15;
minCellSeparation = 5;
darkImage = 0; % 0 or 1
params = [imageScale, edgeValue, radiusMin, radiusMax, gradientThresh, searchRadius, minCellSeparation, darkImage];

% conversion and other specifications
numSecondsBetweenFrames_convert = 20;
numUmPerPix_convert = 0.664;
arrestCoefficientThreshold = 2.0;

% save only irm-attached cells (0 for all cells, 1 for irm-attached only)
wantIrmOnly = 0;

% remove paths shorter than a given threshold (set threshold to 0 to leave datacell untouched; otherwise, this removes all paths of length shorter than threshold)
removeShortPaths_threshold = 5;

% max tracking jump threshold
maxTrackingJump = 20;

nextJob = {expName, dirString, numChannels, numFrames, startimg_dic, startimg_irm, startimg_memory, startimg_naive, params, numSecondsBetweenFrames_convert, numUmPerPix_convert, arrestCoefficientThreshold, outline_channel, wantIrmOnly, removeShortPaths_threshold, maxTrackingJump};
jobs{end+1} = nextJob; 
% *************************************************


% *************************************************
%                    Job Form 5
% *************************************************

expName = 'fc7_PKCaPseudo';
dirString = '../../../data/LSM710/2011/091611_motility/last60frames/fc7_PKCaPseudo/'; % relative to home i.e. tcmat/tcmat_v1/src
numChannels = 1;
numFrames = 61;

% assign numbers 1-4 for each of the below. if channel does not exist, write 0 (there must be a non-zero for startimg_dic).
startimg_dic = 1;
startimg_irm = 0;
startimg_memory = 0;
startimg_naive = 0;

% assign one of the non-zero channels above from which to extract outline information. if no outline information is desired, write 0.
outline_channel = 1;

% params for detection
imageScale = 1.5;
edgeValue = 0.05;
radiusMin = 5;
radiusMax = 15;
gradientThresh = 10;
searchRadius = 15;
minCellSeparation = 5;
darkImage = 0; % 0 or 1
params = [imageScale, edgeValue, radiusMin, radiusMax, gradientThresh, searchRadius, minCellSeparation, darkImage];

% conversion and other specifications
numSecondsBetweenFrames_convert = 20;
numUmPerPix_convert = 0.664;
arrestCoefficientThreshold = 2.0;

% save only irm-attached cells (0 for all cells, 1 for irm-attached only)
wantIrmOnly = 0;

% remove paths shorter than a given threshold (set threshold to 0 to leave datacell untouched; otherwise, this removes all paths of length shorter than threshold)
removeShortPaths_threshold = 5;

% max tracking jump threshold
maxTrackingJump = 20;

nextJob = {expName, dirString, numChannels, numFrames, startimg_dic, startimg_irm, startimg_memory, startimg_naive, params, numSecondsBetweenFrames_convert, numUmPerPix_convert, arrestCoefficientThreshold, outline_channel, wantIrmOnly, removeShortPaths_threshold, maxTrackingJump};
jobs{end+1} = nextJob; 
% *************************************************

