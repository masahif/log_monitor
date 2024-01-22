# log_monitor
Monitor logs and execute commands

This tool monitors log files and executes specified commands. It is designed with use cases such as monitoring nginx log files in mind. This allows for the execution of external commands separated from the web server's privileges.

## Configuration File
Written in an ini file format.

```
[main]
LOGFILE=/var/log/nginx/access82.log
COOLDOWN_PERIOD=10
PATTERN=GET\ /([A-Za-z0-9_\-]+)(/.+)[\ ]HTTP/1\.1

[commands]
clear_cache=echo 'clearing cache'; aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --query 'Invalidation.Id' --output text --paths "$path"
sample=echo 'running sample'; echo $target
```

### main Section
LOGFILE: The file to monitor
COOLDOWN_PERIOD: Time to ignore requests after the last execution
PATTERN: Regular expression, where the first match is the identifier and the second match is passed as the path parameter.

### commands Section
It is formatted as identifier=command. The $path parameter is replaced with the path in the script.

## Sample Files
nginx-http82.conf: Configuration for nginx to save logs
log_monitor.service: Configuration to start from systemd

#
Masahiro Fukuda <masahif@gmail.com>
