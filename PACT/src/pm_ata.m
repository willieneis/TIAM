function metric = pm_ata(resultcell, gtcell, opt)

% resultcell contains a sequence of object-result-matrices (each matrix has position of objects for a sequence of frames)
% gtcell contains a sequence of gt-result-matrices (each matrix has a position of objects for a sequence of frames)

if nargin<3, opt = []; end

% make resultcell and gtcell the same length
M = length(resultcell);
L = length(gtcell);
if L > M
	resultcell(end+1:L) = cell(1,length(length(resultcell)+1:L));
else
	gtcell(end+1:M) = cell(1,length(length(gtcell)+1:M));
end
N = length(resultcell);

% construct metmat similarity matrix for Hungarian/Munkres algorithm
metmat = [];
for i = 1 : N
	for j = 1 : N
		if size(resultcell{i},1)>0 && size(gtcell{j},1) > 0
			minstartframe = min([resultcell{i}(1,1),gtcell{j}(1,1)]);
			maxendframe = max([resultcell{i}(1,1)+size(resultcell{i},1), gtcell{j}(1,1)+size(gtcell{j},1)]);
			rectmat1 = zeros(maxendframe - minstartframe + 1, 4);
			rectmat2 = zeros(maxendframe - minstartframe + 1, 4);
			rectmat1(resultcell{i}(1,1)-minstartframe+1:resultcell{i}(1,1)-minstartframe+1+size(resultcell{i},1)-1,:) = resultcell{i}(:,3:end);
			rectmat2(gtcell{j}(1,1)-minstartframe+1:gtcell{j}(1,1)-minstartframe+1+size(gtcell{j},1)-1,:) = gtcell{j}(:,3:end);
			metmat(i,j) = pm_stda(rectmat1,rectmat2,opt);
		else
			metmat(i,j) = 0;
		end
	end
end

% convert similarity matrix into distance matrix
metmat2 = max(metmat(:)) - metmat;

% run Hungarian/Munkres algorithm
[assig,cost] = munkres(metmat2);

% make costvec, which holds STDAs of assigned tracks (from metmat)
for i = 1:length(assig)
	costvec(i) = metmat(i,assig(i));
end

% compute ATA
numer = sum(costvec);
denom = mean(L,M);
metric = numer / denom;
