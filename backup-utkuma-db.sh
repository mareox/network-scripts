#!/bin/bash

# Display current date and time at the beginning
echo "--------------------------------------------------------------"
echo "   Backup script started on $(date '+%Y-%m-%d %H:%M:%S')"
echo "--------------------------------------------------------------"

# Stop the Docker container
echo "Stoping container ..."
sudo docker stop utkuma

# Wait until the container has stopped
while sudo docker inspect -f '{{.State.Status}}' utkuma | grep -q "running"; do
    sleep 1
done

# Check if the container stopped successfully
if [ $? -eq 0 ]; then
    echo "Docker container 'utkuma' has been stopped."
else
    echo "Error stopping Docker container 'utkuma'."
    exit 1
fi

echo "Backup copy is running..."

# Define variables
backupDate=$(date '+%F')
BACKUP_DIR="/home/mx-server/backups/BK_utkuma"
BACKUP_NAME="kuma-db-$backupDate.tar.gz"
DB_FILE="/home/docker/utkuma-local/data/kuma.db"
MAX_BACKUPS=6

# Create the backup directory if it doesn't exist
# mkdir -p "$BACKUP_DIR"

# Run the backup command with progress display
cd /home/docker/utkuma-local/data
sudo tar cf - kuma.db | pv -s $(du -sb kuma.db | awk '{print $1}') | gzip > "$BACKUP_NAME"

# Check if the tar file was created successfully
if [ $? -eq 0 ]; then
    echo -e "\nBackup file '$BACKUP_NAME' created successfully."
else
    echo -e "\nError creating backup file."
    exit 1
fi

# Move the backup file to the backup directory
mv "$BACKUP_NAME" "$BACKUP_DIR"

# Check if the move was successful
if [ $? -eq 0 ]; then
    echo "Backup file moved to '$BACKUP_DIR'."
else
    echo "Error moving backup file."
    exit 1
fi

# Delete old backups if there are more than the maximum allowed
cd "$BACKUP_DIR"
BACKUPS_COUNT=$(ls -1 | grep "^db-[0-9]\{8\}-[0-9]\{4\}.tar.gz$" | wc -l)
if [ $BACKUPS_COUNT -gt $MAX_BACKUPS ]; then
  ls -1t | grep "^db-[0-9]\{8\}-[0-9]\{4\}.tar.gz$" | tail -$((BACKUPS_COUNT - MAX_BACKUPS)) | xargs -d '\n' rm
fi

# Verify if the Docker container starts correctly
echo "Starting Docker container utkuma ..."
sudo docker start utkuma
sleep 10

# Check if the container started successfully
if [ $? -eq 0 ]; then
    echo "Docker container 'utkuma' has started."
else
    echo "Error starting Docker container 'utkuma'."
    exit 1
fi

echo "Backup is done... Docker container is up and running!"

# Display current date and time at the end
echo ""
echo "--------------------------------------------------------------"
echo "Backup script completed on $(date '+%Y-%m-%d %H:%M:%S')"
echo "--------------------------------------------------------------"
