################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../AddUser.c \
../Backup.c \
../Blob.c \
../Common.c \
../Connection.c \
../DataArea.c \
../Database.c \
../FireRuby.c \
../FireRubyException.c \
../Generator.c \
../RemoveUser.c \
../Restore.c \
../ResultSet.c \
../Row.c \
../ServiceManager.c \
../Services.c \
../Statement.c \
../Transaction.c \
../TypeMap.c 

OBJ_SRCS += \
../AddUser.obj \
../Backup.obj \
../Blob.obj \
../Common.obj \
../Connection.obj 

OBJS += \
./AddUser.o \
./Backup.o \
./Blob.o \
./Common.o \
./Connection.o \
./DataArea.o \
./Database.o \
./FireRuby.o \
./FireRubyException.o \
./Generator.o \
./RemoveUser.o \
./Restore.o \
./ResultSet.o \
./Row.o \
./ServiceManager.o \
./Services.o \
./Statement.o \
./Transaction.o \
./TypeMap.o 

C_DEPS += \
./AddUser.d \
./Backup.d \
./Blob.d \
./Common.d \
./Connection.d \
./DataArea.d \
./Database.d \
./FireRuby.d \
./FireRubyException.d \
./Generator.d \
./RemoveUser.d \
./Restore.d \
./ResultSet.d \
./Row.d \
./ServiceManager.d \
./Services.d \
./Statement.d \
./Transaction.d \
./TypeMap.d 


# Each subdirectory must supply rules for building sources it contributes
%.o: ../%.c
	@echo 'Building file: $<'
	@echo 'Invoking: GCC C Compiler'
	gcc -O0 -g3 -Wall -c -fmessage-length=0 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)" -o"$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


