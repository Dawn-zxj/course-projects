
iverilog -o testbench.vvp Simulation_Source/Wrapper_tb.v Design_Source/Wrapper.v Design_Source/ARM.v Design_Source/ALU.v Design_Source/CondLogic.v Design_Source/RegisterFile.v Design_Source/ProgramCounter.v Design_Source/Extend.v Design_Source/Shifter.v Design_Source/ControlUnit.v Design_Source/Decoder.v

if %errorlevel% neq 0 (
    rem echo "************** has bug! ***************"
    pause
    exit /b
)

vvp testbench.vvp 

