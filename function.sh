function maySOEFix {
  yum update krb5-libs -y || echo "Failed to update krb5-libs for May SOE"
  echo "Function-END"
}

function resizeDisks {
  echo "[DEBUG MESSAGE]:  Resizing disks, starting with home"
  resize2fs /dev/xvdf || echo "Failed to resize dev/xvdf"
  echo "[DEBUG MESSAGE]:  Resizing disks, next is log"
  resize2fs /dev/xvdh || echo "Failed to resize dev/xvdh"
  echo "Function-END"
}

function createSrmUser {
  echo "[DEBUG MESSAGE]:  Creating the srm group"
  groupadd srm -g 3999 || echo "Failed to create SRM user's group"
  echo "[DEBUG MESSAGE]:  Creating the Srm user"
  useradd -m srm -g srm -u 3999 -d /home/srm -G users -c "srm application user" -s /bin/bash -p $SRM_PASS || echo "Failed to create srm user"
  echo "Function-END"
}

function setTimezoneToAustralia {
  echo "[DEBUG MESSAGE]:  Setting Timezone to local Australian city via softlink"
  ln -sf /usr/share/zoneinfo/Australia/$TZ_PATH /etc/localtime || echo "Failed to symlink $TZ_PATH timezone to /etc/localtime"
  echo '''export TZ=Australia/TZ_PATH''' | sed "s/TZ_PATH/$TZ_PATH/g" >> /home/srm/.bashrc || echo "Failed include TZ variable in inform bashrc"
  echo '''export TZ=Australia/TZ_PATH''' | sed "s/TZ_PATH/$TZ_PATH/g" >> /etc/profile || echo "Failed include TZ variable in general profile"
  echo "Function-END"
}
