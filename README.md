# Description

The tool for easy connection to liquid web based linux hosts over ssh
https://www.liquidweb.com/

# How to start
 
- Create an API user in liquid web
- Setup ssh key for access for every host
- Install dependencies
- Pull repo
- Add script to aliases or put it to $PATH
- Create credentials/config file with API tokens in  ~/.lwc/config
- Enjoy

# Features

- Supports 2 accounts currently with switching by [TAB]
- Built-in search
- Quick connect on [ENTER]
- Persisting list of hosts with refresh by [~]
- Quick exit on [ESC]
- Hosts limited to osFamily=linux

# How to create  ~/.lwc/config file

mkdir -p ~/.lwc
cat <<EOF > ~/.lwc/config

LW_USER_ONE=<API_USER_1>
LW_PASS_ONE=<API_PASS_1>

LW_USER_TWO=<API_USER_2>
LW_PASS_TWO=<API_PASS_2>

SSH_KEY_PATH="<PRIVATEKEY_PATH>"
SSH_USER="<USER>"
SSH_PARAMS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

EOF

# Dependencies
- fzf 
- awk
- jq
- column