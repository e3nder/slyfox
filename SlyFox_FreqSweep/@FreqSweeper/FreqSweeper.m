classdef FreqSweeper
    %FREQSWEEPER Sweeps Frequency of FreqSynth and Plots Results
    %   Creates a nice user interface to watch a frequency sweep take place
    %   and edit its characteristics.
    
    properties
        myPanel = uiextras.Panel();
        myTopFigure = [];
        myFreqSynth = [];
        myGageConfigFrontend = [];
    end
    
    methods
        function obj = FreqSweeper(top,f,freqSynth, gageConfigFE)
            obj.myTopFigure = top;
            obj.myPanel.Parent = f;
            obj.myFreqSynth = freqSynth;
            obj.myGageConfigFrontend = gageConfigFE;
            
            hsplit = uiextras.HBox(...
                'Parent', obj.myPanel, ...
                'Tag', 'hsplit', ...
                'Spacing', 5, ...
                'Padding', 5);
                
                uiVB = uiextras.VBox(...
                    'Parent', hsplit, ...
                    'Tag', 'uiVB', ...
                    'Spacing', 5, ...
                    'Padding', 5);
                
                    uiextras.Empty('Parent', uiVB);
                    startStopVB = uiextras.VBox(...
                        'Parent', uiVB);
                        uiextras.Empty('Parent', startStopVB);
                        startStopHB = uiextras.HBox(...
                            'Parent', startStopVB, ...
                            'Spacing', 5, ...
                            'Padding', 5);
                            uicontrol(...
                                'Parent', startStopHB,...
                                'Style', 'pushbutton', ...
                                'Tag', 'startButton',...
                                'String', 'Start',...
                                'Callback', @obj.startButton_Callback);
                            uiextras.Empty('Parent', startStopHB);
                            uicontrol(...
                                'Parent', startStopHB,...
                                'Style', 'pushbutton', ...
                                'Tag', 'stopButton',...
                                'String', 'Stop',...
                                'Callback', @obj.stopButton_Callback);
                            set(startStopHB, 'Sizes', [-2 -1 -2]);
                        uiextras.Empty('Parent', startStopVB);
                        set(startStopVB, 'Sizes', [-1 -2 -1]);
                    freqParamHB = uiextras.HBox(...
                        'Parent', uiVB, ...
                        'Spacing', 5, ...
                        'Padding', 5);
                        startFreqVB = uiextras.VBox(...
                            'Parent', freqParamHB, ...
                            'Spacing', 5, ...
                            'Padding', 5);
                            uiextras.Empty('Parent', startFreqVB);
                            uicontrol(...
                                'Parent', startFreqVB, ...
                                'Style', 'text', ...
                                'String', 'Start Frequency', ...
                                'FontWeight', 'bold', ...
                                'FontUnits', 'normalized', ...
                                'FontSize', 0.6);
                            uicontrol(...
                                'Parent', startFreqVB, ...
                                'Style', 'edit', ...
                                'Tag', 'startFrequency', ...
                                'String', '24000000', ...
                                'FontWeight', 'normal', ...
                                'FontUnits', 'normalized', ...
                                'FontSize', 0.6); 
                            uiextras.Empty('Parent', startFreqVB);
                                
                        centerFreqVB = uiextras.VBox(...
                            'Parent', freqParamHB, ...
                            'Spacing', 5, ...
                            'Padding', 5);
                            uicontrol(...
                                'Parent', centerFreqVB, ...
                                'Style', 'text', ...
                                'String', 'Current Frequency', ...
                                'FontWeight', 'bold', ...
                                'FontUnits', 'normalized', ...
                                'FontSize', 0.7);
                            uicontrol(...
                                'Parent', centerFreqVB, ...
                                'Style', 'text', ...
                                'Tag', 'curFreq', ...
                                'String', 'curFreq', ...
                                'FontWeight', 'bold', ...
                                'FontUnits', 'normalized', ...
                                'FontSize', 0.7);
                            uiextras.Empty('Parent', centerFreqVB);
                            uicontrol(...
                                'Parent', centerFreqVB, ...
                                'Style', 'text', ...
                                'String', 'Step Size', ...
                                'FontWeight', 'bold', ...
                                'FontUnits', 'normalized', ...
                                'FontSize', 0.7);
                            uicontrol(...
                                'Parent', centerFreqVB, ...
                                'Style', 'edit', ...
                                'Tag', 'stepFrequency', ...
                                'String', '1', ...
                                'FontWeight', 'normal', ...
                                'FontUnits', 'normalized', ...
                                'FontSize', 0.7); 
                        stopFreqVB = uiextras.VBox(...
                            'Parent', freqParamHB, ...
                            'Spacing', 5, ...
                            'Padding', 5);
                            uiextras.Empty('Parent', stopFreqVB);
                            uicontrol(...
                                'Parent', stopFreqVB, ...
                                'Style', 'text', ...
                                'String', 'Stop Frequency', ...
                                'FontWeight', 'bold', ...
                                'FontUnits', 'normalized', ...
                                'FontSize', 0.6);
                            uicontrol(...
                                'Parent', stopFreqVB, ...
                                'Style', 'edit', ...
                                'Tag', 'stopFrequency', ...
                                'String', '24000010', ...
                                'FontWeight', 'normal', ...
                                'FontUnits', 'normalized', ...
                                'FontSize', 0.6); 
                            uiextras.Empty('Parent', stopFreqVB);
                    jProgBarPanel = uipanel(...
                        'Parent', uiVB, ...
                        'Tag', 'jProgBarPanel', ...
                        'BorderType', 'none', ...
                        'ResizeFcn', @obj.resizeJProgressBarHolder);
                        try
                            jProgBar = javaObjectEDT('javax.swing.JProgressBar');
                            jProgBar.setOrientation(jProgBar.HORIZONTAL);
                        catch
                           error('Cannot create Java-based scroll-bar!');
                        end
                    % Display the object onscreen
                        try
                          [jProgBar, hProgBar] = javacomponent(jProgBar);
                          set(hProgBar,'Parent', jProgBarPanel);
                          setappdata(obj.myTopFigure, 'jProgBar', jProgBar);
                          setappdata(obj.myTopFigure, 'hProgBar', hProgBar);
                        catch
                           error('Cannot display Java-base scroll-bar!');
                        end
                    savePathVB = uiextras.VBox(...
                        'Parent', uiVB, ...
                        'Spacing', 5, ...
                        'Padding', 1);  
                        uicontrol( ...
                            'Parent', savePathVB, ...
                            'Style', 'checkbox', ...
                            'String', 'Save as you go?', ...
                            'Tag', 'saveScan', ...
                            'Value', 1);
                        pathHB = uiextras.HBox(...
                            'Parent', savePathVB, ...
                            'Spacing', 5, ...
                            'Padding', 5);
                            uicontrol(...
                                'Parent', pathHB, ...
                                'Style', 'pushbutton', ...
                                'Tag', 'getSaveDir', ...
                                'String', 'SaveDir', ...
                                'Callback', @obj.getSaveDir_Callback);
                            uicontrol(...
                                'Parent', pathHB, ...
                                'Style', 'edit', ...
                                'String', 'Z:\Sr3\data', ...
                                'Tag', 'saveDir');
                            set(pathHB, 'Sizes', [60 -1]);
                        set(savePathVB, 'Sizes', [-2 -1]);
                    
                    uiextras.Empty('Parent', uiVB);
                    set(uiVB, 'Sizes', [-1 -1 -1 -1 -1 -4]);

                scanPlotsVB = uiextras.VBox(...
                    'Parent', hsplit, ...
                    'Tag', 'scanPlotsVB', ...
                    'Spacing', 5, ...
                    'Padding', 5);
                    sNormAxes = axes(...
                        'Parent', scanPlotsVB,...
                        'Tag', 'sNormAxes', ...
                        'NextPlot', 'replaceChildren');
                        title(sNormAxes, 'Normalized Counts');
                    sEAxes = axes(...
                        'Parent', scanPlotsVB,...
                        'Tag', 'sEAxes', ...
                        'NextPlot', 'replaceChildren');
                        title(sEAxes, 'Excited State Counts');
                    sGAxes = axes(...
                        'Parent', scanPlotsVB,...
                        'Tag', 'sGAxes', ...
                        'NextPlot', 'replaceChildren');
                        title(sGAxes, 'Ground State Counts');
                    sBGAxes = axes(...
                        'Parent', scanPlotsVB,...
                        'Tag', 'sBGAxes', ...
                        'NextPlot', 'replaceChildren');
                        title(sBGAxes, 'Background Counts');
                    sBGSAxes = axes(...
                        'Parent', scanPlotsVB,...
                        'Tag', 'sBGSAxes', ...
                        'NextPlot', 'replaceChildren');
                        title(sBGSAxes, '461 witness GndState');
                    sBEAxes = axes(...
                        'Parent', scanPlotsVB,...
                        'Tag', 'sBEAxes', ...
                        'NextPlot', 'replaceChildren');
                        title(sBEAxes, '461 witness ExcState');
                
                rawPlotsVB = uiextras.VBox(...
                    'Parent', hsplit, ...
                    'Tag', 'scanPlotsVB', ...
                    'Spacing', 5, ...
                    'Padding', 5);
                    
                    rGSAxes = axes(...
                        'Parent', rawPlotsVB,...
                        'Tag', 'rGSAxes', ...
                        'NextPlot', 'replaceChildren');
                        title(rGSAxes, 'Ground State Flourescence');
                    rEAxes = axes(...
                        'Parent', rawPlotsVB,...
                        'Tag', 'rEAxes', ...
                        'NextPlot', 'replaceChildren');
                        title(rEAxes, 'Excited State Flourescence');
                    rBGAxes = axes(...
                        'Parent', rawPlotsVB,...
                        'Tag', 'rBGAxes', ...
                        'NextPlot', 'replaceChildren');
                        title(rBGAxes, 'Background Flourescence');
                    rBGSAxes = axes(...
                        'Parent', rawPlotsVB,...
                        'Tag', 'rBGSAxes', ...
                        'NextPlot', 'replaceChildren');
                        title(rBGSAxes, '461 GndState Witness');
                    rBEAxes = axes(...
                        'Parent', rawPlotsVB,...
                        'Tag', 'rBEAxes', ...
                        'NextPlot', 'replaceChildren');
                        title(rBEAxes, '461 ExcState Witness');
                    rBBGAxes = axes(...
                        'Parent', rawPlotsVB,...
                        'Tag', 'rBBGAxes', ...
                        'NextPlot', 'replaceChildren');
                        title(rBBGAxes, '461 Background Witness');
                set(hsplit, 'Sizes', [-1 -3 -1]);
                myHandles = guihandles(obj.myTopFigure);
                guidata(obj.myTopFigure, myHandles);
                obj.loadState();
        end
        function startButton_Callback(obj, src, eventData)
            myHandles = guidata(obj.myTopFigure);
            
            %1. Create Frequency List
            startFrequency = str2double(get(myHandles.startFrequency, 'String'));
            stepFrequency = str2double(get(myHandles.stepFrequency, 'String'));
            stopFrequency = str2double(get(myHandles.stopFrequency, 'String'));
            freqList = startFrequency:stepFrequency:stopFrequency;
            curFrequency = freqList(1);
            %1a. Initialize Progress Bar
            jProgBar = getappdata(obj.myTopFigure, 'jProgBar');
            jProgBar.setMaximum(length(freqList));
            %2. Check Save/'Run' and Create Saved File Header
            if getappdata(obj.myTopFigure, 'run') & get(myHandles.saveScan, 'Value')
                [path, fileName] = obj.createFileName();
                try
                    mkdir(path);
                    fid = fopen([path filesep fileName], 'a');
                    fwrite(fid, datestr(now, 'mm/dd/yyyy\tHH:MM AM'))
                    fprintf(fid, '\r\n');
                    colNames = {'Frequency', 'Norm', 'GndState', ...
                        'ExcState', 'Background', 'TStamp', 'BLUEGndState', ...
                        'BLUEBackground', 'BLUEExcState'};
                    n = length(colNames);
                    for i=1:n
                        fprintf(fid, '%s\t', colNames{i});
                    end
                        fprintf(fid, '\r\n');
                catch
                    disp('Could not open file to write to.');
                end
            end
            %Create stuff for raw Plotting Later on
            aInfo = obj.myGageConfigFrontend.myGageConfig.acqInfo;
            sampleRate = aInfo.SampleRate;
            depth = aInfo.Depth;
            taxis = 1:depth;
            taxis = 1/sampleRate*taxis;
            %Create stuff for scan plotting.
            temp = zeros(6,length(freqList));
            setappdata(obj.myTopFigure, 'scanData', temp);
            setappdata(obj.myTopFigure, 'normData', zeros(1, length(freqList)));
            %2.5 Initialize Frequency Synthesizer
            obj.myFreqSynth.initialize();
            %Start Frequency Loop / Check 'Run'
            for i=1:length(freqList)
                if ~getappdata(obj.myTopFigure, 'run')
                    break;
                end
                %3. Set Frequency (Display + Synthesizer)
                curFrequency = freqList(i);
                ret = obj.myFreqSynth.setFrequency(num2str(curFrequency));
                if ~ret
                    setappdata(obj.myTopFigure, 'run', 0);
                    break;
                end
                set(myHandles.curFreq, 'String', num2str(curFrequency));
                %4. Update Progress Bar
                jProgBar.setValue(i);
                drawnow;
                %5. Call Gage Card to gather data
                [data,time,ret] = GageCard.GageMRecord(obj.myGageConfigFrontend.myGageConfig);
                if ~ret
                    setappdata(obj.myTopFigure, 'run', 0);
                    break;
                end

                %6. Call AnalyzeRawData
                scanDataCH1 = obj.analyzeRawData(data(1,:,:));
                scanDataCH2 = obj.analyzeRawDataBLUE(data(2,:,:));
                %7. Clear the Raw Plots, Plot the Raw Plots
                plot(myHandles.rGSAxes, taxis, reshape(data(1,1,:), [1 depth]));
                plot(myHandles.rEAxes, taxis, reshape(data(1,2,:), [1 depth]));
                plot(myHandles.rBGAxes, taxis, reshape(data(1,3,:), [1 depth]));
                plot(myHandles.rBGSAxes, taxis, reshape(data(2,1,:), [1 depth]));
                plot(myHandles.rBEAxes, taxis, reshape(data(2,2,:), [1 depth]));
                plot(myHandles.rBBGAxes, taxis, reshape(data(2,3,:), [1 depth]));
                %8. Update Scan Plots
                x = freqList(1:i) - freqList(1);
                tempScanData = getappdata(obj.myTopFigure, 'scanData');
                tempNormData = getappdata(obj.myTopFigure, 'normData');
                tempScanData(1:3,i) = double(scanDataCH1);
                tempScanData(4:6,i) = double(scanDataCH2);
                %NORMALIZED counts are (E - bg)/(E + G - 2bg)
                tempNormData(i) = (tempScanData(2,i) - tempScanData(3,i)) / (tempScanData(2,i) + tempScanData(1,i) - 2*tempScanData(3,i));
                setappdata(obj.myTopFigure, 'normData', tempNormData);
                setappdata(obj.myTopFigure, 'scanData', tempScanData);
                plot(myHandles.sNormAxes, x, tempNormData(1:i));
                plot(myHandles.sEAxes, x, tempScanData(2,1:i));
                plot(myHandles.sGAxes, x, tempScanData(1,1:i));
                plot(myHandles.sBGAxes, x, tempScanData(3,1:i));
                plot(myHandles.sBGSAxes, x, tempScanData(4,1:i));
                plot(myHandles.sBEAxes, x, tempScanData(5,1:i));
                %9. Check Save and Write Data to file.
                if get(myHandles.saveScan, 'Value')
% 'Frequency', 'Norm', 'GndState', 'ExcState', 'Background', 'TStamp', 'BLUEGndState', 'BLUEBackground', 'BLUEExcState'
                    temp = [curFrequency tempNormData(i) tempScanData(1,i) tempScanData(2,i) tempScanData(3,i) str2double(time) tempScanData(4,i) tempScanData(6,i) tempScanData(5,i)];
                    fprintf(fid, '%8.6f\t', temp);
                    fprintf(fid, '\r\n');
                end
            end
            %9.5 Close Frequency Synthesizer and Data file
            obj.myFreqSynth.close();
            fclose('all'); % weird matlab thing, can't just close fid, won't work.
            %10. If ~Run, make obvious and reset 'run'
            if ~getappdata(obj.myTopFigure, 'run')
                disp('Acquisistion Stopped');
                set(myHandles.curFreq, 'String', 'STOPPED');
                setappdata(obj.myTopFigure, 'run', 1);
                drawnow;
            end
            guidata(obj.myTopFigure, myHandles);
        end
        function resizeJProgressBarHolder(obj, src, eventData)
            myHandles = guidata(obj.myTopFigure);
            old_units = get(src,'Units');
            set(src,'Units','pixels');
            figpos = get(src,'Position');
            hProgBar = getappdata(obj.myTopFigure, 'hProgBar');
            set(hProgBar, 'Position', [floor(0.1*figpos(3)) floor(0.32*figpos(4)) floor(0.8*figpos(3)) floor(0.36*figpos(4))]);
            set(src,'Units',old_units);
        end
        function stopButton_Callback(obj, src, eventData)
            setappdata(obj.myTopFigure, 'run', 0);
        end
        function getSaveDir_Callback(obj, src, eventData)      
            myHandles = guidata(obj.myTopFigure);
            dirPath = uigetdir(['Z:\Sr3\data']);
            set(myHandles.saveDir, 'String', dirPath);
            guidata(obj.myTopFigure, myHandles);
        end
        function [path, fileName] = createFileName(obj)
            myHandles = guidata(obj.myTopFigure);
            basePath = get(myHandles.saveDir, 'String');
            folderPath = [datestr(now, 'yymmdd') filesep 'Sweeps'];
            curTime = datestr(now, 'HHMMSS');
            fileName = ['Sweep_' curTime '.txt'];
            path = [basePath filesep folderPath];
        end
        function scanData = analyzeRawData(obj, data)
            scanData = sum(data,3);
        end
        function scanData = analyzeRawDataBLUE(obj, data)
            scanData = mean(data,3);
        end
        function saveState(obj)
            myHandles = guidata(obj.myTopFigure);
            FreqSweeperState.startFrequency = get(myHandles.startFrequency, 'String');
            FreqSweeperState.stepFrequency = get(myHandles.stepFrequency, 'String');
            FreqSweeperState.stopFrequency = get(myHandles.stopFrequency, 'String');
            FreqSweeperState.saveScan = get(myHandles.saveScan, 'Value');
            FreqSweeperState.saveDir = get(myHandles.saveDir, 'String');
            save FreqSweeperState;
        end
        function loadState(obj)
            try
                load FreqSweeperState
                myHandles = guidata(obj.myTopFigure);
                set(myHandles.startFrequency, 'String', FreqSweeperState.startFrequency);
                set(myHandles.stepFrequency, 'String', FreqSweeperState.stepFrequency);
                set(myHandles.stopFrequency, 'String', FreqSweeperState.stopFrequency);
                set(myHandles.startScan, 'Value', FreqSweeperState.saveScan);
                set(myHandles.saveDir, 'String', FreqSweeperState.saveDir);
                guidate(obj.myTopFigure, myHandles);
            catch
                disp('No saved state for FreqSweeper Exists');
            end
        end
    end
    
end
