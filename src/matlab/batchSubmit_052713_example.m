function batchSubmit_052713_example()

% set up batch jobs in this file (this calls tcmatBatchScript.m at the end)
addpath(genpath('C:/Users/mayyav01/Documents/MATLAB/tcmat_forVivek/src'));

% jobs is constructed and passed as a parameter to tcmatBatchScript.m
jobs = {};



% *************************************************
%                    Job Form
% *************************************************

expName = '052713_memIso_2oCcl21';
dirString = 'C:/Users/mayyav01/Documents/data/LSM510/052713_lfa1/anals/memIso_2oCcl21/'; % relative to home i.e. tcmat/tcmat_v1/src
numChannels = 2;
numFrames = 180;

% assign numbers 1-4 for each of the below. if channel does not exist, write 0 (there must be a non-zero for startimg_dic).
startimg_dic = 2;
startimg_irm = 1;
startimg_memory = 0;
startimg_naive = 0;

% assign one of the non-zero channels above from which to extract outline information. if no outline information is desired, write 0.
outline_channel = 0;

% params for detection
imageScale = 1.2;
edgeValue = 0.05;
radiusMin = 5;
radiusMax = 15;
gradientThresh = 10;
searchRadius = 16;
minCellSeparation = 6;
darkImage = 0; % 0 or 1
params = [imageScale, edgeValue, radiusMin, radiusMax, gradientThresh, searchRadius, minCellSeparation, darkImage];

% conversion and other specifications
numSecondsBetweenFrames_convert = 28.94;
numUmPerPix_convert = 0.439;
arrestCoefficientThreshold = 0.5;

% save only irm-attached cells (0 for all cells, 1 for irm-attached only)
wantIrmOnly = 0;

% remove paths shorter than a given threshold (set threshold to 0 to leave datacell untouched; otherwise, this removes all paths of length shorter than threshold)
removeShortPaths_threshold = 10;

% max tracking jump threshold
maxTrackingJump = 33;

nextJob = {expName, dirString, numChannels, numFrames, startimg_dic, startimg_irm, startimg_memory, startimg_naive, params, numSecondsBetweenFrames_convert, numUmPerPix_convert, arrestCoefficientThreshold, outline_channel, wantIrmOnly, removeShortPaths_threshold, maxTrackingJump};
jobs{end+1} = nextJob; 
% *************************************************

nextJob{1} = '052713_memBlock_2oCcl21';
nextJob{2} = 'C:/Users/mayyav01/Documents/data/LSM510/052713_lfa1/anals/memBlock_2oCcl21/';
jobs{end+1} = nextJob;

nextJob{1} = '052713_memIso_pt05oCcl21';
nextJob{2} = 'C:/Users/mayyav01/Documents/data/LSM510/052713_lfa1/anals/memIso_pt05oCcl21/';
jobs{end+1} = nextJob;

nextJob{1} = '052713_memBlock_pt05oCcl21';
nextJob{2} = 'C:/Users/mayyav01/Documents/data/LSM510/052713_lfa1/anals/memBlock_pt05oCcl21/';
jobs{end+1} = nextJob;

nextJob{1} = '052713_memIso_2o';
nextJob{2} = 'C:/Users/mayyav01/Documents/data/LSM510/052713_lfa1/anals/memIso_2o/';
nextJob{end} = 28;
jobs{end+1} = nextJob;

nextJob{1} = '052713_memBlock_2o';
nextJob{2} = 'C:/Users/mayyav01/Documents/data/LSM510/052713_lfa1/anals/memBlock_2o/';
nextJob{end} = 28;
jobs{end+1} = nextJob;

nextJob{1} = '052713_memIso_pt05o';
nextJob{2} = 'C:/Users/mayyav01/Documents/data/LSM510/052713_lfa1/anals/memIso_pt05o/';
nextJob{end} = 28;
jobs{end+1} = nextJob;

nextJob{1} = '052713_memBlock_pt05o';
nextJob{2} = 'C:/Users/mayyav01/Documents/data/LSM510/052713_lfa1/anals/memBlock_pt05o/';
nextJob{end} = 28;
jobs{end+1} = nextJob;

% call tcmatBatchScript.m
tcmatBatchScript(jobs);
