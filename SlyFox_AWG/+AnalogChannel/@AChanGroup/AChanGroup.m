classdef AChanGroup < hgsetget
    %ACHANGROUP Container for many ACHAN objects
    %   Container for 1 DAQs card worth of analog channels. Arguments for
    %   constructor are as follows:
    %        numChannels (number)
    %        groupName (String)
    %        channelNames (Cell Array - List of Names)
    %        adaptorName (String)
    %        HardwareProperties (Map)
    %          keys:Property Names, values: Property Values
    
    properties (SetAccess = private)
        myDevice = [];
    end
    
    properties (Dependent)
        myOutputData
    end
    
    properties
        myNumChannels = 1;
        myAChans = AnalogChannel.AChan(0,'Ch0', 'nidaqmx');
        myName = 'Dev0'
        myDisplay = [];
        myChanNames = {'Ch0'};
        myAdaptorName = 'nidaqmx'
        myHWProperties = containers.Map(...
            {'SampleRate',...
            'TriggerType'},...
            {50000,...
            'HwDigital'});
    end
    
    methods
%%%%%%%%%%%%%%%%%% CONSTRUCTOR %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = AChanGroup(varargin)
            if nargin >0
                %%%%%%%%%%%%% Steps 1 - assign values to "myValues"
                obj.myNumChannels = varargin{1};
                obj.myName = varargin{2};
                obj.myChanNames{:} = varargin{3};
                obj.myHWProperties = varargin{4};
                
                %%%%%%%%%%%%% Steps 2 - safely create device
                for k=1:obj.myNumChannels
                    obj.addAChan(k,obj.myChanNames{k})
                end
                obj.buildNewDAQSession
            end
        end
%%%%%%%%%%%%%%%%%% SET METHODS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = set.myNumChannels(obj,value)
            if ~(value > 0)
                error('Number of Analog Channels must be positive')
            else
                 obj.myNumChannels = value;
            end
        end % myNumChannels get function  
        function obj = set.myName(obj, value)
            if ~ischar(value)
                error('Name of Channel Group must be String')
            else
                obj.myName = value;
            end
        end % myName set function
        function obj = set.myChanNames(obj, value)
            if ~iscellstr(value) || length(value) ~= obj.myNumChannels
                error('Channel Names must be a Cell Array of Strings')
            else
                obj.myChanNames{:} = value;
                %%%% SET NAMES IN EVERY ACHAN
            end
        end % myChanNames get function    
        function obj = set.myOutputData(obj,~)
            fprintf('%s%d\n','OutputData is: ',obj.Modulus)
            error('You cannot set OutputData explicitly'); 
        end % myOutputData get function
        function obj = set.myAChans(obj, value)
            obj.myAChans(:) = value;
        end
        function obj = set.myDevice(obj,value)
            obj.myDevice = value
        end
        function obj = set.myHWProperties(obj, value)
            obj.myHWProperties = value;
        end
        function obj = set.myAdaptorName(obj, value)
            obj.myAdaptorName = value;
        end
%%%%%%%%%%%%%%%%%% ADD GET METHODS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function value = get.myDevice(obj)
            value = obj.myDevice;
        end
        function value = get.myNumChannels(obj)
            value = obj.myNumChannels;
        end
        function value = get.myAChans(obj)
            value{:} = obj.myAChans;
        end
        function value = get.myName(obj)
            value = obj.myName;
        end
        function value = get.myDisplay(obj)
            value = obj.myDisplay(obj)
        end
        function value = get.myChanNames(obj)
            value{:} = obj.myChanNames;
        end
        function value = get.myHWProperties(obj)
            value = obj.myHWProperties
        end
        function value = get.myAdaptorName(obj)
            value = obj.myAdaptorName;
        end
       
%%%%%%%%%%%%%%%%%%SMART DESTRUCTOR%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% ACTIVE/BUILDER Functions%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function bool = addAChan(obj, newChanID, newChanName)
            %ADDACHAN Adds a new AChan object to this device
            %   newChanID - new channel number
            %   newChanName - new channel name
            
            %Try to add to device
            try
                addchannel(obj.myDevice, newChanID);
                newAChan = AChan(newChanID, newChanName, obj.myAdaptorName);
                set(obj, 'myAChans', [obj.myAChans; newAChan]);
                bool = 1;
            catch exception
                bool = 0;
                error('Channel could not be added to device object');
            end
        end
        function buildNewDAQSession(obj)
            %BUILDNEWDAQSESSION Builds new DAQ and DAQ channels
            %   This needs to be done whenever you want to change the the
            %   output data as there is no "FLUSH DATA" function for the
            %   DAQ. This is absolutely horrible and Mathworks should be
            %   ashamed of themselves.....shuuuunnnn.
            
            %Check to see if a DAQ Device object is still around, if so
            %delete and clear it.
            if isvalid(obj.myDevice)
                delete(obj.myDevice);
                clear(obj.myDevice); %is this ok?
            end
            propNames = keys(obj.myHWProperties);
            propValues = values(obj.myHWProperties, propNames);
            obj.myDevice = analogoutput(obj.myAdaptor, obj.myName);
            set(obj.myDevice, propNames, propValues); % Setting Global Properties
            
            
            channelNames{:} = obj.myAChans{:}.myName; 
            addchannels(obj.myDevice, 0:obj.myNumChannels, channelNames)% Adds correct number of channels
            
            ID{:} = obj.myAChans{:}.myIDnum;
            
            %Sets Channel DefaultVoltageValue
            obj.myDevice.OutOfDataMode = 'DefaultValue';
            defaultVval{:} = obj.myAChans{:}.myDefaultVoltageValue;
            obj.myDevice.Channel(ID{:}).DefaultChannelValue = defaultVval{:};
            
            %Sets Hardware Trigger Channel
            TrigChannels{:} = obj.myAChans{:}.myTriggerPort;
            obj.myDevice.Channel(ID{:}).HwDigitalTriggerSource = TrigChannels{:};
        end
        function bool = uploadData(obj) %%%%% NOT DONE YET
            try
                if strcmp(get(obj.myDevice, 'Running'), 'On')
                    stop(obj.myDevice);
                end
                %%%%NEED TO SET HW PROPERTIES AND CHANNEL TRIGGERS
                data = obj.assembleOutputData();
                putdata(obj.myDevice, data);
                bool = 1;
                start(obj.myDevice);
            catch exception
                bool = 0;
            end
        end
% function loadAChanGroup - should be public WRONG? - MAYBE SHOULD BE AS
% HIGH LEVEL AS POSSIBLE
% function saveAChanGroup - should be public WRONG? - MAYBE SHOULD BE AS
% HIGH LEVEL AS POSSIBLE
% function enableAChan - should be public  Start/Stops output without
%                       destroying waveform
% function disableAChan - should be public Start/Stops output without
%                       destroying waveform
    end
    %%%%%%%%%%%%%%%%%%HELPER FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access = private)
        
        function tEnd = findLongestWaveform(obj)
            times(:) = obj.myAChans(:).myWaveformTime %not ; for debugging purposes
            tEnd = max(times);
        end
        
        function maxSampleRate = findMaxSampleRate(obj)
            %FINDMAXSAMPLERATE Finds maximum sample rate
            %   This function finds the maximum sample rate assuming that
            %   the only limiting constraints are 1) the length of the
            %   longest waveform and 2) the maximum amount of samples that
            %   can be stored by the Analog Out card given the number of
            %   channels.
            maxSamples = obj.myDevice.MaxSamplesQueued; %takes into account scaling with # of channels.
            out = daqhwinfo(obj.myDevice);
            maxCARDSampleRate = out.MaxSampleRate;
            tend = obj.findLongestWaveform;
            if maxCardSampleRate*tend > maxSamples
                maxSampleRate = floor(maxSamples/tend);
            else
                maxSampleRate = maxCARDSampleRate;
            end
        end
        function data = assembleOutputData(obj)
            sampleRate = obj.myHWProperties('SampleRate');
            tEnd = obj.findLongestWaveform;
            samples = floor(tEnd*sampleRate)+1;
            numChannels = obj.myNumChannels;
            data = zeros([samples numChannels]); %Preallocate for speed
            for k = 1:numChannels
                data(:,k) = obj.myAChans(k).sampleWaveform(sampleRate, tEnd);
            end %Populate each column of data
        end
    end
    
end

