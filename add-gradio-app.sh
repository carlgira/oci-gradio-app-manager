#!/bin/bash
PARAM=($1)
APP_NAME=${PARAM[0]}
GITHUB_REPO=${PARAM[1]}
HUGGINGFACE_TOKEN_NAME=${PARAM[2]}
HUGGINGFACE_TOKEN_VALUE=$(cat ~/.huggingface_token)

USER='ubuntu'
HOME_DIR=$(eval echo ~$USER)
APP_DIR=$HOME_DIR/$APP_NAME

add_gradio_app_root() {
USER=$1 
APP_NAME=$2
APP_DIR=$3 
HUGGINGFACE_TOKEN_NAME=$4 
HUGGINGFACE_TOKEN_VALUE=$5 
GRADIO_SERVER_PORT=$6

cat <<EOT >> /etc/systemd/system/$APP_NAME.service
[Unit]
Description=uWSGI instance to serve $APP_NAME
After=network.target

[Service]
User=$USER
Group=www-data
WorkingDirectory=$APP_DIR
Environment="PATH=$APP_DIR/.venv/bin; $HUGGINGFACE_TOKEN_NAME=$HUGGINGFACE_TOKEN_VALUE; GRADIO_SERVER_PORT=$GRADIO_SERVER_PORT"
ExecStart=$APP_DIR/.venv/bin/uwsgi --ini uswgi.ini

[Install]
WantedBy=multi-user.target
EOT


cat <<EOT >> /etc/nginx/sites-available/$APP_NAME
server {
    listen 80;

    location /$APP_NAME {
        include uwsgi_params;
        uwsgi_pass unix:$APP_DIR/$APP_NAME.sock;
    }
}
EOT

ln -s /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled

systemctl daemon-reload
systemctl start $APP_NAME
systemctl enable $APP_NAME
systemctl restart nginx
}


add_gradio_app() {

git clone $GITHUB_REPO ~/$APP_NAME
python3 -m venv ~/$APP_NAME/.venv
source ~/$APP_NAME/.venv/bin/activate
pip install -r ~/$APP_NAME/requirements.txt
pip install gradio uwsgi

NUM_FILES=$(ls -1qA ~ | wc -l)
GRADIO_SERVER_PORT=$((NUM_FILES + 1000))

cat <<EOT >> $HOME_DIR/$APP_NAME/uswgi.ini
[uwsgi]
module = wsgi:app

master = true
processes = 1

socket = $APP_NAME.sock
chmod-socket = 660
vacuum = true

die-on-term = true
EOT

sudo add_gradio_app_root $USER $APP_NAME $APP_DIR $HUGGINGFACE_TOKEN_NAME $HUGGINGFACE_TOKEN_VALUE $GRADIO_SERVER_PORT

}

add_gradio_app 2>&1 > $APP_DIR/startup.log