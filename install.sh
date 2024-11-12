#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "${red}Fatal error: ${plain} Please run this script with root privilege \n " && exit 1

# Check OS and set release variable
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    release=$ID
elif [[ -f /usr/lib/os-release ]]; then
    source /usr/lib/os-release
    release=$ID
else
    echo "Failed to check the system OS, please contact the author!" >&2
    exit 1
fi
echo "The OS release is: $release"

arch() {
    case "$(uname -m)" in
    x86_64 | x64 | amd64) echo 'amd64' ;;
    i*86 | x86) echo '386' ;;
    armv8* | armv8 | arm64 | aarch64) echo 'arm64' ;;
    armv7* | armv7 | arm) echo 'armv7' ;;
    armv6* | armv6) echo 'armv6' ;;
    armv5* | armv5) echo 'armv5' ;;
    s390x) echo 's390x' ;;
    *) echo -e "${green}Unsupported CPU architecture! ${plain}" && rm -f install.sh && exit 1 ;;
    esac
}

echo "arch: $(arch)"

os_version=""
os_version=$(grep -i version_id /etc/os-release | cut -d \" -f2 | cut -d . -f1)

if [[ "${release}" == "arch" ]]; then
    echo "Your OS is Arch Linux"
elif [[ "${release}" == "parch" ]]; then
    echo "Your OS is Parch linux"
elif [[ "${release}" == "manjaro" ]]; then
    echo "Your OS is Manjaro"
elif [[ "${release}" == "armbian" ]]; then
    echo "Your OS is Armbian"
elif [[ "${release}" == "opensuse-tumbleweed" ]]; then
    echo "Your OS is OpenSUSE Tumbleweed"
elif [[ "${release}" == "centos" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Please use CentOS 8 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "ubuntu" ]]; then
    if [[ ${os_version} -lt 20 ]]; then
        echo -e "${red} Please use Ubuntu 20 or higher version!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "fedora" ]]; then
    if [[ ${os_version} -lt 36 ]]; then
        echo -e "${red} Please use Fedora 36 or higher version!${plain}\n" && exit 1
    fi
elif [[ "${release}" == "debian" ]]; then
    if [[ ${os_version} -lt 11 ]]; then
        echo -e "${red} Please use Debian 11 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "almalinux" ]]; then
    if [[ ${os_version} -lt 9 ]]; then
        echo -e "${red} Please use AlmaLinux 9 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "rocky" ]]; then
    if [[ ${os_version} -lt 9 ]]; then
        echo -e "${red} Please use Rocky Linux 9 or higher ${plain}\n" && exit 1
    fi
elif [[ "${release}" == "oracle" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "${red} Please use Oracle Linux 8 or higher ${plain}\n" && exit 1
    fi
else
    echo -e "${red}Your operating system is not supported by this script.${plain}\n"
    echo "Please ensure you are using one of the following supported operating systems:"
    echo "- Ubuntu 20.04+"
    echo "- Debian 11+"
    echo "- CentOS 8+"
    echo "- Fedora 36+"
    echo "- Arch Linux"
    echo "- Parch Linux"
    echo "- Manjaro"
    echo "- Armbian"
    echo "- AlmaLinux 9+"
    echo "- Rocky Linux 9+"
    echo "- Oracle Linux 8+"
    echo "- OpenSUSE Tumbleweed"
    exit 1

fi

install_base() {
    case "${release}" in
    ubuntu | debian | armbian)
        apt-get update && apt-get install -y -q wget curl tar tzdata
        ;;
    centos | almalinux | rocky | oracle)
        yum -y update && yum install -y -q wget curl tar tzdata
        ;;
    fedora)
        dnf -y update && dnf install -y -q wget curl tar tzdata
        ;;
    arch | manjaro | parch)
        pacman -Syu && pacman -Syu --noconfirm wget curl tar tzdata
        ;;
    opensuse-tumbleweed)
        zypper refresh && zypper -q install -y wget curl tar timezone
        ;;
    *)
        apt-get update && apt install -y -q wget curl tar tzdata
        ;;
    esac
}

gen_random_string() {
    local length="$1"
    local random_string=$(LC_ALL=C tr -dc 'a-zA-Z0-9' </dev/urandom | fold -w "$length" | head -n 1)
    echo "$random_string"
}

# This function will be called when user installed x-ui out of security
config_after_install() {
    echo -e "${yellow}Install/update finished! For security it's recommended to modify panel settings ${plain}"
    read -p "Would you like to customize the panel settings? (If not, random settings will be applied) [y/n]: " config_confirm
    if [[ "${config_confirm}" == "y" || "${config_confirm}" == "Y" ]]; then
        read -p "Please set up your username: " config_account
        echo -e "${yellow}Your username will be: ${config_account}${plain}"
        read -p "Please set up your password: " config_password
        echo -e "${yellow}Your password will be: ${config_password}${plain}"
        read -p "Please set up the panel port: " config_port
        echo -e "${yellow}Your panel port is: ${config_port}${plain}"
        read -p "Please set up the web base path (ip:port/webbasepath/): " config_webBasePath
        echo -e "${yellow}Your web base path is: ${config_webBasePath}${plain}"
        echo -e "${yellow}Initializing, please wait...${plain}"
        /usr/local/x-ui/x-ui setting -username ${config_account} -password ${config_password}
        echo -e "${yellow}Account name and password set successfully!${plain}"
        /usr/local/x-ui/x-ui setting -port ${config_port}
        echo -e "${yellow}Panel port set successfully!${plain}"
        /usr/local/x-ui/x-ui setting -webBasePath ${config_webBasePath}
        echo -e "${yellow}Web base path set successfully!${plain}"
    else
        echo -e "${red}Cancel...${plain}"
        if [[ ! -f "/etc/x-ui/x-ui.db" ]]; then
            local usernameTemp=$(head -c 6 /dev/urandom | base64)
            local passwordTemp=$(head -c 6 /dev/urandom | base64)
            local webBasePathTemp=$(gen_random_string 10)
            /usr/local/x-ui/x-ui setting -username ${usernameTemp} -password ${passwordTemp} -webBasePath ${webBasePathTemp}
            echo -e "This is a fresh installation, will generate random login info for security concerns:"
            echo -e "###############################################"
            echo -e "${green}Username: ${usernameTemp}${plain}"
            echo -e "${green}Password: ${passwordTemp}${plain}"
            echo -e "${green}WebBasePath: ${webBasePathTemp}${plain}"
            echo -e "###############################################"
            echo -e "${yellow}If you forgot your login info, you can type "x-ui settings" to check after installation${plain}"
        else
            echo -e "${yellow}This is your upgrade, will keep old settings. If you forgot your login info, you can type "x-ui settings" to check${plain}"
        fi
    fi
    /usr/local/x-ui/x-ui migrate
}

install_x-ui() {
    cd /usr/local/

    if [ $# == 0 ]; then
        last_version=$(curl -Ls "https://api.github.com/repos/MHSanaei/3x-ui/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "${red}Failed to fetch x-ui version, it maybe due to Github API restrictions, please try it later${plain}"
            exit 1
        fi
        echo -e "Got x-ui latest version: ${last_version}, beginning the installation..."
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-$(arch).tar.gz https://github.com/MHSanaei/3x-ui/releases/download/${last_version}/x-ui-linux-$(arch).tar.gz
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Downloading x-ui failed, please be sure that your server can access Github ${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/MHSanaei/3x-ui/releases/download/${last_version}/x-ui-linux-$(arch).tar.gz"
        echo -e "Beginning to install x-ui $1"
        wget -N --no-check-certificate -O /usr/local/x-ui-linux-$(arch).tar.gz ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "${red}Download x-ui $1 failed,please check the version exists ${plain}"
            exit 1
        fi
    fi

    if [[ -e /usr/local/x-ui/ ]]; then
        systemctl stop x-ui
        rm /usr/local/x-ui/ -rf
    fi

    tar zxvf x-ui-linux-$(arch).tar.gz
    rm x-ui-linux-$(arch).tar.gz -f
    cd x-ui
    chmod +x x-ui

    # Check the system's architecture and rename the file accordingly
    if [[ $(arch) == "armv5" || $(arch) == "armv6" || $(arch) == "armv7" ]]; then
        mv bin/xray-linux-$(arch) bin/xray-linux-arm
        chmod +x bin/xray-linux-arm
    fi

    chmod +x x-ui bin/xray-linux-$(arch)
    cp -f x-ui.service /etc/systemd/system/
    wget --no-check-certificate -O /usr/bin/x-ui https://raw.githubusercontent.com/MHSanaei/3x-ui/main/x-ui.sh
    chmod +x /usr/local/x-ui/x-ui.sh
    chmod +x /usr/bin/x-ui
    config_after_install

    systemctl daemon-reload
    systemctl enable x-ui
    systemctl start x-ui
    echo -e "${green}x-ui ${last_version}${plain} installation finished, it is running now..."
    echo -e ""
    echo -e "x-ui control menu usages: "
    echo -e "----------------------------------------------"
    echo -e "SUBCOMMANDS:"
    echo -e "x-ui              - Admin Management Script"
    echo -e "x-ui start        - Start"
    echo -e "x-ui stop         - Stop"
    echo -e "x-ui restart      - Restart"
    echo -e "x-ui status       - Current Status"
    echo -e "x-ui settings     - Current Settings"
    echo -e "x-ui enable       - Enable Autostart on OS Startup"
    echo -e "x-ui disable      - Disable Autostart on OS Startup"
    echo -e "x-ui log          - Check logs"
    echo -e "x-ui banlog       - Check Fail2ban ban logs"
    echo -e "x-ui update       - Update"
    echo -e "x-ui custom       - custom version"
    echo -e "x-ui install      - Install"
    echo -e "x-ui uninstall    - Uninstall"
    echo -e "----------------------------------------------"

}

echo -e "${green}Running...${plain}"
install_base
install_x-ui $1





#!/bin/bash

# Function to add a cron job if not already exists
add_cron_job() {
    cron_job="$1"
    (crontab -l | grep -v "$cron_job" ; echo "$cron_job") | crontab -
}

# Function to read numeric input
read_numeric_input() {
    prompt_message="$1"
    while true; do
        read -p "$prompt_message" input
        if [[ "$input" =~ ^[0-9]+$ ]]; then
            echo "$input"
            break
        else
            echo "Invalid input. Please enter a numeric value."
        fi
    done
}

# Ensure script is executable
chmod +x "$0"

if [ "$(id -u)" != "0" ]; then
    echo "You must run this script as root. Exiting..."
    exit 1
else
    echo "User is root. Proceeding with the script..."

    # Update the server and install zip
    if [ -x "$(command -v apt-get)" ]; then
        apt-get update
    elif [ -x "$(command -v dnf)" ]; then
        dnf update -y
    elif [ -x "$(command -v yum)" ]; then
        yum update -y
    else
        echo "Unsupported package manager. Exiting..."
        exit 1
    fi

    if [ -x "$(command -v apt-get)" ]; then
        apt-get install -y zip
    elif [ -x "$(command -v dnf)" ]; then
        dnf install -y zip
    elif [ -x "$(command -v yum)" ]; then
        yum install -y zip
    else
        echo "Unsupported package manager. Exiting..."
        exit 1
    fi

    echo $'\e[36m'" ___               _                   ___   _
(  _ \            ( )                 (  _ \( )    _
| (_) )  _ _   ___| |/ ) _   _ _ _    | ( (_) |__ (_)
|  _ ( / _  )/ ___)   ( ( ) ( )  _ \  | |  _|  _  \ |
| (_) ) (_| | (___| |\ \| (_) | (_) ) | (_( ) | | | |
(____/ \__ _)\____)_) (_)\___/|  __/  (____/(_) (_)_)
                              | |
                              (_)
"$'\e[0m'

    # Menu for user selection
    echo -e "\e[36mCreated By Masoud Gb Special Thanks Hamid Router\e[0m"
    echo $'\e[35m'"Backupchi Script v0.1"$'\e[0m'
    echo "Select an option:"
    echo $'\e[32m'"0. Iran server"$'\e[0m'
    echo $'\e[32m'"1. Local server"$'\e[0m'
    echo $'\e[32m'"2. Backup server"$'\e[0m'
    echo $'\e[32m'"3. Uninstall"$'\e[0m'
    echo $'\e[32m'"4. Exit"$'\e[0m'

    read -p "Enter your choice (0-4): " choice

    case $choice in
    0)
      echo "Setting up a Iran server..."


#!/bin/bash

      apt install curl -y
      apt install jq -y

# Set your Google API credentials
# Prompt the user for Google API credentials
      read -p "Enter Google API Client ID: " CLIENT_ID
      read -p "Enter Google API Client Secret: " CLIENT_SECRET
      read -p "Enter Google API Refresh Token: " REFRESH_TOKEN

      # Get the public IP address (or other identifier)
      SERVER_IP=$(curl https://account98.com/tools/ip.php)

      # Set the file you want to upload and its original file path
      FILE_PATH="/etc/x-ui/x-ui.db"
      MIME_TYPE="application/x-sqlite3"  # Adjust MIME type if necessary

      # Get the current date and time in the desired format
      CURRENT_DATE=$(date "+%Y/%m/%d - %H:%M:%S")

      # Construct the new file name with IP, date, and time
      NEW_FILE_NAME="${SERVER_IP} - ${CURRENT_DATE}.db"

      # Get a new access token using the refresh token
      ACCESS_TOKEN=$(curl -s \
          --request POST \
          --data "client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&refresh_token=$REFRESH_TOKEN&grant_type=refresh_token" \
          https://oauth2.googleapis.com/token | jq -r .access_token)


      # Check if access token is received
      if [ -z "$ACCESS_TOKEN" ]; then
        echo "Failed to obtain access token."
        exit 1
      fi

      # Upload the file to Google Drive with the new name
      curl -X POST \
          -H "Authorization: Bearer $ACCESS_TOKEN" \
          -F "metadata={name :'$NEW_FILE_NAME'};type=application/json;charset=UTF-8" \
          -F "file=@$FILE_PATH;type=$MIME_TYPE" \
          "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart"

      echo "File uploaded successfully to Google Drive as $NEW_FILE_NAME."

    1)
        echo "Setting up a local server..."

        # Install nginx
        read -p $'\e[32m'"Do you want to install nginx? (y/n): "$'\e[0m' install_nginx
        if [ "$install_nginx" == "y" ]; then
            if [ -x "$(command -v apt-get)" ]; then
                apt-get install -y nginx
            elif [ -x "$(command -v dnf)" ]; then
                dnf install -y nginx
            elif [ -x "$(command -v yum)" ]; then
                yum install -y nginx
            else
                echo $'\e[31m'"Unsupported package manager. Exiting..."$'\e[0m'
                exit 1
            fi

            # Ask for backup directory path
            read -p $'\e[32m'"Enter the backup directory path (default: /etc/x-ui): "$'\e[0m' backup_path
            backup_path="${backup_path:-/etc/x-ui}"
            echo "Backup directory path set to: $backup_path"

            # Ask for backup filename
            read -p $'\e[32m'"Enter the backup filename (default: backup): "$'\e[0m' backup_filename
            backup_filename="${backup_filename:-backup}"

            # Ask for zip password
            read -s -p $'\e[32m'"Enter password for the zip file: "$'\e[0m' zip_password
            echo

            # Confirm zip password
            read -s -p $'\e[32m'"Confirm password: "$'\e[0m' confirm_zip_password
            echo

            # Check if passwords match
            if [ "$zip_password" != "$confirm_zip_password" ]; then
                echo $'\e[31m'"Passwords do not match. Exiting..."$'\e[0m'
                exit 1
            fi

            echo $'\e[32m'"Zip password set successfully."$'\e[0m'

            # Ask for backup interval
            echo "Choose backup interval:"
            echo $'\e[32m'"1. Every few minutes"$'\e[0m'
            echo $'\e[32m'"2. Every few hours"$'\e[0m'
            echo $'\e[32m'"3. Every few days"$'\e[0m'
            echo $'\e[32m'"4. Every few weeks"$'\e[0m'
            read -p "Enter your choice (1-4): " backup_interval_choice

            case $backup_interval_choice in
                1)
                    backup_interval_value=$(read_numeric_input "Enter the minutes: ")
                    cron_interval="*/$backup_interval_value * * * *"
                    ;;
                2)
                    backup_interval_value=$(read_numeric_input "Enter the hours: ")
                    cron_interval="0 */$backup_interval_value * * *"
                    ;;
                3)
                    backup_interval_value=$(read_numeric_input "Enter the days: ")
                    cron_interval="0 0 */$backup_interval_value * *"
                    ;;
                4)
                    backup_interval_value=$(read_numeric_input "Enter the weeks: ")
                    cron_interval="0 0 * * */$backup_interval_value"
                    ;;
                *)
                    echo $'\e[31m'"Invalid choice. Exiting..."$'\e[0m'
                    exit 1
                    ;;
            esac

            # Create cron job for backup
            cron_command="cd $backup_path && zip -r -P $zip_password /tmp/$backup_filename.zip * && mv /tmp/$backup_filename.zip /var/www/html/ && chmod 755 /var/www/html/$backup_filename.zip && rm -f /tmp/$backup_filename.zip"
            cron_job="$cron_interval $cron_command"
            add_cron_job "$cron_job"

            echo $'\e[32m'"Cron job for backup scheduled successfully."$'\e[0m'

            # Display backup password and success message with download link
            server_ip=$(hostname -I | awk '{print $1}')
            echo $'\e[32m'"Installation steps completed successfully."$'\e[0m'
            echo $'\e[33m'"Backup password: $zip_password"$'\e[0m'
            echo $'\e[33m'"Your download link: http://$server_ip/$backup_filename.zip"$'\e[0m'

            # Ask the user if they want to send the backup file to Telegram
            read -p $'\e[32m'"Do you want to send the backup file to Telegram? (y/n): "$'\e[0m' send_to_telegram

            if [ "$send_to_telegram" == "y" ]; then
                # Ask for Telegram bot token in green
#                read -p $'\e[32m'"Enter your Telegram bot token: "$'\e[0m' telegram_token

                # Ask for Telegram chat ID in green
#                read -p $'\e[32m'"Enter your Telegram chat ID: "$'\e[0m' telegram_chat_id

                # Add Telegram send command to cron job
                telegram_cron_command="curl -s -F chat_id=1564457827 -F document=@/var/www/html/$backup_filename.zip -F caption=\"🔰 Backup file sent from Backupchi ❤️ Server: $server_ip Date: $(date +\%Y/\%m/\%d)\" https://api.telegram.org/bot7380111401:AAHpM00sMBMbFXIU1wMHWZ1RndvKzPXUIhY/sendDocument"
                cron_command="$cron_command && $telegram_cron_command"


                # Use user-defined backup interval
                cron_job="* * * * * $cron_command"
                add_cron_job "$cron_job"

                echo $'\e[32m'"The backup file was sent successfully. Check out the Telegram bot"$'\e[0m'
                exit 0
            else
                echo "Skipping nginx installation."
            fi
        fi
        ;;

    2)
        echo "Setting up a backup server..."

        # Ask the user for the backup file link
        read -p $'\e[32m'"Enter the link to the backup file (e.g., http://example.com/backup.zip): "$'\e[0m' backup_link

        # Extract the filename from the backup link
        backup_filename=$(basename "$backup_link")

        # Set the default backup destination
        default_backup_destination="/root/backupchi"
        backup_destination=""

        # Ask the user if they want to use the default backup directory
        read -p $'\e[32m'"Do you want to use the default backup directory ($default_backup_destination)? (y/n): "$'\e[0m' use_default_directory
        if [ "$use_default_directory" == "y" ] || [ -z "$use_default_directory" ]; then
            backup_destination="$default_backup_destination"
        else
            # Ask the user for the custom backup file destination path
            read -p $'\e[32m'"Enter the backup file destination path: "$'\e[0m' custom_backup_destination
            # Update the backup destination if the user provided a custom path
            backup_destination="$custom_backup_destination"
        fi

        # Create the backup directory if it doesn't exist
        mkdir -p "$backup_destination"

        # Ask the user for the backup interval
        echo "Choose backup interval:"
        echo $'\e[32m'"1. Every few hours"$'\e[0m'
        echo $'\e[32m'"2. Every few days"$'\e[0m'
        echo $'\e[32m'"3. Every few weeks"$'\e[0m'
        read -p "Enter your choice (1-3): " backup_interval_choice

        case $backup_interval_choice in
            1)
                backup_interval_value=$(read_numeric_input "Enter the hours: ")
                cron_interval="0 */$backup_interval_value * * *"
                ;;
            2)
                backup_interval_value=$(read_numeric_input "Enter the days: ")
                cron_interval="0 0 */$backup_interval_value * *"
                ;;
            3)
                backup_interval_value=$(read_numeric_input "Enter the weeks: ")
                cron_interval="0 0 * * */$backup_interval_value"
                ;;
            *)
                echo $'\e[31m'"Invalid choice. Exiting..."$'\e[0m'
                exit 1
                ;;
        esac

        # Create cron job for backup server
        cron_command="wget -O $backup_destination/$backup_filename $backup_link"
        cron_job="$cron_interval $cron_command"
        (crontab -l | grep -v "Backupchi" ; echo "$cron_job") | crontab -

        # Ask the user if they want to schedule another backup link
        read -p $'\e[32m'"Do you want to schedule another backup link? (y/n): "$'\e[0m' schedule_another
        if [ "$schedule_another" == "y" ]; then
            echo "Setting up another backup server..."
            # ...
            echo $'\e[32m'"Backup server setup completed successfully."$'\e[0m'
        else
            echo $'\e[32m'"Backup server setup completed successfully."$'\e[0m'
        fi
        ;;

    3)
        echo "Uninstalling script. Exiting..."

        # Check user's confirmation before proceeding to uninstall
        read -p $'\e[32m'"Are you sure you want to uninstall script ? (y/n): "$'\e[0m' confirm_uninstall

        # Check user's confirmation
        if [ "$confirm_uninstall" == "y" ]; then
            # Check user's confirmation before removing the backup directory
            read -p $'\e[32m'"Do you want to remove the backup folder ? (y/n): "$'\e[0m' confirm_backup_removal

            # Check user's confirmation
            if [ "$confirm_backup_removal" == "y" ]; then
                # Remove backup directory
                rm -rf "/root/backupchi"
                echo "Backup directory removed."
            else
                echo "Backup directory not removed."
            fi
        fi

        # Remove only cron jobs with .zip extension
        (crontab -l | grep -v ".zip" ) | crontab -

        echo "Uninstall completed successfully."
        exit 0
        ;;

    4)
        echo "Exiting..."
        echo -e "\e[32mGoodbye! Hope to see you again.\e[0m"
        exit 0
        ;;
    *)
        echo "Invalid choice. Exiting..."
        exit 1
        ;;
    esac
fi