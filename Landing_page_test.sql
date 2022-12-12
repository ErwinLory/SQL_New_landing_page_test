-- step 1: find out when the new page "/lander-1" was launched
SELECT 
	MIN(created_at) AS first_created_at
    ,MIN(website_pageview_id) AS first_pageview_id
FROM website_pageviews
WHERE pageview_url = '/lander-1'
AND created_at IS NOT NULL;
/*
the result:
first_created_at = '2012-06-19 00:35:54'
first_pageview_id = 23504
*/

-- step 2: find the first(min) website_pageview_id for relevant session
WITH first_test_pageviews AS(
SELECT 
	website_pageviews.website_session_id
    ,MIN(website_pageviews.website_pageview_id) as min_pageview_id
FROM website_pageviews
INNER JOIN website_sessions
	ON website_sessions.website_session_id = website_pageviews.website_session_id
    AND website_sessions.created_at < '2012-07-28' -- just for limitation
    AND website_pageviews.website_pageview_id > '23504' -- min_pageview we found in step 1
    AND utm_source = 'gsearch'
    AND utm_campaign = 'nonbrand'
GROUP BY website_pageviews.website_pageview_id
),

-- step 3: identify the landing page of each session only for "/home" and "/lander-1"
nonbrand_test_sessions_w_landing_page AS(
SELECT 
	first_test_pageviews.website_session_id
    ,website_pageviews.pageview_url AS landing_page
FROM first_test_pageviews
LEFT JOIN website_pageviews
	ON website_pageviews.website_pageview_id = first_test_pageviews.min_pageview_id
WHERE website_pageviews.pageview_url IN ('/home','/lander-1')
),

-- step 4: Counting pageviews for each session to identify bounces
nonbrand_test_bounced_sessions AS(
SELECT 
	nonbrand_test_sessions_w_landing_page.website_session_id
    ,nonbrand_test_sessions_w_landing_page.landing_page
FROM nonbrand_test_sessions_w_landing_page
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = nonbrand_test_sessions_w_landing_page.website_session_id
GROUP BY 1,2
HAVING COUNT(website_pageviews.website_pageview_id) = '1'
) -- for identify bounces

-- step 5: summarizing total sessions and bounced sessions by landing page and count the rates
SELECT 
	nonbrand_test_sessions_w_landing_page.landing_page
    ,COUNT(DISTINCT nonbrand_test_sessions_w_landing_page.website_session_id) AS total_sessions
    ,COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id) AS total_bounced_sessions
    ,COUNT(DISTINCT nonbrand_test_bounced_sessions.website_session_id)/COUNT(DISTINCT nonbrand_test_sessions_w_landing_page.website_session_id) AS bounced_rates
FROM nonbrand_test_sessions_w_landing_page
LEFT JOIN nonbrand_test_bounced_sessions
	ON nonbrand_test_bounced_sessions.website_session_id = nonbrand_test_sessions_w_landing_page.website_session_id
GROUP BY 1;






