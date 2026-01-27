sudo yum install vim -y
sudo yum install screen -y
vim ~/.screenrc
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user
exit
