
function do_use = determine_if_use(mp, md)
    do_use = 1;
    if isnan(md)
        do_use=0;
    end
    if abs(md-mp) < .2*max(md, mp) || ...
            mp - md > .3*max(md, mp)
        do_use=0;
    end
end