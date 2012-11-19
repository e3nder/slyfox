classdef PID_gui < hgsetget
    %PID_GUI Frontend for tuning up a software controlled PID
    %   Frontend for a software controlled PID which includes inputs for
    %   gains, plotted error as a function of time, and FFT of the error as
    %   a function of time, log file save location, etc.
    
    properties
        myTopFigure = [];
        myTitlePanel = [];
        myPanel = [];
        myPID;
        myPID2;
        myName;
        myPlotHandle = [];
        myFFTPlotHandle = [];
        myKp = [];
        myKi = [];
        myKd = [];
        myDeltaT = [];
        mySetPoint = [];
        
        myKp2 = [];
        myKi2 = [];
        myKd2 = [];
        myDeltaT2 = [];
        mySetPoint2 = [];
        myEnableBox = [];
    end
    
    methods
        function obj = PID_gui(topFig, parentObj, myName)
            obj.myTopFigure = topFig;
            obj.myName = myName;
            obj.myPID = PID.PID(1,0,0,0,10);
            obj.myPID2 = PID.PID(1,0,0,0,10);
            obj.myTitlePanel = uiextras.Panel('Parent', parentObj, ...
                'Title', ['PID ' num2str(myName)]);
            obj.myPanel = uiextras.HBox('Parent', obj.myTitlePanel, ...
                'Spacing', 5, ...
                'Padding', 5);
            mainControlsVB = uiextras.VBox('Parent', obj.myPanel, ...
                'Spacing', 5, ...
                'Padding', 5);
                gainsPanel = uiextras.Panel('Parent', mainControlsVB, ...
                    'Title', 'Gains');
                gainsHB = uiextras.HBox('Parent', gainsPanel);
                gainLabels = uiextras.VButtonBox('Parent', gainsHB, ...
                'Spacing', 2, ...
                'Padding', 2);
                    uiextras.Empty('Parent', gainLabels);
                    uicontrol('Parent', gainLabels, ...
                        'Style', 'text', ...
                        'FontSize', 6, ...
                        'String', 'Kp');
                    uicontrol('Parent', gainLabels, ...
                        'Style', 'text', ...
                        'FontSize', 6, ...
                        'String', 'Ki');
                    uicontrol('Parent', gainLabels, ...
                        'Style', 'text', ...
                        'FontSize', 6, ...
                        'String', 'Kd');
                    uicontrol('Parent', gainLabels, ...
                        'Style', 'text', ...
                        'FontSize', 6, ...
                        'String', 'Set Point');
                    uicontrol('Parent', gainLabels, ...
                        'Style', 'text', ...
                        'FontSize', 6, ...
                        'String', 'Delta t');
                gainsEdits = uiextras.VButtonBox('Parent', gainsHB, ...
                'Spacing', 2, ...
                'Padding', 2);
                    uicontrol('Parent', gainsEdits, ...
                        'Style', 'text', ...
                        'FontSize', 6, ...
                        'String', 'PID1');
                    obj.myKp = uicontrol('Parent', gainsEdits, ...
                        'Style', 'edit', ...
                        'Tag', 'kP', ...
                        'String', '1.625');
                    obj.myKi = uicontrol('Parent', gainsEdits, ...
                        'Style', 'edit', ...
                        'Tag', 'kI', ...
                        'String', '11.3e-5');
                    obj.myKd = uicontrol('Parent', gainsEdits, ...
                        'Style', 'edit', ...
                        'Tag', 'kD', ...
                        'String', '0');
                    obj.mySetPoint = uicontrol('Parent', gainsEdits, ...
                        'Style', 'edit', ...
                        'Tag', 'setPoint', ...
                        'String', '0');
                    obj.myDeltaT = uicontrol('Parent', gainsEdits, ...
                        'Style', 'edit', ...
                        'Tag', 'deltaT', ...
                        'String', '3926.44');
               gainsEdits2 = uiextras.VButtonBox('Parent', gainsHB, ...
                   'Spacing', 2, ...
                   'Padding', 2);
                    uicontrol('Parent', gainsEdits2, ...
                        'Style', 'text', ...
                        'FontSize', 6, ...
                        'String', 'PID2');
                    obj.myKp2 = uicontrol('Parent', gainsEdits2, ...
                        'Style', 'edit', ...
                        'Tag', 'kP2', ...
                        'String', '1');
                    obj.myKi2 = uicontrol('Parent', gainsEdits2, ...
                        'Style', 'edit', ...
                        'Tag', 'kI2', ...
                        'String', '0');
                    obj.myKd2 = uicontrol('Parent', gainsEdits2, ...
                        'Style', 'edit', ...
                        'Tag', 'kD2', ...
                        'String', '0');
                    obj.mySetPoint2 = uicontrol('Parent', gainsEdits2, ...
                        'Style', 'edit', ...
                        'Tag', 'setPoint2', ...
                        'String', '0');
                    obj.myDeltaT2 = uicontrol('Parent', gainsEdits2, ...
                        'Style', 'edit', ...
                        'Tag', 'deltaT2', ...
                        'String', '3926.44');
                        pidButtons = uiextras.HButtonBox('Parent', mainControlsVB);
                        obj.myEnableBox = uicontrol( ...
                            'Parent', pidButtons, ...
                            'Style', 'checkbox', ...
                            'String', 'Enable PID', ...
                            'Tag', 'pidEnabled', ...
                            'Value', 1);
                        uicontrol( ...
                            'Parent', pidButtons, ...
                            'Style', 'pushbutton', ...
                            'String', 'BodePlot', ...
                            'Callback', @obj.createBodePlot_Callback, ...
                            'Tag', 'createBodePlot');
                        tempPAN = obj.myPanel; %Needed for older matlabs
                    errPlot = axes( 'Parent', tempPAN, ...
                        'Tag', ['err_PID' obj.myName ], ...
                        'ActivePositionProperty', 'OuterPosition');
                        title(errPlot, 'Error Signal');
                    errFFT = axes( 'Parent', tempPAN, ...
                        'Tag', ['err_FFT' obj.myName ], ...
                        'ActivePositionProperty', 'OuterPosition');
                        title(errFFT, 'SS Error Amp Spectrum');
        end
        
        function updateMyPlots(obj, newErr, runNum, plotSize)
            myHandles = guidata(obj.myTopFigure);
            tempPIDData = getappdata(obj.myTopFigure, ['PID' obj.myName 'Data']);
            if isempty(obj.myPlotHandle)
                obj.myPlotHandle = plot(myHandles.(['err_PID' obj.myName]), tempPIDData(end-plotSize:end), 'ok', 'LineWidth', 3);
                
                
                Fs = 1/str2double(get(obj.myDeltaT, 'String'));% Sampling frequency
                L = length(tempPIDData);    % Length of signal
                NFFT = 2^nextpow2(L);       % Next power of 2 from length of y
                Y = fft(tempPIDData,NFFT)/L;
                f = Fs/2*linspace(0,1,NFFT/2+1);
                % Plot single-sided amplitude spectrum.
                obj.myFFTPlotHandle = plot(myHandles.(['err_FFT' obj.myName]), f, 2*abs(Y(1:NFFT/2+1)), 'LineWidth', 1);
            elseif runNum > 2
                set(obj.myPlotHandle, 'YData', tempPIDData(end-plotSize:end));
                refreshdata(obj.myPlotHandle);
                
                
                Fs = 1/str2double(get(obj.myDeltaT, 'String'));% Sampling frequency
                L = length(tempPIDData);    % Length of signal
                NFFT = 2^nextpow2(L);       % Next power of 2 from length of y
                Y = fft(tempPIDData,NFFT)/L;
                f = Fs/2*linspace(0,1,NFFT/2+1);
                set(obj.myFFTPlotHandle, 'YData', 2*abs(Y(1:NFFT/2+1)));
                set(obj.myFFTPlotHandle, 'XData', f);
                refreshdata(obj.myFFTPlotHandle);
                drawnow;
            end
            guidata(obj.myTopFigure, myHandles);
        end
        function getSaveDir_Callback(obj, src, eventData)      
            myHandles = guidata(obj.myTopFigure);
            dirPath = uigetdir(['Z:\Sr3\data']);
            set(myHandles.saveDir, 'String', dirPath);
            guidata(obj.myTopFigure, myHandles);
        end
        function createBodePlot_Callback(obj, src, eventData)
            C = pid(str2double(get(obj.myKp, 'String')), str2double(get(obj.myKi, 'String'))*1000,str2double(get(obj.myKd, 'String'))/1000 ,'Ts',str2double(get(obj.myDeltaT, 'String'))/1000,'IFormula','Trapezoidal');
            C2 = pid(str2double(get(obj.myKp2, 'String')),str2double(get(obj.myKi2, 'String'))*1000,str2double(get(obj.myKd2, 'String'))/1000, 'Ts',str2double(get(obj.myDeltaT, 'String'))/1000,'IFormula','Trapezoidal');
            P = bodeoptions;
            P.FreqUnits = 'Hz';
            figure;
            bodeplot(C2*C, P)
        end
    end
    
end

