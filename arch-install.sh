#!/bin/sh

KEYMAP="pt-latin1"
# Example: /dev/sda
DISK=""
# Example: /dev/sda1
EFI_PARTITION=""
FORMAT_EFI_PARTITION=0
# Example: /dev/sda2
ROOT_PARTITION=""
REGION="Europe"
CITY="Lisbon"
LOCALE="en_US.UTF-8 UTF-8"
HOSTNAME=""
USERNAME=""

if [ -z $1 ]
then
	loadkeys $KEYMAP
	
	mkfs.ext4 -F $ROOT_PARTITION
	
	if [ $FORMAT_EFI_PARTITION -eq 1 ]
	then
		mkfs.fat -F 32 $EFI_PARTITION
	fi
	
	mount $ROOT_PARTITION /mnt
	mount --mkdir $EFI_PARTITION /mnt/boot
	
	pacstrap -K /mnt base linux linux-firmware
	
	genfstab -U /mnt >> /mnt/etc/fstab

	cp $0 /mnt/$0
	arch-chroot /mnt /arch-install.sh chroot
elif [ "$1" = "chroot" ]
then
	ln -sf /usr/share/$REGION/$CITY /etc/localtime

	hwclock --systohc

	pacman -S networkmanager man-db man-pages texinfo neovim

	systemctl enable NetworkManager.service

	echo "$(sed /etc/locale.gen -e "s/\#$LOCALE/$LOCALE/")" > /etc/locale.gen

	locale-gen

	echo "KEYMAP="$KEYMAP > /etc/locale.gen

	echo $HOSTNAME > /etc/hostname

	echo -e "127.0.0.1\tlocalhost" > /etc/hosts
	echo "::1" >> /etc/hosts

	passwd

	pacman -S grub efibootmgr

	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

	grub-mkconfig -o /boot/grub/grub.cfg

	useradd -m $USERNAME

	passwd $USERNAME

	usermod -aG wheel $USERNAME

	pacman -S sudo

	cp /etc/sudoers /sudoers.temp

	echo "$(sed /sudoers.temp -e "s/\# \%wheel ALL=(ALL:ALL) ALL/\%wheel ALL=(ALL:ALL) ALL/")" > /sudoers.temp
	visudo -c /sudoers.temp && cp /sudoers.temp /etc/sudoers

	pacman -S xdg-user-dirs

	sudo -u $USERNAME xdg-user-dirs-update
fi
