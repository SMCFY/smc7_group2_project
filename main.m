delay = Delay();
disp('Begin Signal Input...')
audioTestBench(delay);
tic
while toc<50
   
    mySignal = deviceReader();
    myProcessedSignal = delay.process(mySignal);
    deviceWriter(myProcessedSignal);
    
end

release(deviceReader)
release(deviceWriter)