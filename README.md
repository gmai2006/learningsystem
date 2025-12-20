# Kafka
```docker run -p 9092:9092 apache/kafka-native:4.1.0```
# Postgres
## Install gis extension
1. sudo apt-get install postgresql-XX-postgis
   e.g. sudo apt-get install postgresql-16-postgis
2. sudo systemctl restart postgresql
3. Go to Postgres admin
4. ```declarative
CREATE EXTENSION postgis;
CREATE TABLE locations (
id SERIAL PRIMARY KEY,
geo GEOGRAPHY(Point, 4326),
name VARCHAR(255)
);
```

# MySQL data source
1. Download the mysql jar file from Oracle only jar file, not the bundle
2. Create MySQL Module
- Create the module directory structure in WildFly: 
> $WILDFLY_HOME/modules/com/mysql/driver/main/
- Place the MySQL JDBC JAR file in this directory and create a module.xml file:
```
<?xml version="1.0" encoding="UTF-8"?>
<module xmlns="urn:jboss:module:1.3" name="com.mysql.driver">
    <resources>
        <resource-root path="mysql-connector-java-8.0.X.jar"/>
    </resources>
    <dependencies>
        <module name="javax.api"/>
        <module name="javax.transaction.api"/>
    </dependencies>
</module>
```
**Replace mysql-connector-java-8.0.X.jar with your actual JAR filename.**

3. Connect to wildfly admin console
> ./jboss-cli.sh --connect
4. Add the driver
>/subsystem=datasources/jdbc-driver=mysql:add(driver-name=mysql,driver-module-name=com.mysql.driver,driver-class-name=com.mysql.jdbc.Driver)
5. Create the Datasource (CLI Method)Create the Datasource (CLI Method)
> data-source add --name=MySQLPool --jndi-name=java:jboss/datasources/MySQLDS --driver-name=mysql --connection-url=jdbc:mysql://localhost:3306/your_database --user-name=your_user --password=your_password
6. Test your connection
>/subsystem=datasources/data-source=MySQLPool:test-connection-in-pool
---
# Postgresql
1. Download the mysql jar file
2. Connect to wildfly admin console
> ./jboss-cli.sh --connect
3. Add the PostgreSQL module
> module add --name=org.postgres --resources=/path/to/postgresql-42.7.7.jar --dependencies=javax.api,javax.transaction.api
4. Install JDBC drive
> Install the JDBC driver
5. Create a datasource
> data-source add --jndi-name=java:jboss/datasources/PostgreSQLDS --name=PostgrePool --connection-url=jdbc:postgresql://localhost:5432/postgresdb --driver-name=postgres --user-name=postgres --password=mypassword
6. Test connection
> /subsystem=datasources/data-source=PostgrePool:test-connection-in-pool
> 
# Back up and restore the DB
```pg_dump -U username -W -h localhost database_name > backup.sql```
```pg_restore -U username -d database_name backup.dump```

# Efax
- https://stoplight.io/mocks/consensus/fax-services/33545480