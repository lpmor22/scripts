# In the Windows 10 Setup
Shift + F10
C:
cd Windows\System32
ren utilman.exe utilman.exe.bak 
ren cmd.exe utilman.exe
wpeutil reboot

# In the Sign-in screen
net user Administrator /active:yes
Restart

# In the Windows 10 Setup
Shift + F10
C:
cd Windows\System32
ren utilman.exe cmd.exe 
ren utilman.exe.bak utilman.exe
net user Administrator /active:no
wpeutil reboot