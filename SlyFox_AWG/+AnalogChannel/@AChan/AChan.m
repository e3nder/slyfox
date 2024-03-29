classdef AChan < hgsetget
    %ACHAN Analog Channel for use in SlyFox_AWG
    %   This Analog Channel backend will store information about waveforms
    %   triggertypes and the like. Waveforms will either be passed as
    %   either and array of (ti Vi) pairs or as cell array of function
    %   handles plus time durations.
    
    properties
        myName = 'Ch0';
        myWaveformType = [];
        myIDnum = 0;
        myTriggerType = 'HwDigital';
        myAdaptor = 'nidaqmx';
        myDefaultVoltageValue = 0;
        myEnabled = 1;
    end
    
    properties (GetAccess = private)
        myWaveform
        % Stored as an array of (ti Vi) pairs
        % or as a cell array of the form:
        %         {{@(t) f(t), [0,tf1]}, {@(t) g(t), [ti2, tf2]},...}
    end
    
    properties (Dependent)
        myWaveformTime
    end
    
    methods
        function obj = AChan(idNum, name, adaptor)
            obj.myName = name;
            obj.myIDnum = idNum;
            obj.myAdaptor = adaptor;
        end
        %%%%%%%%%%%%%%%%%%SET FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = set.myName(obj, value)
            if ~ischar(value)
                error('Name of Channel must be String')
            else
                obj.myName = value;
            end
        end
        function obj = set.myIDnum(obj, value)
            if ~isnumeric(value)
                error('ID number must be Integer')
            else
                obj.myIDnum = value;
            end
        end
        function obj = set.myAdaptor(obj, value)
            if ~ischar(value) && ~strcmp(value, 'nidaqmx')
                error('Adaptor must be one of the following Strings: nidaq')
            else
                obj.myAdaptor = value;
            end
        end
        function obj = set.myTriggerType(obj, value)
            if ~ischar(value) && strcmp(value, 'HwDigital')
                error('TriggerType must be String ')
            else
                obj.myTriggerType = value;
            end
        end
        function obj = set.myWaveformType(obj, value)
            if ~ischar(value) && (~strcmp(value, 'Linear') || ~strcmp(value, 'Function'))
                error('WaveformType must be: StartEnd or Function ')
            else
                obj.myWaveformType = value;
            end
        end
        function obj = set.myWaveform(obj, value)
            %%%Unsafe :/
            obj.myWaveform = value
        end
        function obj = set.myWaveformTime(obj,~)
            fprintf('%s%d\n','myWaveformTime is: ',obj.myWaveformTime)
            error('You cannot set myWaveformTime explicitly'); 
        end
        function obj = set.myDefaultVoltageValue(obj, value)
            % Needs protection somehow...check adaptor name?
            obj.myDefaultVoltageValue = value;
        end
        function obj = set.myEnabled(obj,value)
            obj.myEnabled = value;
        end
        
        %%%%%%%%%%%%%%%%%%GET FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function waveformTime = get.myWaveformTime(obj)
            switch(obj.myWaveformType)
                case 'Linear'
                    waveformTime = obj.myWaveform(end,1);
                case 'Function'
                    waveformTime = obj.myWaveform{end}{2}(2);
            end
        end
        function value = get.myName(obj)
            value = obj.myName;
        end
        function value = get.myIDnum(obj)
            value = obj.myIDnum;
        end
        function value = get.myAdaptor(obj)
            value = obj.myAdaptor;
        end
        function value = get.myTriggerType(obj)
            value = obj.myTriggerType;
        end
        function value = get.myWaveformType(obj)
            value = obj.myWaveformType;
        end
        function value = get.myDefaultVoltageValue(obj)
            value = obj.myDefaultVoltageValue;
        end
        function value = get.myEnabled(obj)
            value = obj.myEnabled;
        end
        %%%%%%%%%%%%%%%%%%WAVEFORM FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%
        function sampledData = sampleWaveform(obj, sampleRate, tEnd)
            %SAMPLEWAVEFORM Creates Discrete sampled waveform
            %   This samples the waveform stored in AChan and this is the 
            %   actual vector that is outputed by the DAQ card. 
            step = 1/sampleRate;
            xi = 0:step:tEnd;
                    
            switch(obj.myWaveformType)
                case 'Linear'
                    X = obj.myWaveform(:,1);
                    Y = obj.myWaveform(:,2);
                    sampledData = interp1(X,Y,xi, 'linear', obj.myDefaultVoltageValue); 
                case 'Function'
                    sampledData = zeros(1,length(xi));
                    numFunctions = size(obj.myWaveform,2);
                    for k=1:numFunctions
                        inRegion = (xi >= obj.myWaveform{k}{2}(1)) & (xi < obj.myWaveform{k}{2}(2));
                        sampledData(inRegion) = obj.myWaveform{k}{1}(xi(inRegion));
                    end
                    %%%%% Special case when last data point is exactly an
                    %%%%% integer number of clock cycles away.
                    if ~mod(obj.myWaveform{k}{2}(2), step)
                        sampledData( xi == obj.myWaveform{end}{2}(2)) = obj.myWaveform{end}{1}(obj.myWaveform{end}{2}(2));
                    end
                    % fill with DefaultVoltageValues if waveform ending
                    % time is less than tEnd (longest waveform on the card)
                    if obj.myWaveform{end}{2}(2) < tEnd
                        sampledData(xi > obj.myWaveform{end}{2}(2)) = obj.myDefaultVoltageValue;
                    end
                    
            end
        end    
    end
    
end

