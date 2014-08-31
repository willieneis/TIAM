function gtcell = gt2gtcell(viper_text_file)

    % this is expecting a viper .txt file

    gtcell = {};
    file = fopen(viper_text_file);

    breakout = 0;
    nextline = fgetl(file);
    while(length(strfind(nextline, 'OBJECT')) == 0  && breakout == 0)
        nextline = fgetl(file);
        if length(nextline > 0)
            if nextline(1) == -1
                breakout = 1;
            end
        end
    end
    nextline = fgetl(file);

    while(length(strfind(nextline, 'END_DATA')) == 0  &&  breakout == 0)
        while(length(strfind(nextline, 'OBJECT')) == 0  && breakout == 0)
            nextline = fgetl(file);
            if length(nextline > 0)
                if nextline(1) == -1
                    breakout = 1;
                end
            end
        end
        if breakout == 0

            [tok, remain] = strtok(nextline);
            for t = 1 : 3
                [tok, remain] = strtok(remain);
            end

            r = strfind(tok, ':');
            next_startframe = str2num(tok(1:r-1));
            nextline = fgetl(file);
            nextline = fgetl(file);

            k = strfind(nextline, ':');
            if length(k > 0)
                stringtosave = nextline(k(1):end);
                gtcell = addstring2gtcell(gtcell, stringtosave, next_startframe);
            end
        end
    end

    function gtcell = addstring2gtcell(gtcell, string, startframe)
        newrect = [];
        temp = get_tokens(string, '"');
        for i = 2 : 2 : size(temp, 1)
            nextrect = str2num(temp{i});
            mult = regexp(temp{i-1}, '[0123456789]');
            if length(mult) > 0
                num = str2num(temp{i-1}(mult(1):mult(end)));
                nextrect = repmat(nextrect, [num, 1]);
                newrect = [newrect; nextrect];
            else
                newrect = [newrect; nextrect];
            end
        end
        newrect(:, 3:6) = newrect;
        newrect(:, 1) = startframe;
        newrect(:, 2) = size(newrect, 1) + startframe - 1;
        gtcell{end+1} = newrect;
    end

end
