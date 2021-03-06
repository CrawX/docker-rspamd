#!/bin/sh
#display environment variables passed with --env
echo "\$REDIS= $REDIS"
echo "\$CLAMAV= $CLAMAV"
echo "\$OLEFY= $OLEFY"
echo "\$RAZORFY= $RAZORFY"
echo "\$DCCIFD= $DCCIFD"
echo "\$CONTROLIP= $CONTROLIP"
echo "\$DNSSEC= $DNSSEC"
echo "\$NOGREY= $NOGREY"
echo "\$BZSLEEP= $BZSLEEP"
echo "\$SYSREDIR= $SYSREDIR"
echo

wait_port() {
  TL=0
  [ -n "$4" ] && INC="$4" || INC="3"
  echo "Waiting for $1"
  while :
  do
    nc -zv "$2" "$3" && return
    echo "."
    TL=$((TL + INC))
    [ "$TL" -gt 90 ] && return 1
    sleep "$INC"
  done
}

NME=rspamd
set-timezone.sh "$NME"

chown rspamd:rspamd /var/lib/rspamd
cd /etc/rspamd/local.d || exit 1

if [ -n "$SYSREDIR" ]
then
  if [ ! -f maps.d/redirectors.inc ]
  then
    echo "Copying Rspamd redirectors.inc into local.d/maps.d"
    cp ../maps.d/redirectors.inc maps.d/
  else
    echo "local.d/maps.d/redirectors.inc exists, skipping"
  fi
fi

echo "Checking for new map files"
cd maps.orig || exit 1
MAPS=$(find ./ -name '*.map')
cd .. || exit 1

for m in ${MAPS};
do
  echo "Checking $m"
  if [ ! -f maps.d/"$m" ]
  then
    echo "Copying $m into maps.d"
    cp -a maps.orig/"$m" maps.d/"$m"
  else
    echo "Skipping $m, already in maps.d"
  fi
done

chown -R rspamd:rspamd maps.d

conf_files="antivirus external_services rbl rbl_group sh_rbl_group_hbl sh_rbl_hbl"
for n in ${conf_files}
do
  rm -f "$n".conf
done
rm -f rspamd.local.lua

if [ -n "$REDIS" ]
then
  sed -r "s+(.*_servers.*=).*+\1 \"$REDIS\";+" -i redis.conf
  wait_port "redis" "$REDIS" 6379
# let redis load database into memory
  sleep 60s
fi

# start update abuse.ch malware bazaar hashes
[ -n "$BZSLEEP" ] && su rspamd -s /bin/sh -c "update_bazaar.sh" &

if [ -n "$CLAMAV" ]
then
echo "
clamav {
  log_clean = true;
  symbol = CLAM_VIRUS;
  type = clamav;
  servers = \"$CLAMAV:3310\";
  patterns {
    JUST_EICAR = '^Eicar-Test-Signature$';
  }
}
" > antivirus.conf
fi

if [ -n "$DCCIFD" ]
then
  echo "
dcc {
  servers = \"$DCCIFD:10045\";
}
" >> external_services.conf
  wait_port "dccifd" "$DCCIFD" 10045
fi

if [ -n "$OLEFY" ]
then
  echo "
oletools {
  type = \"oletools\";
  servers = \"$OLEFY:10050\";
}
" >> external_services.conf
  wait_port "olefy" "$OLEFY" 10050
fi

if [ -n "$RAZORFY" ]
then
  echo "
razor {
  servers = \"$RAZORFY:11342\";
}
" >> external_services.conf
  wait_port "razorfy" "$RAZORFY" 11342
fi

echo "bind_socket = \"*:11334\";" > worker-controller.inc
[ -n "$CONTROLIP" ] && echo "secure_ip = \"$CONTROLIP\";" >> worker-controller.inc

[ -n "$DNSSEC" ] && SUB=true || SUB=false
sed -r "s+(.*enable_dnssec).*+\1 = $SUB;+g" -i options.inc

[ -n "$NOGREY" ] && SUB="false" || SUB="true"
echo "enabled = $SUB;" > greylist.conf

if [ -f /etc/rspamd/rspamd-dqs/dqs-key ]
then
  echo "Setting up spamhaus DQS"
  cd /etc/rspamd/local.d || exit 1
  HBL=$(drill TV7QRQPGBKF4X3K4T5QYILRI3SP5CIWVIIOH25YUOGVOJ3SBTYNA._cw."$(cat /etc/rspamd/rspamd-dqs/dqs-key)".hbl.dq.spamhaus.net | grep  -c "127.0.3.20")
  if [ "$HBL" -eq 0 ]
  then
    echo "Your key is not HBL enabled"
    cp ../rspamd-dqs/rbl.conf ../rspamd-dqs/rbl_group.conf ./
  else
    echo "Your key is HBL enabled"
    cp ../rspamd-dqs/*.conf ../rspamd-dqs/rspamd.local.lua ./
    sed -i -e "s+your_DQS_key+$(cat /etc/rspamd/rspamd-dqs/dqs-key)+g" rspamd.local.lua
  fi
  sed -i -e "s+your_DQS_key+$(cat /etc/rspamd/rspamd-dqs/dqs-key)+g" ./*.conf
fi

[ -f /usr/sbin/rspamd ] && s="s"

/usr/"$s"bin/rspamd -f -u rspamd -g rspamd
