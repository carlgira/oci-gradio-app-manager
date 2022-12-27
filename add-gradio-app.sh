#!/bin/bash

USER='ubuntu'
HOME_DIR=$(eval echo ~$USER)


add_gradio_app_root() {
USER=$1 
APP_NAME=$2
APP_DIR=$3 
GRADIO_SERVER_PORT=$4

cat <<EOT > /etc/systemd/system/$APP_NAME.service
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

cat <<EOT > /etc/nginx/sites-available/$APP_NAME
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
APP_NAME=$1
GITHUB_REPO=$2
REQUIREMENTS=$3
ENVIRONMENT=$4
APP_DIR=$HOME_DIR/$APP_NAME

if [[ ! -f "$APP_DIR"/.venv/bin/activate ]]
then
    git clone $GITHUB_REPO $APP_DIR
    python3 -m venv $APP_DIR/.venv
fi

source $APP_DIR/.venv/bin/activate

NUM_FILES=$(ls -1qA ~ | wc -l)
GRADIO_SERVER_PORT=$((NUM_FILES + 10000))

    echo "$REQUIREMENTS" 
    if [ "$REQUIREMENTS" != "null" ]; then
        rm $APP_DIR/requirements.txt
        echo "$REQUIREMENTS" | jq -r -c '.[]' |
        while IFS=$"\n" read -r c; do
            echo $c >> $APP_DIR/requirements.txt
        done
    fi

    pip install --upgrade pip
    pip install gradio
    pip install -r $APP_DIR/requirements.txt
    
    VARS=''
    # check in ENVIRONMENT is not null
    if [ "$ENVIRONMENT" != "null" ]; then
        for s in $(echo $ENVIRONMENT | jq -r "to_entries|map(\"\(.key)=\u0027\(.value|tostring)\u0027\")|.[]" ); do
            VARS=$(echo -e "$VARS \n export $s")
        done
    fi
    cat <<EOT > $APP_DIR/start.sh
$VARS
export GRADIO_SERVER_PORT=$GRADIO_SERVER_PORT 
$APP_DIR/.venv/bin/python $APP_DIR/app.py
EOT

sudo bash -c "$(declare -f add_gradio_app_root); add_gradio_app_root $USER $APP_NAME $APP_DIR $GRADIO_SERVER_PORT"
}

add_all_apps(){
CONF_FILE=$1

cat $CONF_FILE | jq -c '.[]' |
while IFS=$"\n" read -r c; do
    APP_NAME=$(echo "$c" | jq -r '.appName')
    APP_URL=$(echo "$c" | jq -r '.appUrl')
    REQUIREMENTS=$(echo "$c" | jq -r '.requirements')
    ENVIRONMENT=$(echo "$c" | jq -r '.environment')

    add_gradio_app $APP_NAME $APP_URL $REQUIREMENTS $ENVIRONMENT
done

}

add_all_apps $1 2>&1 > /tmp/startup.log