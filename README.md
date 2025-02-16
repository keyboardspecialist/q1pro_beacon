# Beacon3d Environment Setup for Q1 Pro
----

Thanks to the guys over on the Qidi community wiki. This guide largely follows their work. https://github.com/qidi-community/Plus4-Wiki

Shroud is a remix of https://www.printables.com/model/1149931-qidi-q1-pro-improved-visibility-duct-remix/collections

These instructions are for the Beacon3d RevH board.

The mount and fan shroud provided are preliminary designs and aren't guaranteed to perform well with regards to both cooling and input shaping/resonance.

The Beacon mount swaps the stock m3x25 screws for m3x16 to mount to the toolhead. Otherwise it uses the included m3x6 screws to mount the board.

* [Pull](#pull-this-repo)
* [Automated Script](#automated-script)
* [Backup](#backup-env)
* [Update](#update-python)
* [Python Patch](#python-patches)
* [Printer Config](#printer-config)
* [Manual Config](#printer-config-manually)

## Pull this repo

```bash
git clone git@github.com:keyboardspecialist/q1pro_beacon.git
```

clone it into your Q1 home directory: `/home/mks`

## Automated Script

The sections below are automated by the `setupenv.sh` script included.

You may need to mark it executable:

```bash
chmod +x setupenv.sh
```

Running the script `./setupenv.sh` with no arguments will output the main menu.

**NOTE: Use the `-m|--mount` option to specify which mount you are configuring for**

**NOTE: If you run `--all` or `--patch` be sure your beacon is plugged into USB, so the patch can find its device ID**


## backup env

First we back up our import configs in case we need to roll back or reference stock settings.

`mkdir -p /home/mks/qidi-klipper-backup`
`(cd /home/mks; tar cvf - klipper klipper_config) | (cd /home/mks/qidi-klipper-backup; tar xf -)`

## update python

Q1 Pro has an old version of python 2.7, we need 3.8+ for Beacon.

Instructions taken from plus4 cartography probe guide. Our only difference is greenlet version. Q1 has 1.1.2 instead of 2.0.2 listed

```bash
sudo service klipper stop

cd ~

wget https://github.com/stew675/ShakeTune_For_Qidi/releases/download/v1.0.0/python-3-12-3.tgz

tar xvzf python-3-12-3.tgz

rm python-3-12-3.tgz
```

```bash
sudo rm -rf klippy-env

~/python-3.12.3/bin/python3.12 -m venv klippy-env

cd ~/klippy-env

sed -i 's/greenlet==1.1.2/greenlet==3.0.3/' ../klipper/scripts/klippy-requirements.txt # Need to upgrade this package for 3.12.

bin/pip install -r ../klipper/scripts/klippy-requirements.txt
```

## Python Patches

The Q1 Pro runs an old version of klipper and lacks source updates for Python3 and Beacon3d compatilibity

The 4 files affected are `configfile.py`, `adxl345.py`, `probe.py`, and `virtual_sdcard.py`

The patches need to be run from the git source directory and take the form

`patch < patch_file.patch`


## Printer Config

I have supplied patch files for `printer.cfg` and `gcode_macro.cfg`. They are run the same way as the python patches. However, if you wish to do this by hand skip ahead.

The only difference is the printer.cfg has an additional step prior to applying. First we need to insert the device string into the config

```bash
sed -i "s|{{beacon_dev}}|$( ls /dev/serial/by-id/usb-Beacon* | head -n1 )|g" "printer_cfg.patch"
```

then patch

```bash
patch < printer_cfg.patch
```

**NOTE: the x_offset and y_offset in [beacon] are for the supplied mount. If you design your own/move the probe, these need to reflect the new position**

`printercfg_side_mount.patch` - for the original side mount design
`printercfg_shroud_mount.patch` - for the new shroud mount

Not included in the printer.cfg patch is removing a possible additional `[smart_effector]` block in the commented out section at the bottom marked as *do not edit*.
I wasn't sure if I could guarantee the patch would always succeed there, so just remove it by hand. Otherwise you will get the "pin not set im smart_effector" error.

## Printer Config Manually

This is essentialy the same as the Plus4 guide with some minor tweaks for our particular model.

https://github.com/qidi-community/Plus4-Wiki/tree/main/content/bed-scanning-probes/Beacon3D/RevH-Normal#printercfg-changes



### Printer.cfg

In the `z_tilt` and `bed_mesh` sections, be sure to copy Q1 Pro values for position, points and min/max bed values.

### gcode_macro.cfg

In `print_start`, comment out `set_zoffset`. Otherwise, its straight forward comment out the old sections and paste in the new ones.
