classdef DDS_Frontend < hgsetget
    %DDS_FRONTEND GUI for controlling a DDS_Config Object
    %   DDS_Frontend has a panel and a DDS_Config object. In the panel it
    %   has many controls to change the various parameters of a DDS_Config
    %   object and also to change the characteristics of the DDS output.
    %   Written by Ben Bloom 10/4/2011
    
    properties
        myTopFigure = [];
        myTitlePanel = [];
        myPanel = [];
        myDDS;
        mySerial;
        myBoardAddr;
        myCurrentMode = 1;
        myAvailableModes = {'Single Tone', 'FSK', 'Ramped FSK', 'Chirp', 'BPSK'};
    end
    
    methods
        function obj = DDS_Frontend(topFig, parentObj, boardAddr)
            obj.myTopFigure = topFig;
            obj.myTitlePanel = uiextras.Panel('Parent', parentObj, ...
                'Title', ['DDS' num2str(boardAddr)]);
            obj.myPanel = uiextras.HBox('Parent', obj.myTitlePanel, ...
                'Spacing', 5, ...
                'Padding', 5);
            obj.myDDS = DDS.DDS_Config(boardAddr);
            obj.myBoardAddr = boardAddr;
            
            buttonVBox = uiextras.VBox('Parent', obj.myPanel, ...
                'Spacing', 5, ...
                'Padding', 5);
                uiextras.Empty('Parent', buttonVBox);
                uicontrol(...
                           'Parent', buttonVBox,...
                           'Style', 'popupmenu', ...
                           'Tag', 'cardList',...
                           'String', {'AD9854'});
                uicontrol(...
                                'Parent', buttonVBox,...
                                'Style', 'pushbutton', ...
                                'Tag', 'sendCommand',...
                                'String', 'Send Command',...
                                'Callback', @obj.sendCommand_Callback);
                sysClkHB = uiextras.HBox('Parent', buttonVBox, ...
                    'Padding', 5, ...
                    'Spacing', 5);
                    uicontrol(...
                        'Parent', sysClkHB, ...
                        'Style', 'text', ...
                        'String', 'SysCLK (MHz)');
                    uicontrol(...
                        'Parent', sysClkHB, ...
                        'Style', 'edit', ...
                        'String', '200', ...
                        'Tag', ['sysClk' num2str(obj.myBoardAddr)]);
                uiextras.Empty('Parent', buttonVBox);
                set(buttonVBox, 'Sizes', [-3 -1 -2 -1 -3]);
            modeTabPanel = uiextras.TabPanel('Parent', obj.myPanel, ...
                'Tag', 'modeTabPanel', ...
                'Callback', @obj.modeTabPanel_Callback);
            
                stVB = uiextras.VBox('Parent', modeTabPanel);
                    uiextras.Empty('Parent', stVB);
                    stHB = uiextras.HBox('Parent', stVB, ...
                        'Spacing', 5, ...
                        'Padding', 5);
                        textVB = uiextras.VBox('Parent', stHB);
                            uiextras.Empty('Parent', textVB);
                            uicontrol(...
                                'Parent', textVB,...
                                'Style', 'text', ...
                                'FontWeight', 'bold', ...
                                'FontUnits', 'normalized', ...
                                'FontSize', 0.5, ...
                                'String', 'Frequency (MHz)');
                            uiextras.Empty('Parent', textVB);
                            textVB.Sizes = [-1 -4 -1];
                        uicontrol(...
                            'Parent', stHB,...
                            'Style', 'edit', ...
                            'Tag', ['stFTW' num2str(obj.myBoardAddr)],...
                            'FontUnits', 'normalized', ...
                            'FontSize', 0.5, ...
                            'String', '75.000000');
                        stHB.Sizes = [-2 -1];
                    uiextras.Empty('Parent', stVB);
                    stVB.Sizes = [-2 -1 -2];
                FSKVB = uiextras.VBox('Parent', modeTabPanel, ...
                    'Spacing', 5, ...
                    'Padding', 5);
                    FSKHBcontrol = uiextras.HBox('Parent', FSKVB);
                        uiextras.Empty('Parent', FSKHBcontrol);
                        uicontrol(...
                            'Parent', FSKHBcontrol, ...
                            'Style', 'popupmenu', ...
                            'Tag', ['FSKsetting' num2str(obj.myBoardAddr)], ...
                            'FontUnits', 'normalized', ...
                            'FontSize', 0.2, ...
                            'String', {'Send F1&F2', ...
                                'Send F1', ...
                                'Send F2', ...
                                'Pseudo-Single Tone'});
                        uiextras.Empty('Parent', FSKHBcontrol);
                    FSKHB0 = uiextras.HBox('Parent', FSKVB, ...
                        'Spacing', 5, ...
                        'Padding', 5);
                        text2VB = uiextras.VBox('Parent', FSKHB0);
                            uiextras.Empty('Parent', text2VB);
                            uicontrol(...
                                'Parent', text2VB,...
                                'Style', 'text', ...
                                'FontWeight', 'bold', ...
                                'FontUnits', 'normalized', ...
                                'FontSize', 0.6, ...
                                'String', 'Frequency 1 (MHz)');
                            uiextras.Empty('Parent', text2VB);
                            text2VB.Sizes = [-1 -4 -1];
                        uicontrol(...
                            'Parent', FSKHB0,...
                            'Style', 'edit', ...
                            'Tag', ['fskFTW1' num2str(obj.myBoardAddr)],...
                            'FontUnits', 'normalized', ...
                            'FontSize', 0.6, ...
                            'String', '70.000000');
                        FSKHB0.Sizes = [-2 -1];
                    uiextras.Empty('Parent', FSKVB);
                    FSKHB1 = uiextras.HBox('Parent', FSKVB, ...
                        'Spacing', 5, ...
                        'Padding', 5);
                        text3VB = uiextras.VBox('Parent', FSKHB1);
                            uiextras.Empty('Parent', text3VB);
                            uicontrol(...
                                'Parent', text3VB,...
                                'Style', 'text', ...
                                'FontWeight', 'bold', ...
                                'FontUnits', 'normalized', ...
                                'FontSize', 0.6, ...
                                'String', 'Frequency 2 (MHz)');
                            uiextras.Empty('Parent', text3VB);
                            text3VB.Sizes = [-1 -4 -1];
                        uicontrol(...
                            'Parent', FSKHB1,...
                            'Style', 'edit', ...
                            'Tag', ['fskFTW2' num2str(obj.myBoardAddr)],...
                            'FontUnits', 'normalized', ...
                            'FontSize', 0.6, ...
                            'String', '80.000000');
                        FSKHB1.Sizes = [-2 -1];
                    uiextras.Empty('Parent', FSKVB);
                    FSKVB.Sizes = [-2 -1 -2 -1 -2];
                rFSKGrid = uiextras.VBox('Parent', modeTabPanel);
                CHIRPGrid = uiextras.VBox('Parent', modeTabPanel);
                BPSKGrid = uiextras.VBox('Parent', modeTabPanel);
            modeTabPanel.TabNames = obj.myAvailableModes;
            modeTabPanel.SelectedChild = 1;
            set(obj.myPanel, 'Sizes', [-1 -3]);
        end
        
        function modeTabPanel_Callback(obj, src, eventData)
            obj.myCurrentMode = eventData.SelectedChild;
        end
        function sendCommand_Callback(obj, src, eventData)
            myHandles = guidata(obj.myTopFigure);
            myMode = obj.myAvailableModes{obj.myCurrentMode};
            
            obj.myDDS.mySysClk = str2double(get(myHandles.(['sysClk' num2str(obj.myBoardAddr)]), 'String'));
            
            switch myMode
                case 'Single Tone'
                    freq = str2double(get(myHandles.(['stFTW' num2str(obj.myBoardAddr)]), 'String'));
                    [oFreq, ftw] = obj.myDDS.calculateFTW(freq);
                    params = struct('FTW1', ftw);
                    
                    iSet = obj.myDDS.createInstructionSet(myMode, params);
                    fwrite(obj.mySerial, iSet{1});
                    fscanf(obj.mySerial);
                case 'FSK'
                    if get(myHandles.(['FSKsetting'  num2str(obj.myBoardAddr)]), 'Value') == 1
                        freq1 = str2double(get(myHandles.(['fskFTW1' num2str(obj.myBoardAddr)]), 'String')); 
                        freq2 = str2double(get(myHandles.(['fskFTW2' num2str(obj.myBoardAddr)]), 'String')); 
                        [oFreq, ftw] = obj.myDDS.calculateFTW([freq1 freq2]);
                        params = struct('FTW1', ftw(1,:), 'FTW2', ftw(2, :), 'WriteMode', 1);
                        
                        iSet = obj.myDDS.createInstructionSet(myMode, params);
                        fwrite(obj.mySerial, iSet{1});
                        fscanf(obj.mySerial)
                        fwrite(obj.mySerial, iSet{2});
                        fscanf(obj.mySerial)
                    end
            end
            
            if ~strcmp(myMode, obj.myDDS.myMode)
                params = struct('NEWMODE', myMode);
                iSet = obj.myDDS.createInstructionSet('CHANGEMODE', params);
                fwrite(obj.mySerial, iSet{1});
                fscanf(obj.mySerial)
            end
        end
    end
    
end

