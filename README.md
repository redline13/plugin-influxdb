# plugin-influxdb

https://www.redline13.com/blog/2016/11/gathering-stats-with-influxdb-plugin

### How this works on Load Agent

- On test startup make sure all the required parts are available and configured
	- telegraf installation (v1.1.1)
	- Jolokia (v1.3.5) installation

- Confiure telegraph for inputs
	- Enable Jolokia and configure
	- Enable Graphite Listener on port 2003

- Configure telegraph for user settings
	- Retrieve the DB and Influx Host config settings
	- Update /etc/telegraf/telegraf.conf

- Implement test_start()
	- After the process (JMeter) is started a plugin can act, start jolokia agent to attach to JMeter process

At this point the agent is running the test and reporting metrics through to the influxDB endpoint.


![Architecture picture](https://d1u7j79bg1ays7.cloudfront.net/blog/wp-content/uploads/2016/11/RedLine13-InfluxDB-Architecture.jpg)
