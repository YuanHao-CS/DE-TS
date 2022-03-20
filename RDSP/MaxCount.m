%% Calculate the maximum output of the machining system
function MaxMate = MaxCount(CNCNum,RGVPara,MaxTime)
    MaxMate=0;
    for Pro1Num=1:CNCNum-1
        for Pro1Num_I=1:min(Pro1Num,CNCNum/2)
            Pro1Mate=Pro1Num_I*floor(MaxTime/(RGVPara(3)+RGVPara(5)))+(Pro1Num-Pro1Num_I)*floor(MaxTime/(RGVPara(3)+RGVPara(6)));
            Pro2Mate=(CNCNum/2-Pro1Num_I)*floor(MaxTime/(RGVPara(4)+RGVPara(5)))+(CNCNum/2-Pro1Num+Pro1Num_I)*floor(MaxTime/(RGVPara(4)+RGVPara(6)));
            MateOutput=min(Pro1Mate,Pro2Mate);
            MaxMate=max(MaxMate,MateOutput);
        end
    end
end