function metric = pm_fda(rectmat1, rectmat2, opt)

% rectmat1 contains all detects of results (at frame t)
% rectmat2 contains all detects of gt (at frame t)

if nargin<3, opt = []; end

L = size(rectmat1, 1);
M = size(rectmat2, 1);
if L > M
	rectmat2(end+1:L, :) = 0;
else
	rectmat1(end+1:M, :) = 0;
end
N = size(rectmat1, 1);

metmat = [];
for i = 1 : N
	for j = 1 : N
		if rectmat1(i,3) == 0  ||  rectmat2(i,3) == 0
			metmat(i,j) = 0;
		else
			metmat(i,j) = pm_overlapratio(rectmat1(i, :), rectmat2(j, :), opt);
		end
	end
end
metmat2 = max(metmat(:)) - metmat;
[assig, cost] = munkres(metmat2);
costvec = [];
for i = 1 : length(assig)
	costvec(i) = metmat(i, assig(i));
end
numer = sum(costvec);
denom = mean(L, M);
metric = numer / denom;
