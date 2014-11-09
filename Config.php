<?php
/**
 *	Project name: OpenNote
 * 	Author: Jacob Liscom
 *	Version: 13.10.0
**/
//Notice no include here. We need this here because we want to include this without the rest of the include tree
//Docker version of config	
	abstract class Config{
		
		/**
		 * Database details
		 */
			public static function dbConfig(){
				if(self::$injectedCoreConfig!=null)
					return self::$injectedCoreConfig;
					
				//Un-comment desired database type
					//@pdoMethod@
				return self::mysqlConfig();
				//return self::sqliteConfig();
			}

				/**
				 * sql lite
				 */
				private static function sqliteConfig(){			
					//pdo
						//Path to DB. Do not put in webdirectory without protection! If you do anyone can download your database!
						$dbName = "OpenNote.sqlite"; //relative path to sqllite db
						return new PDO(sprintf("sqlite:%s\%s",dirname(__FILE__),$dbName));
				}
				
				/**
				 * mysql
				 */
				private static function mysqlConfig(){			
					//mysql
						$dbUserName = "root";
						$dbPassword = "tacobell";
						$dbServer = "localhost";
						$dbName = "OpenNote";
						
						return new PDO(sprintf("mysql:host=%s;dbname=%s", $dbServer, $dbName), $dbUserName, $dbPassword);
				}
				
				private static $injectedCoreConfig = null;
				
				/**
				 * Setter for config
				 * @param $config - config object to inject
				 */
				public static function setInjectedCoreConfig($config){
					self::$injectedCoreConfig = $config;
				}
				
			/**
			 * Which model to use
			 */
			public static function getModel(){
				return new \model\pdo\Model(self::dbConfig());
			}
		
		/**
		 * Upload
		 */
			public static function getUploadEnabled(){
				return true;//Default: true. Allow users to upload files.
			}
			
			/**
			 * Get upload path relative to File class
			 */
				public static function getUploadPath(){
					return dirname(__FILE__)."/upload/";
				}
			
			
		/**
		 * Registration
		 */
			public static function getRegistrationEnabled(){
				return true;//Default: true. Allow users to register.
			}
			
		/**
		 * Security
		 */
			/**
			 * @return - the token life in minutes
			 */		 
		 	public static function tokenLife(){
		 		return 60;
		 	}
		 	
		/**
		 * Config
		 */
		 	/**
		 	 * @return - array to send client
		 	 */
		 	public static function getInitialConfig(){
		 		return array(
		 			"uploadEnabled" => self::getUploadEnabled(),
		 			"registrationEnabled" => self::getRegistrationEnabled()
		 		);
		 	}
				
		/**
		 * Get web root
		 */
			 public static function getWebRoot(){
			 	return str_replace("\\", "/",str_replace(realpath($_SERVER["DOCUMENT_ROOT"]),"",realpath(dirname(__FILE__))))."/";
			 }
	}
?>
