# Magic Mole
Bash network tunnel manager

### Required Packages
- grep
- awk
- sed
- cat
- autossh

### Installing
First start by cloning this repository

```
cd <your-git-folder>
git clone https://github.com/geodavies/magic-mole.git
```
Next we need to configure which tunnels you want to use. This script will look for the file *example-tunnels.csv*
for the configuration of the tunnels by default. This location can be changed by updating the location at the top of the script.

The *example-tunnels.csv* file inside this repository can be used as a starting point but you will likely want to move this somewhere more permanent in the long run. The below commands for your system will move the *example-tunnels.csv* file to your home directory and change the location in the script. If you already have a *tunnels.csv* file in your home directory it will be replaced, so make sure you back it up first or skip the second command.

**Linux**
```
cd magic-mole
cp example-tunnels.csv /home/$USER/tunnels.csv
sed -i 's/^input=.*$/input="\/home\/$USER\/tunnels.csv"/g' magic-mole.sh
```
**MacOS**
```
cd magic-mole
cp example-tunnels.csv /Users/$USER/tunnels.csv
sed -i '' 's/^input=.*$/input="\/Users\/$USER\/tunnels.csv"/g' magic-mole.sh
```
You can now execute the script directly from the git repository directory if you choose but you may want to
create a symlink to the script so it can be executed from anywhere in the terminal.
```
sudo ln -s $PWD/magic-mole.sh /usr/local/bin/mm
```
The script can now be run from anywhere by using the command '*mm*'

To have the tunnels start automatically on login, add the following to the bottom of ~/.profile:
```
mm start
```
*Note this script is currently limited to only make connections to servers which already have the public key of the
host being run from configured on the bastion host.*

### Usage
To get usage instructions run the script without any arguments
```
mm
```
```
Usage: [command] [name]
    1: The command to perform on the tunnel (eg. start/stop/restart/status)
    2: (Optional) The name of the tunnel (eg. tunnel-name) or leave empty for all
```
Tunnels can either be directly referenced by their name (eg. example-tunnel-1) or you can leave it empty to apply the command to all tunnels.

Tunnels can also be referred to by any of their tags. If for example you want to start all tunnels which contain both the *dev* and *example* tags
then you can run 'mm start dev example'. Note that when starting by tag all tags provided must be present in the spreadsheet record. 
#### Example
Individual
```
mm status example-tunnel-1
```
```
Tunnel Name               | Tags                           | IP              | Local Port      | Remote Port     | Bastion                   | Status 
--------------------------+--------------------------------+-----------------+-----------------+-----------------+---------------------------+----------
example-tunnel-1          | dev example                    | 12.151.112.202  | 3000            | 3000            | bill@136.62.46.55         | Down           
```
All
```
mm status
```
```
Tunnel Name               | Tags                           | IP              | Local Port      | Remote Port     | Bastion                   | Status 
--------------------------+--------------------------------+-----------------+-----------------+-----------------+---------------------------+----------
example-tunnel-1          | dev                            | 12.151.112.202  | 3000            | 3000            | bill@136.62.46.55         | Down   
example-tunnel-2          | ci                             | 146.218.221.177 | 9090            | 8080            | ben@198.24.36.47          | Down      
```
Tag
```
mm status example
```
```
Tunnel Name               | Tags                           | IP              | Local Port      | Remote Port     | Bastion                   | Status 
--------------------------+--------------------------------+-----------------+-----------------+-----------------+---------------------------+----------
example-tunnel-1          | dev example                    | 12.151.112.202  | 3000            | 3000            | bill@136.62.46.55         | Down   
example-tunnel-2          | ci example                     | 146.218.221.177 | 9090            | 8080            | ben@198.24.36.47          | Down      
```
```
mm status dev
```
```
Tunnel Name               | Tags                           | IP              | Local Port      | Remote Port     | Bastion                   | Status 
--------------------------+--------------------------------+-----------------+-----------------+-----------------+---------------------------+----------
example-tunnel-1          | dev example                    | 12.151.112.202  | 3000            | 3000            | bill@136.62.46.55         | Down   
```
