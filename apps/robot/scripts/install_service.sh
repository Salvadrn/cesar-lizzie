#!/bin/bash
# Install Adapt AI Robot as a systemd service on Raspberry Pi

SERVICE_NAME="adaptai-robot"
INSTALL_DIR="/opt/adaptai-robot"
USER="pi"

echo "Installing $SERVICE_NAME service..."

# Copy files
sudo mkdir -p $INSTALL_DIR
sudo cp -r ../src ../config ../requirements.txt $INSTALL_DIR/
sudo chown -R $USER:$USER $INSTALL_DIR

# Install Python deps
cd $INSTALL_DIR
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create systemd service
sudo tee /etc/systemd/system/$SERVICE_NAME.service > /dev/null << EOF
[Unit]
Description=Adapt AI Medical Follower Robot
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python src/main.py --config config/default.yaml
Restart=always
RestartSec=5
Environment=PYTHONPATH=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
echo "Service installed. Start with: sudo systemctl start $SERVICE_NAME"
