classdef RDSP2 < PROBLEM
% <single> <real> <large/none> <expensive/none>
% RGVDSP2 - Rali Guided Vehicle Dynamic Scheduling Problem2.
% CNCNum   ---   8 --- Number of CNCs
% ProcDays ---   7 --- Continuous processing days of CNCs

%------------------------------- Reference --------------------------------
%
%------------------------------- Copyright --------------------------------
% Copyright (c) 2021 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

    properties%(Access = private)
        ProcDays=7;
        CNCNum=8;
        RGVPara=[23 18 280 500 30 35 30];
    end
    methods
        %% Default settings of the problem
        function Setting(obj)
            [obj.CNCNum,obj.ProcDays,obj.M] = obj.ParameterSet(8,7,1);
            if obj.CNCNum<8
                obj.CNCNum=8;
            end
            if mod(obj.CNCNum,2)~=0
                obj.CNCNum=round(mod(obj.CNCNum,2))*2;
            end
            DI=obj.CNCNum+floor(obj.ProcDays*24*60*60/obj.RGVPara(3))*ceil(obj.CNCNum*obj.RGVPara(3)/sum(obj.RGVPara(3:4)));
            DII=obj.CNCNum+floor(obj.ProcDays*24*60*60/obj.RGVPara(4))*ceil(obj.CNCNum*obj.RGVPara(4)/sum(obj.RGVPara(3:4)));
            obj.D = max(DI,DII);
            obj.encoding = 'real';
            obj.lower=[zeros(1,obj.CNCNum),101*ones(1,obj.D-obj.CNCNum)];
            obj.upper=[ones(1,obj.CNCNum),((obj.CNCNum-1)*100+1)*ones(1,obj.D-obj.CNCNum)];
        end
        
        %% Perform a repair operation on the population
        function PopDec = CalDec(obj,PopDec)
            ToolCode=mod(round(PopDec(:,1:obj.CNCNum)),2);
            for i=1:size(ToolCode,1)
                if sum(ToolCode(i,:))==0
                    ToolCode(i,max(1,round(obj.CNCNum*rand())))=1;
                elseif sum(ToolCode(i,:))==obj.CNCNum
                    ToolCode(i,max(1,ceil(obj.CNCNum*rand())))=0;
                end
            end
            ProcArra=round(PopDec(:,obj.CNCNum+1:end));
            ProcArra1=floor(ProcArra/100);
            ProcArra2=round(mod(ProcArra,100));
            Proc1Num=sum(ToolCode,2);
            Proc2Num=obj.CNCNum-sum(ToolCode,2);
            for i=1:size(ProcArra,1)
                Proc1Label=[find(ProcArra1(i,:)>Proc1Num(i)),find(ProcArra1(i,:)<1)];
                ProcArra1(i,Proc1Label)=round(unifrnd(1,Proc1Num(i),1,size(Proc1Label,2)));
                Proc1Labe2=[find(ProcArra2(i,:)>Proc2Num(i)),find(ProcArra2(i,:)<1)];
                ProcArra2(i,Proc1Labe2)=round(unifrnd(1,Proc2Num(i),1,size(Proc1Labe2,2)));
            end
            ProcArra=ProcArra1*100+ProcArra2;
            PopDec=[ToolCode,ProcArra];
        end
        
        %% Calculate objective values
        function PopObj = CalObj(obj,PopDec)
            PopObj=zeros(size(PopDec,1),obj.M);
            for i=1:size(PopDec,1)
                RGV=RGVClass(obj.ProcDays,obj.M,obj.CNCNum,obj.RGVPara,PopDec(i,:));
                PopObj(i,:)=RGV.RGVSche();
                delete(RGV);
            end
        end
    end
end