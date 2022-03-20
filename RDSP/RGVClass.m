classdef RGVClass < handle

    properties%(Access = private)
        %CNC parameters
        CNCNum
        MaxMate
        ToolArra1
        ToolArra2
        Tool2Flag
        ProcArra1
        ProcArra2
        
        %RGV parameters
        FirsTran
        NextTran
        CNCProc1
        CNCProc2
        CNCLoad1
        CNCLoad2
        MateWash
        
        %Status information
        M
        CurrSite=1
        CNCStat
        ProcDays
        Day=1
        CurrSeco=0
        ObjVal
        Orde=1
    end
    
    methods
        function obj = RGVClass(ProcDays,M,CNCNum,RGVPara,Solu)
            %RGV  parameters
            obj.FirsTran=RGVPara(1);
            obj.NextTran=RGVPara(2);
            obj.CNCProc1=RGVPara(3);
            obj.CNCProc2=RGVPara(4);
            obj.CNCLoad1=RGVPara(5);
            obj.CNCLoad2=RGVPara(6);
            obj.MateWash=RGVPara(7);
            
            %CNC parameters
            obj.ProcDays=ProcDays;
            MaxTime=ProcDays*24*60*60;
            obj.ObjVal=zeros(1,ProcDays*2);
            obj.M=M;
            obj.MaxMate=MaxCount(CNCNum,RGVPara,MaxTime);
            obj.CNCNum=CNCNum;
            obj.CNCStat=zeros(1,obj.CNCNum);
            for i=1:obj.CNCNum
                if Solu(1,i)==1
                    obj.ToolArra1=[obj.ToolArra1,i];
                else
                    obj.ToolArra2=[obj.ToolArra2,i];
                end
            end
            obj.Tool2Flag=0*obj.ToolArra2;
            ProcArra=Solu(1,obj.CNCNum+1:size(Solu,2));
            obj.ProcArra1=floor(ProcArra/100);
            obj.ProcArra2=floor(mod(ProcArra,100));
        end
        
        %% RGV Scheduling Execution Function: execute all complete processing
        function ObjVal=RGVSche(obj)
            % 1 Execute all instructions in order
            for Orde=1:size(obj.ProcArra1,2)
                obj.Orde=Orde;
                obj.RGVSingSche();
                if obj.Day>obj.ProcDays
                    break;
                end
            end
            
            % 2 Calculate return value
            tmp=reshape(obj.ObjVal,2,obj.ProcDays);
            if obj.M==1
                ObjVal=1-(sum(tmp(1,:))/obj.MaxMate);
            elseif obj.M==2
                ObjVal=[1/sum(tmp(1,:)),sum(tmp(2,:))];
            end
            
            % 3 Output result
            if obj.Day>=obj.ProcDays
                Timer=obj.TimeConvert();
                disp(Timer(1)+"Day "+Timer(2)+"h "+Timer(3)+":"+Timer(4)...
                    +" ，output="+sum(tmp(1,:))+"，RGV mobile unit="+sum(tmp(2,:))...
                    +"，loss="+ObjVal*100+"%");
            end
            

        end
        
        %% RGV Single Scheduling Execution Function: execute a complete processing
        function RGVSingSche(obj)
            if obj.Day<=obj.ProcDays
                obj.RGVTran(obj.ToolArra1(obj.ProcArra1(1,obj.Orde)));
                obj.RGVLoad();
                obj.RGVTran(obj.ToolArra2(obj.ProcArra2(1,obj.Orde)));
                obj.RGVLoad();
            end
        end
        
        %% RGV Move Function: move RGV from current location CurrSite to NextSite
        function RGVTran(obj,NextSite)
            RealCurrSite=ceil(obj.CurrSite/2);
            RealNextSite=ceil(NextSite/2);
            if RealCurrSite~=RealNextSite
                Time=obj.FirsTran+(abs(RealNextSite-RealCurrSite)-1)*obj.NextTran;
                obj.TimePass(Time);
                if obj.Day<=obj.ProcDays
                    obj.ObjVal(1,obj.Day*2)=obj.ObjVal(1,obj.Day*2)+Time;
                end
            end
            obj.CurrSite=NextSite;
        end
        
        %% RGV Loading and Unloading Function: RGV loading and unloading at CurrSite
        function RGVLoad(obj)
            % 1 Wait for the CNC at CurrSite to finish the current machining
            obj.TimePass(obj.CNCStat(obj.CurrSite));
            if mod(obj.CurrSite,2)==1
                obj.TimePass(obj.CNCLoad1);
            else
                obj.TimePass(obj.CNCLoad2);
            end
            
            % 2 Perform loading and unloading operations by CNC category
            if isempty(find(obj.ToolArra2==obj.CurrSite,1))==0
                obj.CNCStat(obj.CurrSite)=obj.CNCProc2;
                if obj.Tool2Flag(obj.ProcArra2(obj.Orde))==0
                    obj.Tool2Flag(obj.ProcArra2(obj.Orde))=1;
                else
                    obj.TimePass(obj.MateWash);
                    if obj.Day<=obj.ProcDays
                        obj.ObjVal(obj.Day*2-1)=obj.ObjVal(obj.Day*2-1)+1;
                    end
                end
            else
                obj.CNCStat(obj.CurrSite)=obj.CNCProc1;
            end
            
        end
        
         %% Time Jump Function: current time jumps after Time
        function TimePass(obj,Time)
            obj.CNCStat=max(0,obj.CNCStat-Time);
            obj.CurrSeco=obj.CurrSeco+Time;
            if obj.CurrSeco>=86400
                obj.CurrSeco=obj.CurrSeco-86400;
                obj.Day=obj.Day+1;
            end
        end
        
        %% Time Conversion Function: convert time format
        function Timer=TimeConvert(obj)
            Timer=[0,0,0,0];
            Timer(1)=obj.Day;
            Timer(2)=floor(obj.CurrSeco/(60*60));
            LastHourSeco=mod(obj.CurrSeco,60*60);
            Timer(3)=floor(LastHourSeco/60);
            Timer(4)=mod(LastHourSeco,60);
        end
        
    end
end