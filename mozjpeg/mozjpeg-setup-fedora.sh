
sudo dnf install nasm -y

git clone https://github.com/mozilla/mozjpeg.git 

cd mozjpeg/

cmake -G"Unix Makefiles" .

make

