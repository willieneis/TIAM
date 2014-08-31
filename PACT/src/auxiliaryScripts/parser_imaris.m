function resultcell = parser_imaris(pathStr)
    dat = importdata(pathStr); dat = dat.data;
    dat(:,1) = (dat(:,1) - 1000000000)+1;
    resultcell = {};
    for id=1:max(dat(:,1))
        nextMat = dat(find(dat(:,1) == id),:);
        nextMat(:,1) = nextMat(1,2);
        nextMat(:,2) = nextMat(1,1)+size(nextMat,1)-1;
        resultcell{id} = nextMat;
    end
end
