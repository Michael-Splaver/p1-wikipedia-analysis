CREATE DATABSE wikimedia_dumps_db
USE wikimedia_dumps_db

--Q1 Which English wikipedia article got the most traffic on October 20?
CREATE EXTERNAL TABLE pageviews_oct_20(
    domain_code STRING,
    page_title STRING,
    count_views INT,
    total_response_size INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ' '
LOCATION '/user/nat/input/pageviews-oct-20';

INSERT OVERWRITE DIRECTORY '/user/nat/output/pageviews-oct-20-title'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
SELECT page_title, sum(count_views) as page_views
FROM pageviews_oct_20
WHERE domain_code = 'en' OR domain_code = 'en.m'
GROUP BY page_title
ORDER BY page_views DESC;

CREATE EXTERNAL TABLE pageviews_oct_20_title(
    page_title STRING,
    count_views INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/user/nat/output/pageviews-oct-20-title';

-- Q2. What wikipedia article has the largest fraction of its readers follow an internal link to another wikipedia article?
--NOTE: used data from August (clickstream and pageviews)
CREATE EXTERNAL TABLE clickstream(
    referrer STRING,
    referred STRING,
    type STRING,
    count INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/user/nat/input/clickstream';

INSERT OVERWRITE DIRECTORY '/user/nat/output/clickstream-referrer'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
SELECT referrer, sum(count) AS link_count
FROM clickstream
WHERE type='link'
GROUP BY referrer
ORDER BY link_count DESC;

CREATE EXTERNAL TABLE clickstream_referrer(
    referrer STRING,
    link_count INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/user/nat/output/clickstream-referrer';

CREATE EXTERNAL TABLE pageviews_aug(
    domain_code STRING,
    page_title STRING,
    count_views INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ' '
LOCATION '/user/nat/input/pageviews-aug';

INSERT OVERWRITE DIRECTORY '/user/nat/output/pageviews-aug-title'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
SELECT page_title, sum(count_views) as page_views
FROM pageviews_aug
WHERE domain_code = 'en' OR domain_code = 'en.m' OR domain_code = 'en.z'
GROUP BY page_title
ORDER BY page_views DESC;

CREATE EXTERNAL TABLE pageviews_aug_title(
    page_title STRING,
    count_views INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/user/nat/output/pageviews-aug-title';

INSERT OVERWRITE DIRECTORY '/user/nat/output/links-per-view'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
SELECT pageviews.page_title, clickstream.link_count, pageviews.count_views, round(clickstream.link_count/pageviews.count_views,2) as links_clicked_per_view
FROM pageviews_aug_title AS pageviews
INNER JOIN clickstream_referrer AS clickstream
ON pageviews.page_title = clickstream.referrer
WHERE pageviews.count_views > 1000
ORDER BY links_clicked_per_view DESC;

--3. What series of wikipedia articles, starting with [Hotel California](https://en.wikipedia.org/wiki/Hotel_California),
-- keeps the largest fraction of its readers clicking on internal links?
-- This is similar to (2), but you should continue the analysis past the first article.
--NOTE: used data from August (clickstream and pageviews)
SELECT clickstream.referrer, clickstream.referred, round((clickstream.count/pageviews.count_views)*100,2) as percentage_clickthrough
FROM pageviews_aug_title AS pageviews
INNER JOIN clickstream
ON pageviews.page_title = clickstream.referrer
WHERE pageviews.page_title = 'Hotel_California'
ORDER BY percentage_clickthrough DESC
LIMIT 5; -- 100%

SELECT clickstream.referrer, clickstream.referred, round((clickstream.count/pageviews.count_views)*100,2) as percentage_clickthrough
FROM pageviews_aug_title AS pageviews
INNER JOIN clickstream
ON pageviews.page_title = clickstream.referrer
WHERE pageviews.page_title = 'Hotel_California_(Eagles_album)'
ORDER BY percentage_clickthrough DESC
LIMIT 5; -- 100% * 3.88% = 3.88%

SELECT clickstream.referrer, clickstream.referred, round((clickstream.count/pageviews.count_views)*100,2) as percentage_clickthrough
FROM pageviews_aug_title AS pageviews
INNER JOIN clickstream
ON pageviews.page_title = clickstream.referrer
WHERE pageviews.page_title = 'The_Long_Run_(album)'
ORDER BY percentage_clickthrough DESC
LIMIT 5; -- 3.88% * 8.07% = 0.31%

SELECT clickstream.referrer, clickstream.referred, round((clickstream.count/pageviews.count_views)*100,2) as percentage_clickthrough
FROM pageviews_aug_title AS pageviews
INNER JOIN clickstream
ON pageviews.page_title = clickstream.referrer
WHERE pageviews.page_title = 'Eagles_Live'
ORDER BY percentage_clickthrough DESC
LIMIT 5; --0.31% * 12.57% = 0.039%

SELECT clickstream.referrer, clickstream.referred, round((clickstream.count/pageviews.count_views)*100,2) as percentage_clickthrough
FROM pageviews_aug_title AS pageviews
INNER JOIN clickstream
ON pageviews.page_title = clickstream.referrer
WHERE pageviews.page_title = 'Eagles_Greatest_Hits,_Vol._2'
ORDER BY percentage_clickthrough DESC
LIMIT 5; --0.039% * 27.25% = 0.011%

--4. Find an example of an english wikipedia article that is relatively more popular in the UK.
-- Find the same for the US and Australia.
--NOTE: used data from October 20th 
--Assuming 8am - 7pm are the most active hours
-- 14 UTC - 1 UTC = US CENTRAL
-- 8 UTC - 19 UTC = UK TIME
-- 21 UTC - 8 UTC = AUS TIME (AEDT)

--US
CREATE EXTERNAL TABLE pageviews_oct_20_us(
    domain_code STRING,
    page_title STRING,
    count_views INT,
    total_response_size INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ' '
LOCATION '/user/nat/input/pageviews-oct-20-us';

INSERT OVERWRITE DIRECTORY '/user/nat/output/pageviews-oct-20-us-title'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
SELECT page_title, sum(count_views) as page_views
FROM pageviews_oct_20_us
WHERE domain_code = 'en' OR domain_code = 'en.m'
GROUP BY page_title
ORDER BY page_views DESC;

CREATE EXTERNAL TABLE pageviews_oct_20_us_title(
    page_title STRING,
    count_views INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/user/nat/output/pageviews-oct-20-us-title';

INSERT OVERWRITE DIRECTORY '/user/nat/output/pageviews-oct-20-us-percent-title'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
SELECT pageviews.page_title, pageviews.count_views, totalpageviews.count_views, round((pageviews.count_views/totalpageviews.count_views)*100,2) as percent_during_US_hours
FROM pageviews_oct_20_us_title AS pageviews
INNER JOIN pageviews_oct_20_title AS totalpageviews
ON pageviews.page_title = totalpageviews.page_title
WHERE pageviews.count_views > 1000
ORDER BY percent_during_US_hours DESC;

CREATE EXTERNAL TABLE pageviews_oct_20_us_percent_title(
    page_title STRING,
    count_views INT,
    total_count_views INT,
    percent_during_US_hours DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/user/nat/output/pageviews-oct-20-us-percent-title';

--UK
CREATE EXTERNAL TABLE pageviews_oct_20_uk(
    domain_code STRING,
    page_title STRING,
    count_views INT,
    total_response_size INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ' '
LOCATION '/user/nat/input/pageviews-oct-20-uk';

INSERT OVERWRITE DIRECTORY '/user/nat/output/pageviews-oct-20-uk-title'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
SELECT page_title, sum(count_views) as page_views
FROM pageviews_oct_20_uk
WHERE domain_code = 'en' OR domain_code = 'en.m'
GROUP BY page_title
ORDER BY page_views DESC;

CREATE EXTERNAL TABLE pageviews_oct_20_uk_title(
    page_title STRING,
    count_views INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/user/nat/output/pageviews-oct-20-uk-title';

INSERT OVERWRITE DIRECTORY '/user/nat/output/pageviews-oct-20-uk-percent-title'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
SELECT pageviews.page_title, pageviews.count_views, totalpageviews.count_views, round((pageviews.count_views/totalpageviews.count_views)*100,2) as percent_during_UK_hours
FROM pageviews_oct_20_uk_title AS pageviews
INNER JOIN pageviews_oct_20_title AS totalpageviews
ON pageviews.page_title = totalpageviews.page_title
WHERE pageviews.count_views > 1000
ORDER BY percent_during_UK_hours DESC;

CREATE EXTERNAL TABLE pageviews_oct_20_uk_percent_title(
    page_title STRING,
    count_views INT,
    total_count_views INT,
    percent_during_UK_hours DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/user/nat/output/pageviews-oct-20-uk-percent-title';

--AUS (HAS TOO MUCH OF AN OVERLAP WITH LATE NIGHT USA HOURS TO GET USEFUL INFORMATION)
CREATE EXTERNAL TABLE pageviews_oct_20_aus(
    domain_code STRING,
    page_title STRING,
    count_views INT,
    total_response_size INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ' '
LOCATION '/user/nat/input/pageviews-oct-20-aus';

INSERT OVERWRITE DIRECTORY '/user/nat/output/pageviews-oct-20-aus-title'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
SELECT page_title, sum(count_views) as page_views
FROM pageviews_oct_20_aus
WHERE domain_code = 'en' OR domain_code = 'en.m'
GROUP BY page_title
ORDER BY page_views DESC;

CREATE EXTERNAL TABLE pageviews_oct_20_aus_title(
    page_title STRING,
    count_views INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/user/nat/output/pageviews-oct-20-aus-title';

INSERT OVERWRITE DIRECTORY '/user/nat/output/pageviews-oct-20-aus-percent-title'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
SELECT pageviews.page_title, pageviews.count_views, totalpageviews.count_views, round((pageviews.count_views/totalpageviews.count_views)*100,2) as percent_during_AUS_hours
FROM pageviews_oct_20_aus_title AS pageviews
INNER JOIN pageviews_oct_20_title AS totalpageviews
ON pageviews.page_title = totalpageviews.page_title
WHERE pageviews.count_views > 1000
ORDER BY percent_during_AUS_hours DESC;

CREATE EXTERNAL TABLE pageviews_oct_20_aus_percent_title(
    page_title STRING,
    count_views INT,
    total_count_views INT,
    percent_during_AUS_hours DOUBLE
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/user/nat/output/pageviews-oct-20-aus-percent-title';

--5. Analyze how many users will see the average vandalized wikipedia page before the offending edit is reversed.
--NOTE: used data from August
CREATE EXTERNAL TABLE wiki_history(
    wiki_db STRING, 
    event_entity STRING,
    event_type STRING,
    event_timestamp STRING,
    event_comment STRING,
    event_user_id BIGINT,
    event_user_text_historical STRING,
    event_user_text STRING,
    event_user_blocks_historical STRING,
    event_user_blocks ARRAY<STRING>,
    event_user_groups_historical ARRAY<STRING>,
    event_user_groups ARRAY<STRING>,
    event_user_is_bot_by_historical ARRAY<STRING>,
    event_user_is_bot_by ARRAY<STRING>,
    event_user_is_created_by_self BOOLEAN,
    event_user_is_created_by_system BOOLEAN,
    event_user_is_created_by_peer BOOLEAN,
    event_user_is_anonymous BOOLEAN,
    event_user_registration_timestamp STRING,
    event_user_creation_timestamp STRING,
    event_user_first_edit_timestamp STRING,
    event_user_revision_count BIGINT,
    event_user_seconds_since_previous_revision BIGINT,
    page_id BIGINT,
    page_title_historical STRING,
    page_title STRING,
    page_namespace_historical INT,
    page_namespace_is_content_historical BOOLEAN,
    page_namespace INT,
    page_namespace_is_content BOOLEAN,
    page_is_redirect BOOLEAN,
    page_is_deleted BOOLEAN,
    page_creation_timestamp STRING,
    page_first_edit_timestamp STRING,
    page_revision_count BIGINT,
    page_seconds_since_previous_revision BIGINT,
    user_id BIGINT,
    user_text_historical STRING,
    user_text STRING,
    user_blocks_historical ARRAY<STRING>,
    user_blocks ARRAY<STRING>,
    user_groups_historical ARRAY<STRING>,
    user_groups ARRAY<String>,
    user_is_bot_by_historical ARRAY<STRING>,
    user_is_bot_by Array<STRING>,
    user_is_created_by_self BOOLEAN,
    user_is_created_by_system BOOLEAN,
    user_is_created_by_peer BOOLEAN,
    user_is_anonymous BOOLEAN,
    user_registration_timestamp STRING,
    user_creation_timestamp STRING,
    user_first_edit_timestamp STRING,
    revision_id BIGINT,
    revision_parent_id BIGINT,
    revision_minor_edit BOOLEAN,
    revision_deleted_parts Array<STRING>,
    revision_deleted_parts_are_suppressed BOOLEAN,
    revision_text_bytes BIGINT,
    revision_text_bytes_diff BIGINT,
    revision_text_sha1 STRING,
    revision_content_model STRING,
    revision_content_format STRING,
    revision_is_deleted_by_page_deletion BOOLEAN,
    revision_deleted_by_page_deletion_timestamp STRING,
    revision_is_identity_reverted BOOLEAN,
    revision_first_identity_reverting_revision_id BIGINT,
    revision_seconds_to_identity_revert BIGINT,
    revision_is_identity_revert BOOLEAN,
    revision_is_from_before_page_creation BOOLEAN,
    revision_tags Array<STRING>
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/user/nat/input/wiki-history';

INSERT OVERWRITE DIRECTORY '/user/nat/output/longest-reverted'
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
SELECT event_entity, event_timestamp, page_title, revision_is_identity_reverted, revision_seconds_to_identity_revert
FROM wiki_history
WHERE event_entity = 'revision' AND revision_is_identity_reverted IS true
ORDER BY revision_seconds_to_identity_revert DESC;

CREATE EXTERNAL TABLE wiki_history_longest_reverted(
    event_entity STRING, 
    event_timestamp STRING, 
    page_title STRING, 
    revision_is_identity_reverted BOOLEAN, 
    revision_seconds_to_identity_revert BIGINT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY '\t'
LOCATION '/user/nat/output/longest-reverted';

SELECT round(avg(revision_seconds_to_identity_revert),2) AS average_to_revert
FROM wiki_history_longest_reverted; --AVERAGE LIFE: 452,388.48 seconds = 5.24 days average

SELECT sum(count_views) as total_page_views
FROM pageviews_aug
WHERE domain_code = 'en' OR domain_code = 'en.m' OR domain_code = 'en.z';
--TOTAL VIEWS AUG: 7,393,968,615 views = 238,515,116.61 views/day

SELECT count(*) as total_pages
FROM pageviews_aug
WHERE domain_code = 'en' OR domain_code = 'en.m' OR domain_code = 'en.z'; 
--TOTAL PAGES: 16,139,856
--TOTAL VIEWS PER DAY PER PAGE =  238,515,116.61 / 16,139,856 = 14.78 views/day on each page
-- 14.78 views/day 5.24 days = 77.45 views before vandalized edit is reversed

--6. Run an analysis you find interesting on the wikipedia datasets we're using.
--FIND THE USER WITH THE MOST REVISIONS
SELECT event_user_text AS username, max(event_user_revision_count) AS revisions
FROM wiki_history
GROUP BY event_user_text
ORDER BY revisions DESC
LIMIT 10; --Ser Amantio di Nicolao