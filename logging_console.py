# Horodate les logs écrits sur stderr (/var/log/<appli>/stderr.log)
LOGGING['formatters']['console'] = {
    'format': '%(asctime)s %(levelname)s %(name)s %(message)s',
    'datefmt': '%Y-%m-%d %H:%M:%S',
}
LOGGING['handlers']['console']['formatter'] = 'console'

# Sans /dev/log dans le conteneur, hobo retire le handler syslog : les logs
# applicatifs (connecteurs, etc.) sont perdus. On les envoie sur stderr au
# niveau INFO, comme le syslog de prod.
LOGGING['handlers']['console_app'] = {
    'level': 'INFO',
    'class': 'logging.StreamHandler',
    'formatter': 'console',
}
LOGGING['loggers']['']['handlers'].append('console_app')
