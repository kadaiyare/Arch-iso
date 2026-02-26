# fix for screen readers
if grep -Fqa 'accessibility=' /proc/cmdline &> /dev/null; then
    setopt SINGLE_LINE_ZLE
fi

# ZTP auto-installer
if [ -f /root/install-dialog.sh ]; then
    LANG=ja_JP.UTF-8 /root/install-dialog.sh
fi
