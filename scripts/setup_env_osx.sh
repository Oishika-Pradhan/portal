#!/bin/bash
# setup dev env on OSX

# installing brew
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

# check if the packages are installed, install them if necessary
export PATH=/usr/local/bin:/usr/local/sbin:$PATH
brew install git
brew install pyenv
brew install pyenv-virtualenv
export PYENV_ROOT=/usr/local/var/pyenv
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# setting up virtualenv and installing requirements
pyenv install 3.6.5
pyenv virtualenv 3.6.5 systers
pyenv activate systers
pip install -r ../requirements/dev.txt

# installing postgres
brew install postgresql
pg_ctl -D /usr/local/var/postgres start && brew services start postgresql

# setting up the role and db
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
psql postgres -c "CREATE USER $username WITH PASSWORD '$password'"
psql postgres -c "CREATE DATABASE $db"
psql postgres -c "\c $db"
psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE $db TO $username"

# change the django settings
sed -i.bak "s/'NAME': 'systersdb',/'NAME': '$db',/" ../systers_portal/systers_portal/settings/dev.py
sed -i.bak "s/'USER': '',/'USER': '$username',/" ../systers_portal/systers_portal/settings/dev.py
sed -i.bak "s/'PASSWORD': '',/'PASSWORD': '$password',/" ../systers_portal/systers_portal/settings/dev.py

# host the server for the first time
export SECRET_KEY='foobarbaz'
python ../systers_portal/manage.py migrate
python ../systers_portal/manage.py cities_light
python ../systers_portal.manage.py createsuperuser
python ../systers_portal/manage.py runserver
