################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/pgm/pgmwrite.c \
../src/pgm/ppmwrite.c \
../src/pgm/wimaspgm0.c \
../src/pgm/wimaspgmsc.c \
../src/pgm/wimasppm.c \
../src/pgm/wimasppm0.c \
../src/pgm/wimasppmsc.c 

OBJS += \
./src/pgm/pgmwrite.o \
./src/pgm/ppmwrite.o \
./src/pgm/wimaspgm0.o \
./src/pgm/wimaspgmsc.o \
./src/pgm/wimasppm.o \
./src/pgm/wimasppm0.o \
./src/pgm/wimasppmsc.o 

C_DEPS += \
./src/pgm/pgmwrite.d \
./src/pgm/ppmwrite.d \
./src/pgm/wimaspgm0.d \
./src/pgm/wimaspgmsc.d \
./src/pgm/wimasppm.d \
./src/pgm/wimasppm0.d \
./src/pgm/wimasppmsc.d 


# Each subdirectory must supply rules for building sources it contributes
src/pgm/%.o: ../src/pgm/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: NVCC Compiler'
	/usr/local/cuda-8.0/bin/nvcc -I/home/matt/git/cfitsio -G -g -lineinfo -pg -O0 -gencode arch=compute_35,code=sm_35 -m64 -odir "src/pgm" -M -o "$(@:%.o=%.d)" "$<"
	/usr/local/cuda-8.0/bin/nvcc -I/home/matt/git/cfitsio -G -g -lineinfo -pg -O0 --compile -m64  -x c -o  "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


