#!/bin/bash
# setup dev env on debian

# check if sudo permission is not available
if [ "$EUID" -ne 0 ]; then
    echo "sudo permission is not available"
    exit
fi

# install system-wide dependencies 
apt-get install git curl python-pip
curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
eval "$(pyenv virtualenv-init -)"

# setting up virtualenv and installing requirements
pyenv install 3.6.5
pyenv virtualenv 3.6.5 systers
pyenv activate systers
pip install -r ../requirements/dev.txt

# create the database using psql and the user postgres
read -p "Username: " username
while true; do
    read -s -p "Password: " password
    echo
    read -s -p "Password (again): " password2
    echo
    [ "$password" = "$password2" ] && break
    echo "Please try again"
done
read -p "Enter the name of the db: " db
sudo -i -u postgres psql -c "CREATE ROLE $username WITH PASSWORD '$password'"
sudo -i -u postgres psql -c "CREATE DATABASE $db"
sudo -i -u postgres psql -c "\c $db"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $db to $username"

# change the django settings
sed -i.bak "s/'NAME': 'systersdb',/'NAME': '$db',/" ../systers_portal/systers_portal/settings/dev.py
sed -i.bak "s/'USER': '',/'USER': '$username',/" ../systers_portal/systers_portal/settings/dev.py
sed -i.bak "s/'PASSWORD': '',/'PASSWORD': '$password',/" ../systers_portal/systers_portal/settings/dev.py

# host the server for the first time
export SECRET_KEY='foobarbaz'
python ../systers_portal/manage.py migrate
python ../systers_portal/manage.py cities_light
python ../systers_portal/manage.py createsuperuser
python ../systers_portal/manage.py runserver
