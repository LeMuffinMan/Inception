<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php"
 * and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * Database settings
 * * Secret keys
 * * Database table prefix
 * * Localized language
 * * ABSPATH
 *
 * @link https://wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Database settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', 'oelleaum_db' );

/** Database username */
define( 'DB_USER', 'mysql_user' );

/** Database password */
define( 'DB_PASSWORD', 'QIvN2vnCAZkSjcIe+fmkxjBtbPbTZDPcbREt2boovlE' );

/** Database hostname */
define( 'DB_HOST', 'mariadb:3306' );

/** Database charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8' );

/** The database collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

define( 'WP_REDIS_HOST', 'redis')

define( 'WP_REDIS_POST', 6379)

/**#@+
 * Authentication unique keys and salts.
 *
 * Change these to different unique phrases! You can generate these using
 * the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}.
 *
 * You can change these at any point in time to invalidate all existing cookies.
 * This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',          'IV|,aOJu/sCo^aeldnL4jX,>Fm}_G$*:* ggJUb97^qwepuU,F,O}E$;hx9j#&6,' );
define( 'SECURE_AUTH_KEY',   '4o>~]J*9_X7md^6mlb|g4U3Pa?CTI2}0|0,}MXiPryz%Z()VY$s ^ss=gL%.882e' );
define( 'LOGGED_IN_KEY',     '9jSR@#t^m|?jpt)iI3Ws2[9-8%I5S$$gfpuNM2R,2GCu54l$#2oGj:oOTd}0n+9e' );
define( 'NONCE_KEY',         'i~mn>r`y0YKedzQ(Gq~BZk|1X,L#Bs*C]_AlC$c6!d(T}n^ksqZnB. bTl6Vfs]>' );
define( 'AUTH_SALT',         ' y( uogH3_Ck7`45j(T,8/%>Z[.`7-;1JU%^3Nw6UiFItUnuy79.*03z6T2:[kDa' );
define( 'SECURE_AUTH_SALT',  'J0]$i]Q$}T&z}tHEVCgVuf@(IL+yDYB!IVai$=Xan{=4)?X`UJe8QM}+2/;.7wb-' );
define( 'LOGGED_IN_SALT',    'fq$+y>N1*TKPkkCpal8svoN~u O{Z.(}^`0a0n=[1R0ky~E( ]C(Udq{z9#9OREF' );
define( 'NONCE_SALT',        'lH: E4SCGf<3I`bY38;%vfpz*1]1),W6zXhw!W}=yM8NfWn[N@TAzUOpg;Rn^a=*' );
define( 'WP_CACHE_KEY_SALT', 'fyxe[@G<} %eTr0~9SU}3I_&DFb{,hG?<vh+|Q2KjS){;P`j5y]HSf_z/ll~VRq3' );


/**#@-*/

/**
 * WordPress database table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';


/* Add any custom values between this line and the "stop editing" line. */



/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the documentation.
 *
 * @link https://wordpress.org/support/article/debugging-in-wordpress/
 */
if ( ! defined( 'WP_DEBUG' ) ) {
	define( 'WP_DEBUG', false );
}

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
