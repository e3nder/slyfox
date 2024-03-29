classdef PID < handle
    %PID PID controller
    %   This is a simple PID that holds that values of its gains, and the
    %   last summed error, and has functions for computing correction
    %   factors.
    %   Written by Ben Bloom. Last Updated 04/25/2012 15:50:00
    
    properties
        myPolarity = 1; %Polarity of error
        myKp = 0;       %Proportional Gain
        myTi = 10^10;       %Integral Gain
        myTd = 0;       %Derivative Gain
        myORange = 100;  %Clamped Output Range
        myIntE = 0;  %Record of ALL Previous Errors
        myE0 = 0;    %Previous output error
        myT0 = 0;   %Previous Evaluation Time
        myTimeDiff = 0; %Needed to do FFT of error
    end
    
    methods
        % Instantiates the object
        function obj = PID(pol, Kp, Ti, Td, oRange)
            obj.myPolarity = pol;
            obj.myKp = Kp;
            obj.myTi = Ti;
            obj.myTd = Td;
            obj.myORange = oRange;
            obj.myT0;
        end
        
        %Calculates correction factor for Error for this Iteration and Updates Records
        %Nice Pseudocode from Wikipedia
        function u = calculate(obj, e1, t1)
            if t1 < 0
                timeDiff = abs(t1)*1000;
            else
                timeDiff = (t1 - obj.myT0);
            end
            obj.myTimeDiff = timeDiff;
            
            if obj.myT0 ~= 0
                %Calculate Integral
                obj.myIntE = obj.myIntE + (e1+obj.myE0)*timeDiff/2;
                %Calculate Derivative
                derivative = (e1 - obj.myE0)/timeDiff;
            else
                derivative = 0;
            end
            
            %Calculate Output
            if (obj.myTi ~= 0)
                u = obj.myKp*(e1 + ((obj.myTi*1000)^-1)*obj.myIntE + (obj.myTd*1000)*derivative);
            else
                u = (e1);
            end
            
            %Clamp the outputs
            if abs(u) > obj.myORange
                if u <0
                    u = -1*obj.myORange;
                else
                    u = obj.myORange;
                end
            end
            
            %Update last Error and last Time.
            obj.myE0 = e1;
            obj.myT0 = t1;
        end
        function clear(obj)
            obj.myIntE = 0;
            obj.myE0 = 0;
            obj.myT0 = 0;
        end
        function reset(obj)
            obj.myKp = 0;
            obj.myTi = 10^10;
            obj.myTd = 0;
            obj.myIntE = 0;
            obj.myE0 = 0;
            obj.myT0 = 0;
        end
    end
    
end

