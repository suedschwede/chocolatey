$packageName  = 'rancher'
$tools = Split-Path $MyInvocation.MyCommand.Definition
$toolsDir     = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"


## SMB Share for Virtualbox ova file
$smbshare = "\\share.example.com\public\virtualbox\rancher.ova"

$workspacedir="c:\virtualbox"
$sizec = get-psdrive c
$freec = [long]$sizec.free
if (Test-Path d:\) {
    $workspacedir="d:\"
	$sized = get-psdrive d
    $freed = [long]$sized.free
	if ($freed -gt $freec) {
	   $workspacedir="d:\virtualbox"	
	}
}

VBoxManage setproperty machinefolder $workspacedir


## Create a host only network ( if it doesn't exist )
$test1 = VBoxManage list hostonlyifs | findstr  "Name:"
if (!$test1) {
  VBoxManage hostonlyif create
}

$test2 = VBoxManage list hostonlyifs | findstr  "192.168.56.1"

if (!$test2) {
  $netname = "VirtualBox Host-Only Ethernet Adapter"
  $test3 = VBoxManage list hostonlyifs | findstr  "VirtualBox Host-Only Ethernet Adapter #2" 
  if ($test3) { $netname="VirtualBox Host-Only Ethernet Adapter #2" }
  
  echo $netname
  vboxmanage hostonlyif ipconfig $netname --ip 192.168.56.1 --netmask 255.255.255.0
  
}


$test4 = VBoxManage list vms | findstr  "rancher"
if (!$test4) {
  VBoxManage import $smbshare --vsys 0 --vmname rancher  --unit 5 --ignore --unit 6 --ignore
  $vboxdir=$workspacedir + "\rancher\rancher.vbox"
  VBoxManage registervm $vboxdir

  $mem=VBoxManage list hostinfo | findstr "size:"
  $mem=$mem.replace("Memory size: ","")
  $mem=$mem.replace(" MByte","")
  $memory = [long]$mem

  ## Set memory for virtulabox image
  VBoxManage modifyvm "rancher" --usb off --usbehci off
  if ($memory -gt 12000) {
    VBoxManage modifyvm "rancher" --memory 8000
  }
}