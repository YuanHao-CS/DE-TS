classdef DETS< ALGORITHM
% <single> <real> <large/none> <expensive/none>
% Differential Evolution Algorithm Based on Transdifferentiation Strategy
% Mu   --- 0.8 --- Debilitating Factor
% Alpha--- 0.5 --- Environmental Pressure

%------------------------------- Reference --------------------------------
% 
%------------------------------- Copyright --------------------------------
% Copyright (c) 2018-2019 BIMK Group. You are free to use the PlatEMO for
% research purposes. All publications which use this platform or any code
% in the platform should acknowledge the use of "PlatEMO" and reference "Ye
% Tian, Ran Cheng, Xingyi Zhang, and Yaochu Jin, PlatEMO: A MATLAB platform
% for evolutionary multi-objective optimization [educational forum], IEEE
% Computational Intelligence Magazine, 2017, 12(4): 73-87".
%--------------------------------------------------------------------------

% This function is written by Yuanhao Jiang,
% e-mail:jiangyuanhao@stu.just.edu.cn

    methods
        function main(Algorithm,Problem)
            %% Parameter setting
            [Mu,Alpha] = Algorithm.ParameterSet(0.8,0.5);
            
            %% Generate random population
            CNCNum=Problem.CNCNum;
            RGVPara=Problem.RGVPara;
            Population=Problem.Initialization();
            PopulationDecs=Population.decs;
             Proc1Num=RGVPara(3)/(RGVPara(3)+RGVPara(4))*CNCNum;
            %% Optimization
            while Algorithm.NotTerminated(Population)
                %% 1 Use the DE operator to generate offspring
                OffspringDecs=OperatorDE(PopulationDecs,PopulationDecs(randperm(size(PopulationDecs,1)),:),PopulationDecs(randperm(size(PopulationDecs,1)),:));
                OffspringDecs=round(OffspringDecs);
                for i=1:size(OffspringDecs,1)
                    %% 2 Determining LoopNum based on the debilitating factor
                    Layer=ceil(log(0.01/(1-Mu+0.01))/log(Mu));
                    ProbSumTmp=zeros(1,Layer);
                    for j=1:Layer;ProbSumTmp(j:end)=ProbSumTmp(j:end)+1;end
                    for j=1:Layer;ProbSumTmp(j)=power(Mu,j-1);end
                    LoopNum=RouletteWheelSelection(1,1./ProbSumTmp);           
                    
                    %% 3 Offspring evolution
                    OffspringDecs(i,:)=SoluEvol(CNCNum,Proc1Num,LoopNum,OffspringDecs(i,:));
                    
                end
                
                %% 4 Update population
                MixedPopulation=[SOLUTION(OffspringDecs),Population];
                PopulationObjs=MixedPopulation.objs;
                [~,Index]=sort(PopulationObjs);
                MixedPopulation=MixedPopulation(Index(1:size(Index,1)/2));
                NewPopNum=floor(Alpha*size(MixedPopulation,2));
                PopulationDecs=MixedPopulation.decs();
                NewPop=PopChange(CNCNum,PopulationDecs(size(MixedPopulation,2)-NewPopNum+1:end,:));
                Population=[MixedPopulation(1:size(MixedPopulation,2)-NewPopNum),SOLUTION(NewPop)];
            end
        end
    end
end

%% RandSort：Shuffle the order of the Data
function Data=RandSort(Data)
    Data=Data(randperm(size(Data, 2)));
end% End of RandSort

%% SoluEvol：Fix OffspringDecs for offspring
function OffspringDecs=SoluEvol(CNCNum,Proc1Num,LoopNum,OffspringDecs)
    %% 1 Repair tool installation with as few changes as possible
    if rand()<mod(Proc1Num,1)
        Proc1Tmp=ceil(Proc1Num);
    else
        Proc1Tmp=floor(Proc1Num);
    end
    if sum(OffspringDecs(1:CNCNum))>Proc1Tmp
        tmp=sum(OffspringDecs(1:CNCNum))-Proc1Tmp;
        CNCI=RandSort(find(OffspringDecs(1:CNCNum)==1));
        OffspringDecs(CNCI(1:tmp))=0;
    elseif sum(OffspringDecs(1:CNCNum))<Proc1Tmp
        tmp=Proc1Tmp-sum(OffspringDecs(1:CNCNum));
        CNCII=RandSort(find(OffspringDecs(1:CNCNum)==0));
        OffspringDecs(CNCII(1:tmp))=1;
    end

    %% 2 Generate random repair sequences
    ToolI=sum(OffspringDecs(1:CNCNum));
    ToolII=CNCNum-ToolI;
    LoopLenth=LoopNum*ToolI*(CNCNum-ToolI);
    LoopRand=randperm(LoopLenth);
    ToolCount=[OffspringDecs(1:CNCNum);OffspringDecs(1:CNCNum)*0+ToolI*LoopNum];
    ToolCount(2,:)=ToolCount(2,:)+ToolCount(1,:)*((CNCNum-ToolI)-ToolI)*LoopNum;
    ToolArra1=[];ToolArra2=[];
    for j=1:CNCNum
        if ToolCount(1,j)==1
            ToolArra1=[ToolArra1,j];
        else
            ToolArra2=[ToolArra2,j];
        end
    end
    for j=1:LoopLenth
        %% 3 Repair process I in the random order generated
        LoopTmp=LoopRand(j);
        LoopITmp=floor(OffspringDecs(CNCNum+LoopTmp)/100);
        LoopIITmp=round(OffspringDecs(CNCNum+LoopTmp)-LoopITmp*100);
        if (LoopITmp>=1&&LoopITmp<=ToolI)&&(ToolCount(2,ToolArra1(LoopITmp))>=1)
            ToolCount(2,ToolArra1(LoopITmp))=ToolCount(2,ToolArra1(LoopITmp))-1;
        else
            ListTmp=[];
            for k=1:ToolI
                if ToolCount(2,ToolArra1(k))>=1
                    ListTmp=[ListTmp,k];
                end
            end
            LoopITmp=ListTmp(max(1,round(rand()*(size(ListTmp,2)))));
            ToolCount(2,ToolArra1(LoopITmp))=ToolCount(2,ToolArra1(LoopITmp))-1;
        end

        %% 4 Repair process II in the random order generated
        if (LoopIITmp>=1&&LoopIITmp<=ToolII)&&(ToolCount(2,ToolArra2(LoopIITmp))>=1)
            ToolCount(2,ToolArra2(LoopIITmp))=ToolCount(2,ToolArra2(LoopIITmp))-1;
        else
            ListTmp=[];
            for k=1:ToolII
                if ToolCount(2,ToolArra2(k))>=1
                    ListTmp=[ListTmp,k];
                end
            end
            LoopIITmp=ListTmp(max(1,round(rand()*(size(ListTmp,2)))));
            ToolCount(2,ToolArra2(LoopIITmp))=ToolCount(2,ToolArra2(LoopIITmp))-1;%访问该CNC并计次
        end
        OffspringDecs(CNCNum+LoopTmp)=LoopITmp*100+LoopIITmp;
    end
    
    %% 5 Augmented decision vector dimension
    Loop=OffspringDecs(CNCNum+1:CNCNum+LoopLenth);
    for k=1:floor((size(OffspringDecs,2)-CNCNum)/LoopLenth)
        OffspringDecs(CNCNum+(k-1)*LoopLenth+1:CNCNum+k*LoopLenth)=Loop;
    end
end% End of SoluEvol

%% PopChange：Shuffle and regenerate the decision vector of the population
function PopDecs=PopChange(CNCNum,PopDecs)
    for i=1:size(PopDecs,1)
        ProcTmp=PopDecs(i,1:CNCNum);
        PopDecs(i,1:CNCNum)=ProcTmp(randperm(CNCNum));
        CNCINum=sum(ProcTmp);CNCIINum=CNCNum-CNCINum;
        CNCITmp=repmat((randperm(CNCINum)),1,CNCIINum/gcd(CNCINum,CNCIINum));
        CNCIITmp=repmat((randperm(CNCIINum)),1,CNCINum/gcd(CNCINum,CNCIINum));
        Loop=CNCITmp*100+CNCIITmp; 
        AllLoop=repmat(Loop,1,ceil((size(PopDecs,2)-CNCNum)/size(Loop,2)));
        PopDecs(i,CNCNum+1:end)=AllLoop(1:(size(PopDecs,2)-CNCNum));
    end
end% End of PopChange