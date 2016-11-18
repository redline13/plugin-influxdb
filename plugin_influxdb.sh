
## The installation process gets called on each agent for every test run. 
## Optimize the installation to detect already installed components.
## $1 user home path
## $2 user name
function plugin_install() {

	userHome=$1
	user=$2

	## plugin_setting will parse loadtest.ini and retrieve setting, good idea to prefix your values.
	DATABASE=$(plugin_setting influxdb_db)
	HOST=$(plugin_setting influxdb_host)
	## We will use this below to modify telegraf, we need to escape the / in string.
	HOST_SA=$(sed -e 's/[]\/$*.^|[]/\\&/g' <<< $HOST)
	## If we already have telegraf, then no need.
	if [ ! -f /etc/telegraf/telegraf.conf ]; then
		## We package the DEB with the update.
		sudo dpkg -i $userHome/telegraf_1.1.1_amd64.deb

		## We package version 1.3.5 and move it into /opt/
		sudo mv $userHome/jolokia-jvm-1.3.5-agent.jar /opt/jolokia.jar
	fi
	
	## Update telegraf.conf to match our needs enabling Jolokia and turning on graphite.
	if ! grep -q "\[\[inputs.tcp_listener" /etc/telegraf/telegraf.conf ; then
		sudo sed -i -e 's/^[ ]*database = ".*"/  database = "'${DATABASE}'"/g' /etc/telegraf/telegraf.conf
        echo '
## Generic TCP listener
[[inputs.tcp_listener]]
    service_address = ":2003"
    data_format = "graphite"

## Read JMX metrics through Jolokia
  [[inputs.jolokia]]
    context = "/jolokia/"
  [[inputs.jolokia.servers]]
    name = "jmeter"
    host = "localhost"
    port = "8778"
  [[inputs.jolokia.metrics]]
    name = "heap_memory_usage"
    mbean  = "java.lang:type=Memory"
    attribute = "HeapMemoryUsage"
  [[inputs.jolokia.metrics]]
    name = "thread_count"
    mbean  = "java.lang:type=Threading"
    attribute = "TotalStartedThreadCount,ThreadCount,DaemonThreadCount,PeakThreadCount"
  [[inputs.jolokia.metrics]]
    name = "class_count"
    mbean  = "java.lang:type=ClassLoading"
    attribute = "LoadedClassCount,UnloadedClassCount,TotalLoadedClassCount"' | sudo tee -a /etc/telegraf/telegraf.conf  > /dev/null
	fi

	## Update Configuration as needed.
	sudo sed -i -e 's/^[ ]*hostname = ".*"/  hostname = "redline13-'`hostname`'"/g' /etc/telegraf/telegraf.conf
	sudo sed -i -e 's/^[ ]*urls = .*/  urls = ["'${HOST_SA}'"]/g' /etc/telegraf/telegraf.conf | grep "^[ ]*urls"

	# Restart to pick up any config changes.
	sudo service telegraf restart
	echo "FINISH PLUGIN TELEGRAF"
}

## Invoked after the core test is started
## it will pass along PID, but that pid might be a wrapper to actual process
## $1 user name
## $2 pid that is being tracked for test process.
function test_start(){
	echo "CALLED START_TEST $1 $2"
	## Only variable passed in is the home dir, this is where files are available.
	user=$1
	pid=$2
	
	## For debug to show list of pids when there is an issue
	sudo -i -u "$user" bash -c "java -jar /opt/jolokia.jar list"
	## Tell Jolokia to attach to the jmeter process
	sudo -i -u "$user" bash -c "java -jar /opt/jolokia.jar start jmeter"
}
