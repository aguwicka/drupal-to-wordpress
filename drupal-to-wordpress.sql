# STEP-1 Install WordPress using normal install process. Set up multisite, but don't create other sites yet
# This assumes that WordPress and Drupal are in separate databases, named `wordpress` and `drupal`.

# STEP-2 Run the following script to migrate pages & users.
TRUNCATE TABLE wordpress.wp_comments;
TRUNCATE TABLE wordpress.wp_links;
TRUNCATE TABLE wordpress.wp_postmeta;
TRUNCATE TABLE wordpress.wp_posts;
TRUNCATE TABLE wordpress.wp_term_relationships;
TRUNCATE TABLE wordpress.wp_term_taxonomy;
TRUNCATE TABLE wordpress.wp_terms;


DELETE FROM wordpress.wp_users WHERE ID > 1;
DELETE FROM wordpress.wp_usermeta WHERE user_id > 1;

INSERT INTO wordpress.wp_posts
	(id, post_author, post_date, post_content, post_title, post_excerpt,
	post_name, post_modified, post_type, `post_status`)
	SELECT DISTINCT
		n.nid `id`,
		n.uid `post_author`,
		FROM_UNIXTIME(n.created) `post_date`,
		r.body `post_content`,
		n.title `post_title`,
		r.teaser `post_excerpt`,
		IF(SUBSTR(a.dst, 11, 1) = '/', SUBSTR(a.dst, 12), a.dst) `post_name`,
		FROM_UNIXTIME(n.changed) `post_modified`,
		n.type `post_type`,
		IF(n.status = 1, 'publish', 'private') `post_status`
	FROM drupal.node n
	INNER JOIN drupal.node_revisions r
		USING(vid)
	LEFT OUTER JOIN drupal.url_alias a
		ON a.src = CONCAT('node/', n.nid)
	# Add more Drupal content types below if applicable.
	WHERE n.type IN ('page')
;

UPDATE wordpress.wp_posts SET post_content = REPLACE(post_content, '"/files/', '"/wp-content/uploads/');

INSERT IGNORE INTO wordpress.wp_users
	(ID, user_login, user_pass, user_nicename, user_email,
	user_registered, user_activation_key, user_status, display_name)
	SELECT DISTINCT
		u.uid, u.name, NULL, u.name, u.mail,
		FROM_UNIXTIME(created), '', 0, u.name
	FROM drupal.users u
	INNER JOIN drupal.users_roles r
		USING (uid)
	WHERE (1
		# Uncomment and enter any email addresses you want to exclude below.
		# AND u.mail NOT IN ('test@example.com')
	)
;

INSERT IGNORE INTO wordpress.wp_usermeta (user_id, meta_key, meta_value)
	SELECT DISTINCT
		u.uid, 'wp_capabilities', 'a:1:{s:6:"author";s:1:"1";}'
	FROM drupal.users u
	INNER JOIN drupal.users_roles r
		USING (uid)
	WHERE (1
		# Uncomment and enter any email addresses you want to exclude below.
		# AND u.mail NOT IN ('test@example.com')
	)
;
INSERT IGNORE INTO wordpress.wp_usermeta (user_id, meta_key, meta_value)
	SELECT DISTINCT
		u.uid, 'wp_user_level', '2'
	FROM drupal.users u
	INNER JOIN drupal.users_roles r
		USING (uid)
	WHERE (1
		# Uncomment and enter any email addresses you want to exclude below.
		# AND u.mail NOT IN ('test@example.com')
	)
;

UPDATE wordpress.wp_usermeta
	SET meta_value = 'a:1:{s:13:"administrator";s:1:"1";}'
	WHERE user_id IN (1) AND meta_key = 'wp_capabilities'
;
UPDATE wordpress.wp_usermeta
	SET meta_value = '10'
	WHERE user_id IN (1) AND meta_key = 'wp_user_level'
;

UPDATE wordpress.wp_posts
	SET post_author = NULL
	WHERE post_author NOT IN (SELECT DISTINCT ID FROM wordpress.wp_users)
;

UPDATE wordpress.wp_posts
	SET post_name =
	REVERSE(SUBSTRING(REVERSE(post_name),1,LOCATE('/',REVERSE(post_name))-1))
;

UPDATE wordpress.wp_posts
	SET post_content = REPLACE(post_content,'<p>&nbsp;</p>','')
;
UPDATE wordpress.wp_posts
	SET post_content = REPLACE(post_content,'<p class="italic">&nbsp;</p>','')
;

# STEP-3 If other sites need to be migrated, create those via WP UI

# STEP-4 Run the following script, assuming your next drupal site DB is `drupal_2` &
# WP is still `wordpress` (which shouldn't change).

# Empty previous content from WordPress database.
TRUNCATE TABLE wordpress.wp_2_comments;
TRUNCATE TABLE wordpress.wp_2_links;
TRUNCATE TABLE wordpress.wp_2_postmeta;
TRUNCATE TABLE wordpress.wp_2_posts;
TRUNCATE TABLE wordpress.wp_2_term_relationships;
TRUNCATE TABLE wordpress.wp_2_term_taxonomy;
TRUNCATE TABLE wordpress.wp_2_terms;


INSERT INTO wordpress.wp_2_posts
	(id, post_author, post_date, post_content, post_title, post_excerpt,
	post_name, post_modified, post_type, `post_status`)
	SELECT DISTINCT
		n.nid `id`,
		n.uid `post_author`,
		FROM_UNIXTIME(n.created) `post_date`,
		r.body `post_content`,
		n.title `post_title`,
		r.teaser `post_excerpt`,
		IF(SUBSTR(a.dst, 11, 1) = '/', SUBSTR(a.dst, 12), a.dst) `post_name`,
		FROM_UNIXTIME(n.changed) `post_modified`,
		n.type `post_type`,
		IF(n.status = 1, 'publish', 'private') `post_status`
	FROM drupal_2.node n
	INNER JOIN drupal_2.node_revisions r
		USING(vid)
	LEFT OUTER JOIN drupal_2.url_alias a
		ON a.src = CONCAT('node/', n.nid)
	# Add more Drupal content types below if applicable.
	WHERE n.type IN ('page')
;

UPDATE wordpress.wp_2_posts SET post_content = REPLACE(post_content, '"/files/', '"/wp-content/uploads/');

INSERT IGNORE INTO wordpress.wp_usermeta (user_id, meta_key, meta_value)
	SELECT DISTINCT
		u.uid, 'wp_2_capabilities', 'a:1:{s:6:"author";s:1:"1";}'
	FROM drupal_2.users u
	INNER JOIN drupal_2.users_roles r
		USING (uid)
	WHERE (1
		# Uncomment and enter any email addresses you want to exclude below.
		# AND u.mail NOT IN ('test@example.com')
	)
;
INSERT IGNORE INTO wordpress.wp_usermeta (user_id, meta_key, meta_value)
	SELECT DISTINCT
		u.uid, 'wp_2_user_level', '2'
	FROM drupal_2.users u
	INNER JOIN drupal_2.users_roles r
		USING (uid)
	WHERE (1
		# Uncomment and enter any email addresses you want to exclude below.
		# AND u.mail NOT IN ('test@example.com')
	)
;

UPDATE wordpress.wp_usermeta
	SET meta_value = 'a:1:{s:13:"administrator";s:1:"1";}'
	WHERE user_id IN (1) AND meta_key = 'wp_2_capabilities'
;
UPDATE wordpress.wp_usermeta
	SET meta_value = '10'
	WHERE user_id IN (1) AND meta_key = 'wp_2_user_level'
;

UPDATE wordpress.wp_2_posts
	SET post_author = NULL
	WHERE post_author NOT IN (SELECT DISTINCT ID FROM wordpress.wp_users)
;

UPDATE wordpress.wp_2_posts
	SET post_name =
	REVERSE(SUBSTRING(REVERSE(post_name),1,LOCATE('/',REVERSE(post_name))-1))
;

UPDATE wordpress.wp_2_posts
	SET post_content = REPLACE(post_content,'<p>&nbsp;</p>','')
;
UPDATE wordpress.wp_2_posts
	SET post_content = REPLACE(post_content,'<p class="italic">&nbsp;</p>','')
;

# STEP-5 Repeat 3/4 replacing the _2 with your new site ID.
