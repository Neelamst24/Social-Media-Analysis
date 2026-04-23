-- OBJECTIVE QUESTIONS 
use ig_clone;
-- Q1 Are there any tables with duplicate or missing null values? If so, how would you handle them?
  --  checking duplicates in users tables 
   select id,username,created_at from users
   group by id,username,created_at
   having count(*)>1;
   
   -- checking null values in users table
   select * from users
   where username is null
   or id is null 
   or created_at is null;
   
   -- Table photos

SELECT user_id, image_url, COUNT(*) AS count
FROM photos
GROUP BY user_id, image_url
HAVING COUNT(*) > 1;

SELECT * FROM photos
WHERE image_url IS NULL OR user_id IS NULL OR created_dat IS NULL;

-- Table Comments

SELECT user_id, photo_id, comment_text, COUNT(*) AS count
FROM comments
GROUP BY user_id, photo_id, comment_text
HAVING COUNT(*) > 1;

SELECT * FROM comments
WHERE comment_text IS NULL OR user_id IS NULL OR photo_id IS NULL OR created_at IS NULL;

-- Table Likes

SELECT user_id, photo_id, COUNT(*) AS count
FROM likes
GROUP BY user_id, photo_id
HAVING COUNT(*) > 1;

SELECT * FROM likes
WHERE user_id IS NULL OR photo_id IS NULL OR created_at IS NULL;

-- Table Follows 

SELECT follower_id, followee_id, COUNT(*) AS count
FROM follows
GROUP BY follower_id, followee_id
HAVING COUNT(*) > 1;

SELECT * FROM follows
WHERE follower_id IS NULL OR followee_id IS NULL OR created_at IS NULL;

-- Table Photo_tags

SELECT photo_id, tag_id, COUNT(*) AS count
FROM photo_tags
GROUP BY photo_id, tag_id
HAVING COUNT(*) > 1; 

SELECT * FROM photo_tags
WHERE photo_id IS NULL OR tag_id IS NULL;
   
 -- ****************************************************************************************************  
-- Q2 What is the distribution of user activity levels (e.g., number of posts, likes, comments) across the user base?

select u.id,username,count(distinct p.id) as total_posts,
				count(distinct l.photo_id) as total_likes,
                count(distinct c.id) as total_comments
from users u left join photos p 
on u.id=p.user_id 
left join likes l on u.id=l.user_id 
left join comments c on u.id=c.user_id
group by u.id,username;
-- ***************************************************************************************************
-- Q3 Calculate the average number of tags per post (photo_tags and photos tables).

select avg(tags) as avg_num_tags from (select p.id,count(tag_id) as tags 
from photos p left join photo_tags pt 
on p.id=pt.photo_id
group by p.id) p_tag; 

-- ************************************************************************************************* 
-- Q4 Identify the top users with the highest engagement rates (likes, comments) on their posts and rank them.

with Engagement_rank as (
select id,username,
    coalesce(round(((Total_Comments+Total_Likes)/Total_Post),2),0) as Engagement_rate
from (
	select 
		U.id,U.username,
		count(photo_id) Total_Post,
		sum(number_of_Comments) as Total_Comments,
		sum(number_of_Likes) as Total_Likes
	from users U 
    left join (
			select 
				P.user_id,P.id as Photo_id,
				count(distinct C.id) as number_of_Comments,
				count(distinct L.user_id) as number_of_Likes
			from photos P 
			left join comments C on P.id = C.photo_id
			left join likes L on P.id = L.photo_id
			group by P.id, user_id
) X on U.id = X.user_id
	group by U.id
) RN)
select 
	*,dense_rank() over (order by	Engagement_rate desc) as `Rank`
from Engagement_rank;


-- ******************************************************************************************************
-- Q5 Which user has the highest number of followers and followings?

with cte1 as (select followee_id,count(follower_id) as num_followers
 from follows
 group by followee_id)
 
 ,cte2 as (select follower_id,count(followee_id) as num_followings
 from follows
 group by follower_id)
 
 select username,coalesce(num_followers,0) as num_followers,coalesce(num_followings,0) as num_followings
 from users u left join cte1 on u.id=cte1.followee_id
 left join cte2 on u.id=cte2.follower_id
 order by num_followers desc,num_followings desc;
-- ****************************************************************************************************
-- Q6 Calculate the average engagement rate (likes, comments) per post for each user.
select 
		username,
        coalesce(p.num_posts,0) as num_posts,
        coalesce(l.num_likes,0) as num_likes,
        coalesce(c.num_cmmnts,0) as num_cmmnts,
        case 
			when coalesce(p.num_posts,0)= 0 then 0 
            else (coalesce(l.num_likes,0)+coalesce(c.num_cmmnts,0))/coalesce(p.num_posts,0)
            end as avg_engagement_rate
from users u 
left join (select user_id,count(*) as num_posts from photos
			group by user_id) p on u.id=p.user_id
left join (select user_id,count(*) as num_likes from likes 
			group by user_id) l on u.id=l.user_id
left join (select user_id,count(*) as num_cmmnts from comments 
			group by user_id) c on u.id=c.user_id
order by avg_engagement_rate desc;

 -- *************************************************************************        
-- Q7 Get the list of users who have never liked any post (users and likes tables)
select id,username from users u 
where id not in (select distinct user_id as id 
				from likes); 
                
-- ***************************************************************************
-- Q8 How can you leverage user-generated content (posts, hashtags, photo tags) to create more personalized and engaging ad campaigns?
select tag_name,count(tag_name) as num_post_taged
From (select u.id,username,tag_name,photo_id from users u
join photos p on u.id=p.user_id 
join photo_tags pt on pt.photo_id=p.id
join tags t on pt.tag_id=t.id) rs
group by tag_name
order by num_post_taged desc
;
-- *********************************************************************************

-- Q9 Are there any correlations between user activity levels and specific content types (e.g., photos, videos, reels)? How can this information guide content creation and curation strategies?

select 
	T.id,
    T.tag_name,
    count(distinct P.id) as Posts_count,
    count(distinct C.id) as Total_Comments,
    count(distinct L.user_id,L.photo_id) as Total_likes,
    round((count(distinct C.id) + count(distinct L.user_id,L.photo_id))/count(distinct P.id),2) as AVG_tag_engagement
FROM likes L
join photos P on L.photo_id = P.id
join comments C on P.id = C.photo_id
JOIN photo_tags PT ON P.id = PT.photo_id
JOIN tags T ON PT.tag_id = T.id
group by T.id,T.tag_name
order by AVG_tag_engagement desc;

-- ************************************************************************************************
-- Q10 Calculate the total number of likes, comments, and photo tags for each user.
select 
		username,
        coalesce(p2.photo_tag,0) as total_photo_tag,
        coalesce(l.num_likes,0) as total_likes,
        coalesce(c.num_cmmnts,0) as total_cmmnts        
from users u 
left join (select tag_id,count(*) as photo_tag from photo_tags
			group by tag_id) p2 on u.id=p2.tag_id
left join (select user_id,count(*) as num_likes from likes 
			group by user_id) l on u.id=l.user_id
left join (select user_id,count(*) as num_cmmnts from comments 
			group by user_id) c on u.id=c.user_id
;
-- ************************************************************************

-- Q11 Rank users based on their total engagement (likes, comments, shares) over a month.
with JulyEngagement as (select u.id as user_id,username,
        coalesce(l.total_likes,0) as total_likes,
        coalesce(c.total_cmmnts,0) as total_cmmnts,
        (coalesce(l.total_likes,0)+coalesce(c.total_cmmnts,0)) as total_engagement
from users u 
left join (
		select user_id,count(photo_id) as total_likes
				from likes
		where date(created_at)>='2024-07-01' or date(created_at)<='2024-07-31'
        group by user_id) l on u.id=l.user_id
left join (
		select user_id,count(id) as total_cmmnts
				from comments
		where date(created_at)>='2024-07-01' or date(created_at)<='2024-07-31'
        group by user_id) c on u.id=c.user_id )

select user_id,username,total_likes,total_cmmnts,total_engagement,
		rank()over(order by total_engagement desc) as engagement_rank
from JulyEngagement
order by engagement_rank;

-- ***************************************************************************************		
-- Q12 Retrieve the hashtags that have been used in posts with the highest average number of likes. Use a CTE to calculate the average likes for each hashtag first.

with avg_likes_per_hashtag as (
	select t.tag_name as hashtag,
			count(l.photo_id)/count(distinct p.id) as avg_likes
	from tags t join photo_tags pt on t.id=pt.tag_id
				join photos p on pt.photo_id=p.id 
			left join likes l on p.id=l.photo_id 
	group by t.tag_name)
    
    select hashtag,avg_likes
    from avg_likes_per_hashtag
    order by avg_likes desc 
    limit 5;

-- ***************************************************************************

-- Q13 Retrieve the users who have started following someone after being followed by that person
select f1.follower_id as user_id,
		f1.followee_id as followed_user,
        f1.created_at as follow_back_time
from follows f1 join follows f2 
on f1.follower_id=f2.followee_id
and f1.followee_id=f2.follower_id
where f1.created_at > f2.created_at;

-- *******************************************************************************
-- SUBJECTIVE SOLUTIONS

-- Q_1 Based on user engagement and activity levels, which users would you consider the most loyal or valuable? How would you reward or incentivize these users?
with likes_count as (
		select user_id,count(*) as total_likes
        from likes
        group by user_id)
,
comments_count as (
		select user_id,count(id) as total_comments
        from comments
        group by user_id)
,
photo_counts as (
		select user_id,count(*) as total_post
		from photos 
        group by user_id)
,
phototags_count as (
		select p.user_id,count(distinct pt.tag_id) as total_unique_tags
        from photos p join photo_tags pt 
        on p.id=pt.photo_id
        group by p.user_id)
,
count_of_followers as (
		select follower_id,
				count(follower_id) as total_followers               
		from follows f
        group by follower_id)

select u.id as userid,
u.username,
coalesce(l.total_likes,0) as num_of_likes,
coalesce(c.total_comments,0) as num_of_comments,
coalesce(p.total_post,0) as num_of_post,
coalesce(pt.total_unique_tags,0) as unique_tags_used,
coalesce(f.total_followers,0) as total_followers,
coalesce(
	coalesce(l.total_likes,0) + coalesce(c.total_comments,0) ,0)
as total_engagement
from users u 
left join likes_count as l on u.id=l.user_id
left join comments_count as c on u.id=c.user_id
left join photo_counts as p on u.id=p.user_id
left join phototags_count as pt on u.id=pt.user_id
left join count_of_followers as f on u.id=f.follower_id
group by u.id
having num_of_post >0
order by total_engagement desc
limit 10;

-- ****************************************************************************			
-- Q_2 For inactive users, what strategies would you recommend to re-engage them and encourage them to start posting or engaging again?
 WITH user_category AS (
    SELECT 
        u.id,u.username,
        CASE 
            WHEN p.id IS NULL THEN 'Inactive User'
            ELSE 'Active User'
        END AS User_Category
         FROM users u
        LEFT JOIN photos p 
        ON u.id = p.user_id)
        SELECT
       id,
       username
FROM user_category
WHERE User_Category = 'Inactive User';
			
-- *****************************************************************************
-- Q_3 Which hashtags or content topics have the highest engagement rates? How can this information guide content strategy and ad campaigns?

 WITH Photo_Engagement AS (
   SELECT p.id AS photo_id,
        COUNT(distinct l.photo_id) AS total_likes,
        COUNT(distinct c.id) AS total_comments,
        COUNT(distinct l.photo_id) + COUNT(DISTINCT c.user_id) AS total_engagement
    FROM photos p
    LEFT JOIN likes l ON p.user_id = l.user_id
    LEFT JOIN comments c ON p.user_id = c.user_id
    GROUP BY p.id
     ),
 Hashtag_Engagement AS (
    SELECT t.id AS tag_id,
        t.tag_name,
        count(pe.total_engagement) AS total_engagement,
         COUNT(DISTINCT pt.photo_id) AS total_photos,
         (count(pe.total_engagement) / COUNT(DISTINCT pt.photo_id) )AS engagement_rate
     FROM tags t
     JOIN photo_tags pt ON t.id = pt.tag_id
   JOIN Photo_Engagement pe ON pt.photo_id = pe.photo_id
GROUP BY t.id, t.tag_name)
SELECT tag_name, total_photos, total_engagement, engagement_rate
FROM Hashtag_Engagement
ORDER BY total_engagement DESC
limit 10;

-- ********************************************************************************
-- Q_4 Are there any patterns or trends in user engagement based on demographics (age, location, gender) or posting times? How can these insights inform targeted marketing campaigns?
select 
		hour(p.created_dat) as posting_hour,
        dayname(c.created_at) as posting_day,
        count(distinct p.id) as photos_count,
        count(distinct l.photo_id) as likes_count,
        count(distinct c.id) as comments_count
from photos p 
left join likes l on p.id=l.photo_id
left join comments c on p.id=c.photo_id
group by posting_hour,posting_day
order by comments_count desc,likes_count desc;

-- **************************************************************************
-- Q_5 Based on follower counts and engagement rates, which users would be ideal candidates for influencer marketing campaigns? How would you approach and collaborate with these influencers?
WITH likes_summary AS (
    SELECT
        l.user_id,
        COUNT(DISTINCT l.photo_id) AS likes_cnt
    FROM likes l
    GROUP BY l.user_id
),
comments_summary AS (
		SELECT
        c.user_id,
        COUNT(DISTINCT c.photo_id) AS comments_cnt
    FROM comments c
    GROUP BY c.user_id
),
posts_summary AS (
    SELECT
        p.user_id,
        COUNT(p.id) AS posts_cnt
    FROM photos p
    GROUP BY p.user_id
),
followers_summary AS (
    SELECT
        fl.followee_id AS user_id,
        COUNT(fl.follower_id) AS followers_cnt
    FROM follows fl
    GROUP BY fl.followee_id
)
SELECT
    u.id AS user_id,
    u.username,
   COALESCE(l.likes_cnt, 0) AS total_likes,
    COALESCE(c.comments_cnt, 0) AS total_comments,
    COALESCE(p.posts_cnt, 0) AS total_photos_posted,
    COALESCE(f.followers_cnt, 0) AS total_followers,
    (COALESCE(l.likes_cnt, 0) + COALESCE(c.comments_cnt, 0)) 
        / COALESCE(p.posts_cnt, 0) AS engagement_rate
FROM users u
LEFT JOIN posts_summary p ON u.id = p.user_id
LEFT JOIN likes_summary l ON u.id = l.user_id
LEFT JOIN comments_summary c ON u.id = c.user_id
LEFT JOIN followers_summary f ON u.id = f.user_id
WHERE p.posts_cnt > 0
ORDER BY
    engagement_rate DESC,
    total_followers DESC,
    total_photos_posted DESC
LIMIT 10;

-- *******************************************************************

-- Q-6 Based on user behavior and engagement data, how would you segment the user base for targeted marketing campaigns or personalized recommendations?
 WITH user_activity AS (
       SELECT
        u.id AS user_id,
        u.username,
        COUNT(DISTINCT p.id) AS posts_count,
        COUNT(DISTINCT l.photo_id) AS likes_count,
        COUNT(DISTINCT c.id) AS comments_count,
        YEAR(u.created_at) AS join_year
    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON u.id = l.user_id
    LEFT JOIN comments c ON u.id = c.user_id
    GROUP BY u.id, u.username, YEAR(u.created_at)
)

SELECT
    user_id,
    username,
    posts_count AS total_posts,
    (likes_count + comments_count) AS total_engagement,
    CASE
        WHEN (likes_count + comments_count) >= 150 THEN 'High Engagement User'
        WHEN (likes_count + comments_count) >= 100 THEN 'Medium Engagement User'
        ELSE 'Low Engagement User'
    END AS engagement_segment,
    CASE
        WHEN join_year >= 2017 THEN 'Recently Joined'
        ELSE 'Early Adopter'
    END AS account_type

FROM user_activity
WHERE posts_count > 0
ORDER BY
    total_engagement DESC,
    posts_count DESC;

-- Q-7 If data on ad campaigns (impressions, clicks, conversions) is available, how would you measure their effectiveness and optimize future campaigns?
-- Q-8 How can you use user activity data to identify potential brand ambassadors or advocates who could help promote Instagram's initiatives or events?
-- Q-9 How would you approach this problem, if the objective and subjective questions weren't given?
-- Q-10 Assuming there's a "User_Interactions" table tracking user engagements, how can you update the "Engagement_Type" column to change all instances of "Like" to "Heart" to align with Instagram's terminology?
use ig_clone;
 CREATE TABLE User_Interactions(
	id INT AUTO_INCREMENT UNIQUE PRIMARY KEY,
	username VARCHAR(250) NOT NULL,
	Engagement_Type varchar(250) not null);

INSERT INTO User_Interactions (username,Engagement_Type ) VALUES 
('Kenton_Kirlin', 'Like'),
 ('Andre_Purdy85', 'Comments'), 
 ('Harley_Lind18', 'Comments'),
 ('Arely_Bogan63', 'Comments'), 
 ('Aniya_Hackett', 'Like'), 
 ('Travon.Waters', 'Like'), 
 ('Kasandra_Homenick', 'Comments'), 
 ('Tabitha_Schamberger11', 'Comments'),
 ('Gus93', 'Like'), 
 ('Presley_McClure', 'Comments'), 
 ('Justina.Gaylord27', 'Like'), 
 ('Dereck65', 'Comments'), 
 ('Alexandro35', 'Comments'), 
 ('Jaclyn81', 'Comments'), 
 ('Billy52', 'Like'), 
 ('Annalise.McKenzie16', 'Comments'), 
 ('Norbert_Carroll35', 'Like'), 
 ('Odessa2', 'Comments'), 
 ('Hailee26', 'Comments'), 
 ('Delpha.Kihn', 'Like'), 
 ('Rocio33', 'Like'), 
 ('Kenneth64', 'Like'), 
 ('Eveline95', 'Like'),
 ('Maxwell.Halvorson', 'Like'), 
 ('Tierra.Trantow', 'Like'),
 ('Josianne.Friesen', 'Like'), 
 ('Darwin29', 'Like'), 
 ('Dario77', 'Like'),
 ('Jaime53', 'Comments'),
 ('Kaley9', 'Comments'), 
 ('Aiyana_Hoeger', 'Like'), 
 ('Irwin.Larson', 'Like'), 
 ('Yvette.Gottlieb91', 'Comments'), 
 ('Pearl7', 'Like'), 
 ('Lennie_Hartmann40', 'Comments'), 
 ('Ollie_Ledner37', 'Like'), 
 ('Yazmin_Mills95', 'Comments'), 
 ('Jordyn.Jacobson2', 'Like'), 
 ('Kelsi26', 'Like'), 
 ('Rafael.Hickle2', 'Comments'), 
 ('Mckenna17', 'Like'), 
 ('Maya.Farrell', 'Comments'), 
 ('Janet.Armstrong', 'Like'), 
 ('Seth46', 'Comments'), 
 ('David.Osinski47', 'Like'), 
 ('Malinda_Streich', 'Comments'), 
 ('Harrison.Beatty50', 'Like'), 
 ('Granville_Kutch', 'Comments'), 
 ('Morgan.Kassulke', 'Like'), 
 ('Gerard79', 'Comments'), 
 ('Mariano_Koch3', 'Comments'), 
 ('Zack_Kemmer93', 'Like'), 
 ('Linnea59', 'Comments'), 
 ('Duane60', 'Comments'), 
 ('Meggie_Doyle', 'Like'), 
 ('Peter.Stehr0', 'Comments'), 
 ('Julien_Schmidt', 'Like'), 
 ('Aurelie71', 'Comments'), 
 ('Cesar93', 'Comments'), 
 ('Sam52', 'Like'), 
 ('Jayson65', 'Comments'), 
 ('Ressie_Stanton46', 'Like'), 
 ('Elenor88', 'Comments'), 
 ('Florence99', 'Like'), 
 ('Adelle96', 'Comments'), 
 ('Mike.Auer39', 'Comments'), 
 ('Emilio_Bernier52', 'Like'), 
 ('Franco_Keebler64', 'Comments'), 
 ('Karley_Bosco', 'Like'), 
 ('Erick5', 'Comments'), 
 ('Nia_Haag', 'Like'), 
 ('Kathryn80', 'Comments'), 
 ('Jaylan.Lakin', 'Like'), 
 ('Hulda.Macejkovic', 'Comments'), 
 ('Leslie67', 'Comments'), 
 ('Janelle.Nikolaus81', 'Like'), 
 ('Donald.Fritsch', 'Comments'), 
 ('Colten.Harris76', 'Like'), 
 ('Katarina.Dibbert', 'Comments'), 
 ('Darby_Herzog', 'Comments'), 
 ('Esther.Zulauf61', 'Like'), 
 ('Aracely.Johnston98', 'Comments'), 
 ('Bartholome.Bernhard', 'Comments'), 
 ('Alysa22', 'Comments'), 
 ('Milford_Gleichner42', 'Like'), 
 ('Delfina_VonRueden68', 'Comments'), 
 ('Rick29', 'Like'), 
 ('Clint27', 'Comments'), 
 ('Jessyca_West', 'Comments'), 
 ('Esmeralda.Mraz57', 'Like'), 
 ('Bethany20', 'Comments'), 
 ('Frederik_Rice', 'Comments'), 
 ('Willie_Leuschke', 'Like'), 
 ('Damon35', 'Comments'), 
 ('Nicole71', 'Comments'), 
 ('Keenan.Schamberger60', 'Like'), 
 ('Tomas.Beatty93', 'Comments'), 
 ('Imani_Nicolas17', 'Like'), 
 ('Alek_Watsica', 'Comments'), 
 ('Javonte83', 'Like');
 
 SET SQL_SAFE_UPDATES = 0;
 update  User_Interactions 
 set  Engagement_Type = "Heart" 
 where Engagement_Type= "Like";
 
  select * from User_Interactions; 