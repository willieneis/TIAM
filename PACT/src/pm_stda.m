function value = pm_stda(rectmat1, rectmat2, opt)

% rectmat1 contains all detects of track1
% rectmat2 contains all detects of track2
	% they are same length. There are elements rect = [0 0 0 0] during points of non-alignment

if not(size(rectmat1,1)==size(rectmat2,1))
    error('ERROR==>pm_stda: inputs rectmat1 and rectmat2 are not the same size.')
end

if nargin<3, opt = []; end

for t=1:size(rectmat1,1)
	if rectmat1(t,3)==0 || rectmat2(t,3)==0
		olr_vec(t) = 0;
	else
		olr_vec(t) = pm_overlapratio(rectmat1(t, :), rectmat2(t, :), opt);
	end
end
value = sum(olr_vec) / size(rectmat1,1);
