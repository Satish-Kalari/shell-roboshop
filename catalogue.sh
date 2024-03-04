#!.bin/bash

ID=$(id -u) #getting user ID

R="\e[31m" # these are color codes
G="\e[32m"
Y="\e[33m"
N="\e[0m"

#creating variables 
MONGODB_HOST=mongodb.projoy.store
TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP.log" #$0 is to get script file name

echo "script started excicuting at $TIMESTAMP" &>> $LOGFILE # &=both success and failure >>=appending, >= overwite content 

VALIDATE(){

    if [ $1 -ne 0 ] # $1 takes valuve from $? VALIDATE command from line 37,  
    then
        echo -e "$2 ... $R FAILLED $N" # -e enables $ functions in this case color coding
        exit 1
    else 
        echo -e "$2 ...$G SUCESSFUL $N " # $2 takes 2ng arrgument from VALIDATE command 
    fi
}

if [ $ID -ne 0 ] #checking if user as root acess or permisions to intall the packages 
then
    echo -e "$R Use Root Acess $N" #if does not have permission then asks to get permission
    exit 1 #since cany install exiting the program
else 
    echo -e "$G Proceding with Installation $N" # if had all permmsions it will proceeed to instaltion of packages
fi

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "Disabling current nodejs ver"

dnf module enable nodejs:18 -y &>> $LOGFILE
VALIDATE $? "Enabling nodejs: 18"

dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "Installing nodejs"

id roboshop # this one loosk for if user in this case roboshop already exsit
if [ $? -ne 0 ]
then
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "creating user roboshop"
else
    echo -e "roboshop user already exsit $Y SKIPPING$N"
fi

mkdir -p /app &>> $LOGFILE #-p check if dirctory exit or not, if yes skips creatin, if not create directory
VALIDATE $? "creating App Directory"

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip &>> $LOGFILE
VALIDATE $? "Downloding catalogue.zip"

cd /app &>> $LOGFILE
VALIDATE $? "getting into app directory"

unzip -o /tmp/catalogue.zip &>> $LOGFILE # -o overwrite if unzipped file alteady exsist
VALIDATE $? "unziping catalogue"

npm install &>> $LOGFILE
VALIDATE $? "Installing dependencies"

cp /home/centos/roboshop-shell-practice/catalogue.service /etc/systemd/system/catalogue.service &>> $LOGFILE
VALIDATE $? "Coping catalogue.serice to systemd"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "daemon reload"

systemctl enable catalogue &>> $LOGFILE
VALIDATE $? "Enabling catalogue"

systemctl start catalogue &>> $LOGFILE
VALIDATE $? "Starting catalogue"

cp /home/centos/roboshop-shell-practice/mongo.repo  /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE $? "Coping monogodb repo"

dnf install mongodb-org-shell -y &>> $LOGFILE
VALIDATE $? "instaling mongodb client"

mongo --host $MONGODB_HOST </app/schema/catalogue.js &>> $LOGFILE
VALIDATE $? "monogobd host connection"

netstat -lntp