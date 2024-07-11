sudo apt-get install build-essential cmake libfftw3-dev libmbedtls-dev libboost-program-options-dev libconfig++-dev libsctp-dev libtool autoconf
sudo apt-get install libzmq3-dev
sudo add-apt-repository ppa:ettusresearch/uhd
sudo apt-get update
sudo apt-get install libuhd-dev libuhd4.5.0 uhd-host
sudo apt install libtool autoconf
git clone https://gitlab.eurecom.fr/oai/asn1c.git
cd asn1c
git checkout velichkov_s1ap_plus_option_group
autoreconf -iv
./configure
make -j`nproc`
sudo make install
sudo ldconfig
cd ..
cd srsRAN-e2/srsenb/src
mkdir handover_server
cd handover_server

wget -O CMakeLists.txt https://raw.githubusercontent.com/natanzi/srsran_test/main/srsRAN-e2/srsenb/src/handover_server/CMakeLists.txt
wget -O handover_server.cpp https://raw.githubusercontent.com/natanzi/srsran_test/main/srsRAN-e2/srsenb/src/handover_server/handover_server.cpp
wget -O handover_server.h https://raw.githubusercontent.com/natanzi/srsran_test/main/srsRAN-e2/srsenb/src/handover_server/handover_server.h

cd ..
wget -O CMakeLists.txt https://raw.githubusercontent.com/natanzi/srsran_test/main/srsRAN-e2/srsenb/src/CMakeLists.txt
wget -O main.cc https://raw.githubusercontent.com/natanzi/srsran_test/main/srsRAN-e2/srsenb/src/main.cc

cd ..
cd ..

mkdir build
export SRS=`realpath .`
cd build
cmake ../ -DCMAKE_BUILD_TYPE=RelWithDebInfo \
              -DRIC_GENERATED_E2AP_BINDING_DIR=${SRS}/e2_bindings/E2AP-v01.01 \
              -DRIC_GENERATED_E2SM_KPM_BINDING_DIR=${SRS}/e2_bindings/E2SM-KPM \
              -DRIC_GENERATED_E2SM_GNB_NRT_BINDING_DIR=${SRS}/e2_bindings/E2SM-GNB-NRT
make -j5
sudo make install
sudo ldconfig
sudo srsran_install_configs.sh service
