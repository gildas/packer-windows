w2012R2 = "http://care.dlservice.microsoft.com//dl/download/6/D/A/6DAB58BA-F939-451D-9101-7DE07DC09C03/9200.16384.WIN8_RTM.120725-1247_X64FRE_SERVER_EVAL_EN-US-HRM_SSS_X64FREE_EN-US_DV5.iso"
w2012R2_md5 = "8503997171f731d9bd1cb0b0edc31f3d"
w2008R2 = "http://care.dlservice.microsoft.com//dl/download/7/5/E/75EC4E54-5B02-42D6-8879-D8D3A25FBEF7/7601.17514.101119-1850_x64fre_server_eval_en-us-GRMSXEVAL_EN_DVD.iso",
w2008R2_md5 = "4263be2cf3c59177c45085c0a7bc6ca5"

EVAL_WIN7_X64 = http://care.dlservice.microsoft.com/dl/download/evalx/win7/x64/EN/7600.16385.090713-1255_x64fre_enterprise_en-us_EVAL_Eval_Enterprise-GRMCENXEVAL_EN_DVD.iso
EVAL_WIN7_X64_CHECKSUM ?= 15ddabafa72071a06d5213b486a02d5b55cb7070
EVAL_WIN81_X64 = http://download.microsoft.com/download/B/9/9/B999286E-0A47-406D-8B3D-5B5AD7373A4A/9600.16384.WINBLUE_RTM.130821-1623_X64FRE_ENTERPRISE_EVAL_EN-US-IRM_CENA_X64FREE_EN-US_DV5.ISO
EVAL_WIN81_X64_CHECKSUM = 73321fa912305e5a16096ef62380a91ee1f112da
EVAL_WIN2008R2_X64 = http://download.microsoft.com/download/7/5/E/75EC4E54-5B02-42D6-8879-D8D3A25FBEF7/7601.17514.101119-1850_x64fre_server_eval_en-us-GRMSXEVAL_EN_DVD.iso
EVAL_WIN2008R2_X64_CHECKSUM = beed231a34e90e1dd9a04b3afabec31d62ce3889
EVAL_WIN2012R2_X64 = http://download.microsoft.com/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698DAEB96/9600.16384.WINBLUE_RTM.130821-1623_X64FRE_SERVER_EVAL_EN-US-IRM_SSS_X64FREE_EN-US_DV5.ISO
EVAL_WIN2012R2_X64_CHECKSUM = 7e3f89dbff163e259ca9b0d1f078daafd2fed513


TEMPLATE=$1
PROVISIONER=$2

BOX=$TEMPLATE"_"$PROVISIONER".box"

cd templates/$TEMPLATE

for B in `vagrant box list | grep windows | awk '{print $1}'`; do vagrant box remove --provider=virtualbox $B; done
  for B in `vagrant box list | grep windows | awk '{print $1}'`; do vagrant box remove --provider=vmware_desktop $B; done

    rm -f $BOX
    rm -rf output-$PROVISIONER-iso

    packer build -debug -only=$PROVISIONER-iso packer.json
    vagrant box add --force --name $TEMPLATE $BOX

    cd ../../tests

    gem install bundler --no-ri --no-rdoc
    rm Gemfile.lock
    bundle install --path=vendor

    if [ $PROVISIONER == 'vmware' ]; then
        PROVIDER='vmware_fusion'
    else
        PROVIDER='virtualbox'
        fi

        BOX="$BOX" TEMPLATE="$TEMPLATE" vagrant up --provider=$PROVIDER
        bundle exec rake spec
        BOX="$BOX" TEMPLATE="$TEMPLATE" vagrant destroy -f
    end
  end
end
