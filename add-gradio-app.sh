#!/bin/bash
PARAM=($1)
APP_NAME=${PARAM[0]}
GITHUB_REPO=${PARAM[1]}
HUGGINGFACE_TOKEN_NAME=${PARAM[2]}
HUGGINGFACE_TOKEN_VALUE=$(curl -s -H "Authorization: Bearer Oracle" -L http://169.254.169.254/opc/v2/instance/ | jq -r '.metadata.huggingface_token')

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
ExecStart=/bin/bash $APP_DIR/start.sh

[Install]
WantedBy=multi-user.target
EOT

cat <<EOT >> /etc/nginx/sites-available/$APP_NAME
server {
    listen 8000;

    location /$APP_NAME/ {
        proxy_set_header Host \$host;
        proxy_pass http://127.0.0.1:$GRADIO_SERVER_PORT/;
    }
}
EOT

ln -s /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled

systemctl daemon-reload
systemctl enable $APP_NAME
systemctl restart $APP_NAME
systemctl restart nginx
}


add_gradio_app() {

if [[ -f ~/$APP_NAME/.venv/bin/activate ]]
then
    source ~/$APP_NAME/.venv/bin/activate
else
    git clone $GITHUB_REPO ~/$APP_NAME
    python3 -m venv ~/$APP_NAME/.venv
    source ~/$APP_NAME/.venv/bin/activate
    pip install -r ~/$APP_NAME/requirements.txt
    pip install gradio
fi

NUM_FILES=$(ls -1qA ~ | wc -l)
GRADIO_SERVER_PORT=$((NUM_FILES + 10000))

cat <<EOT >> $APP_DIR/start.sh
export $HUGGINGFACE_TOKEN_NAME=$HUGGINGFACE_TOKEN_VALUE 
export GRADIO_SERVER_PORT=$GRADIO_SERVER_PORT 
$APP_DIR/.venv/bin/python $APP_DIR/app.py
EOT

sudo bash -c "$(declare -f add_gradio_app_root); add_gradio_app_root $USER $APP_NAME $APP_DIR $HUGGINGFACE_TOKEN_NAME $HUGGINGFACE_TOKEN_VALUE $GRADIO_SERVER_PORT"
}

add_gradio_app 2>&1 >> /tmp/startup.log