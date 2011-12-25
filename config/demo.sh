# Where to store backup
BACKUP_DIR=${HOME}/backup

# OpenDJ installation properties
OPENDJ_ARCHIVE=${HOME}/download/OpenDJ-2.4.4.zip
OPENDJ_EXTRACT_DIR=${HOME}/tools
OPENDJ_VERSION="2.4.4"

OPENDJ_BASEDN="dc=example,dc=com"
OPENDJ_PORT="50389"
OPENDJ_ROOT_PASSWORD="adminwelcome42"
OPENDJ_ADMIN_PORT="4444"
OPENDJ_JMX_PORT="1689"

# OpenAM installation properties
OPENAM_DATASTORE=opendj
OPENAM_ARCHIVE=${HOME}/download/openam_954.zip
OPENAM_EXTRACT_DIR=${HOME}/tools
OPENAM_ADMIN_TOOLS_DIR=${HOME}/tools/openam-admin
OPENAM_CONFIG_TOOLS_DIR=${HOME}/tools/openam-configurator

OPENAM_DATA_DIR=${HOME}/data

OPENAM_SERVER_URL=http://openam-ai.opencsi.com:8080
OPENAM_DEPLOYMENT_URI=/opensso
OPENAM_ADMIN_PASSWORD=adminwelcome42
OPENAM_URLAGENT_PASSWORD=password
OPENAM_COOKIE_DOMAIN=.opencsi.com

# Change this value to 0 if the j2ee server is already running when executing the script
J2EE_NEED_TO_START=1
J2EE_DEPLOY_DIR=${HOME}/tools/apache-tomcat-6.0.35/webapps/
J2EE_START_CMD="${HOME}/tools/apache-tomcat-6.0.35/bin/startup.sh"
J2EE_STOP_CMD="${HOME}/tools/apache-tomcat-6.0.35/bin/shutdown.sh"
J2EE_URL_START=${OPENAM_SERVER_URL}${OPENAM_DEPLOYMENT_URI}

# Internal configuration, untouch them unless you know what are you doing
OPENAM_WAR=opensso/deployable-war/opensso.war
OPENAM_CONFIG_TOOLS_ARCHIVE=opensso/tools/ssoConfiguratorTools.zip
OPENAM_ADMIN_TOOLS_ARCHIVE=opensso/tools/ssoAdminTools.zip