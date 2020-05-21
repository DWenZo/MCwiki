#!/bin/bash
# /etc/init.d/minecraft
# version beta 0.1 2020-05-10 (YYYY-MM-DD)
#
### BEGIN INIT INFO
# Provides: minecraft
# Required-Start: $local_fs $remote_fs screen-cleanup
# Required-Stop:  $local_fs $remote_fs
# Should-Start:   $network
# Should-Stop:    $network
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Short-Description: Minecraft server
# Description: Starts the minecraft server
### END INIT INFO

# Settings
SERVICE="spigot.jar"
SCREENNAME="minecraft_server"
OPTIONS="nogui"
WORLD="world"
MCPATH='/home/username/minecraft'
BACKUPPATH='/media/remote.share/minecraft.backup'
MAXHEAP=1024
MINHEAP=1024
HISTORY=1024
INVOCATION="java -Xmx${MAXHEAP}M -Xms${MINHEAP}M -jar $SERVICE $OPTIONS\n" 

mc_start() {
    if pgrep -f $SERVICE > /dev/null
    then
        echo "$SERVICE is already running!"
    else
        echo "Starting $SERVICE..."
        bash -c "cd $MCPATH && screen -dmS ${SCREENNAME}"
	bash -c "screen -p 0 -S $SCREENNAME -X stuff \"$INVOCATION\" "
        sleep 10
        if pgrep -f $SERVICE > /dev/null
        then 
            echo "$SERVICE is now running."
        else   
            echo "ERROR! Could not start $SERVICE!"
        fi
    fi
}

mc_saveoff() {
    if pgrep -f $SERVICE > /dev/null
    then   
        echo "$SERVICE is runnint... suspending saves"
        bash -c "screen -p 0 -S ${SCREENAME} -X eval 'stuff \"say SERVER BACKUP STARTING. Server going readonly...\"\015'"
        bash -c "screen -p 0 -S ${SCREENAME} -X eval 'stuff \"save-off\"\015'"
        bash -c "screen -p 0 -S ${SCREENAME} -X eval 'stuff \"save-all\"\015'"
        sync
        sleep 10
    else 
        echo "$SERVICE is not running."
    fi
}

mc_saveon() {
    if pgrep -f $SERVICE > /dev/null
    then
        echo "$SERVICE is running... enabling saves"
        bash -c "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"save-on\"\015'"
        bash -c "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"say SERVER BACKUP ENDED. Server going read-write...\"\015'"
    else    
        echo "$SERVICE is not running."
    fi
}

mc_stop() {
    if pgrep -f $SERVICE > /dev/null
    then
        echo "Stopping $SERVICE"
        bash -c "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"say SERVER SHUTTING DOWN IN 10 SECONDS. Saving map...\"\015'"
        bash -c "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"save-all\"\015'"
        sleep 10
        bash -c "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"stop\"\015'"
        sleep 7
    else 
        echo "$SERVICE is not running."
    fi
    if pgrep -f $SERVICE > /dev/null
    then
        echo "ERROR! $SERVICE could not be stopped"
    else    
	bash -c "screen -p 0 -S ${SCREENNAME} -X quit"
        echo "$SERVICE is stopped."
    fi
}

mc_status() {
    if pgrep -f $SERVICE > /dev/null
    then
        echo "SERVER INFO"
        pre_log_len=`wc -l "$MCPATH/logs/latest.log" | awk '{print $1}'`
        # 获取最新log文件的行数
        bash -c "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"list\"\015'"
        sleep .2
        # print 
        tail -n $[`wc -l "$MCPATH/logs/latest.log" | awk '{print $1}'`-$pre_log_len] "$MCPATH/logs/latest.log"
    else
        echo "ERROR! $SERVICE is not running."
    fi
}

mc_command() {
    command="$1"
    if pgrep -f $SERVICE > /dev/null
    then
        pre_log_len=`wc -l "$MCPATH/logs/latest.log" | awk '{print $1}'`
        # 获取最新log文件的行数
        echo "$SERVICE is executing command"
        bash -c "screen -p 0 -S ${SCREENNAME} -X eval 'stuff \"$command\"\015'"
        sleep .2
        # print 
        tail -n $[`wc -l "$MCPATH/logs/latest.log" | awk '{print $1}'`-$pre_log_len] "$MCPATH/logs/latest.log"
    fi
}

# contorl
case "$1" in
    start)
        mc_start
        ;;
    stop)
        mc_stop
        ;;
    restart)
        mc_stop
        mc_start
        ;;
    status)
        if pgrep -f $SERVICE > /dev/null
        then
            echo "$SERVICE is running."
            mc_status
        else
            echo "$SERVICE is not running."
        fi
        ;;
    command)
        if [ $# -gt 1 ]
        then
            shift
            # shift 左移，把 'command' 移除
            mc_command "$*"
        else
            echo "Must specify server command (try 'help'?)"
        fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status|restart|command \"server command\"}"
        exit 1
        ;;
esac

exit 0