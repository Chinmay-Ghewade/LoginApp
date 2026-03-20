package db;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class DBConnection {

    private static String url;
    private static String userName;
    private static String password;
    private static String driver;

    static {
        try {
            String tomcatHome = System.getProperty("catalina.home");
            File configFile   = new File(tomcatHome + "/conf/cbs_database.conf");

            Properties props = new Properties();
            props.load(new FileInputStream(configFile));

            driver   = props.getProperty("driver");
            url      = props.getProperty("dbURL");
            userName = props.getProperty("userName");
            password = props.getProperty("password");

            Class.forName(driver);

            System.out.println("✅ DB config loaded from: " + configFile.getAbsolutePath());

        } catch (IOException e) {
            throw new RuntimeException("❌ Cannot read database.conf from TOMCAT_HOME/conf/", e);
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("❌ Oracle JDBC driver not found. Place ojdbc8.jar in TOMCAT_HOME/lib/", e);
        }
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(url, userName, password);
    }
}