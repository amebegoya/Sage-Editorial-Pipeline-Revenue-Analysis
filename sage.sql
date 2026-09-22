-- check spelling of columns
SELECT access_type, COUNT(*) as total
FROM journals
GROUP by access_type
ORDER BY total DESC;

-- cleaned journals table
WITH clean_journals AS (
	SELECT DISTINCT journal_id, journal_name,
		CASE WHEN LOWER(TRIM(subject_area)) = 'political science' THEN 'Political Science'
			 WHEN LOWER(TRIM(subject_area)) = 'sociology' THEN 'Sociology' 
   	 		 WHEN LOWER(TRIM(subject_area)) = 'psychology' THEN 'Psychology'
    		 WHEN LOWER(TRIM(subject_area)) = 'methodology' then 'Methodology'
    		 WHEN LOWER(TRIM(subject_area)) = 'management' THEN 'Management'
    		 WHEN LOWER(TRIM(subject_area)) = 'education' THEN 'Education'
 		end as clean_subject_area,
  		CASE WHEN LOWER(TRIM(access_type)) IN ('subscription', 'sub') THEN 'Subscription'
  			 WHEN LOWER(TRIM(access_type)) IN ('open access', 'oa') THEN 'Open Access'
  		END AS clean_access_type
FROM journals
)
SELECT *
FROM clean_journals;


-- cleaned reviewers table
WITH clean_reviewers AS (
SELECT DISTINCT reviewer_id, reviewer_name, field, 
	CASE WHEN LOWER(TRIM(is_active)) In ('yes', 'true', '1') THEN 1 ELSE 0 
    END AS active_clean 
FROM reviewers
)
SELECT *
FROM clean_reviewers;


-- cleaned submissions table 
with clean_submissions AS (
	SELECT DISTINCT submission_id, journal_id,
  		CASE WHEN LOWER(TRIM(decision)) IN ('rejected', 'reject', 'rej') THEN 'Reject'
  			 WHEN LOWER(TRIM(decision)) IN ('accepted', 'accept')		 THEN 'Accept'
  			 WHEN LOWER(TRIM(decision)) IN ('revise', 'r&r', 'major revision', 'minor revision') THEN 'Revise'
  	END AS clean_decision,
    CASE WHEN submitted_date LIKE '____-__-__' THEN submitted_date
  	  ELSE substr(submitted_date,7,4) || '-' || 
  		   substr(submitted_date,4,2) || '-' || 
  		   substr(submitted_date,1,2)
  	END AS submitted_clean,
  CASE WHEN decision_date LIKE '____-__-__' THEN decision_date
  	  ELSE substr(decision_date,7,4) || '-' || 
  		   substr(decision_date,4,2) || '-' || 
  		   substr(decision_date,1,2)
  	END AS decision_clean_date,
  CASE WHEN published_date LIKE '____-__-__' THEN published_date
  	  ELSE substr(published_date,7,4) || '-' || 
  		   substr(published_date,4,2) || '-' || 
  		   substr(published_date,1,2)
  	END AS published_clean,
  CAST(REPLACE(REPLACE(REPLACE(apc_amount,'$',''),'£',''),',','') AS numeric) AS apc_clean
FROM submissions
)
SELECT *
FROM clean_submissions;


-- clean subscription revenue 
WITH clean_subscription AS (
  SELECT journal_id, year, 
  	CAST(REPLACE(REPLACE(subscription_revenue_local, '£', ''), ',', '') AS numeric) AS rev_clean
FROM subscription_revenue
WHERE journal_id IN (SELECT journal_id FROM journals) AND rev_clean IS NOT NULL
)
SELECT *
FROM clean_subscription;


-- clean review_assignments
WITH clean_assignments AS (
  SELECT DISTINCT assignment_id, submission_id, reviewer_id
FROM review_assignments
WHERE reviewer_id IN (SELECT reviewer_id FROM reviewers)
)
SELECT *
FROM clean_assignments;


--  Q1: how many submissions does each journal get, and what's the decision split?
WITH clean_journals AS (
	SELECT DISTINCT journal_id, journal_name,
		CASE WHEN LOWER(TRIM(subject_area)) = 'political science' THEN 'Political Science'
			 WHEN LOWER(TRIM(subject_area)) = 'sociology' THEN 'Sociology' 
   	 		 WHEN LOWER(TRIM(subject_area)) = 'psychology' THEN 'Psychology'
    		 WHEN LOWER(TRIM(subject_area)) = 'methodology' then 'Methodology'
    		 WHEN LOWER(TRIM(subject_area)) = 'management' THEN 'Management'
    		 WHEN LOWER(TRIM(subject_area)) = 'education' THEN 'Education'
 		end as clean_subject_area,
  		CASE WHEN LOWER(TRIM(access_type)) IN ('subscription', 'sub') THEN 'Subscription'
  			 WHEN LOWER(TRIM(access_type)) IN ('open access', 'oa') THEN 'Open Access'
  		END AS clean_access_type
FROM journals
),
clean_reviewers AS (
SELECT DISTINCT reviewer_id, reviewer_name, field, 
	CASE WHEN LOWER(TRIM(is_active)) In ('yes', 'true', '1') THEN 1 ELSE 0 
    END AS active_clean 
FROM reviewers
),
clean_submissions AS (
	SELECT DISTINCT submission_id, journal_id,
  		CASE WHEN LOWER(TRIM(decision)) IN ('rejected', 'reject', 'rej') THEN 'Reject'
  			 WHEN LOWER(TRIM(decision)) IN ('accepted', 'accept')		 THEN 'Accept'
  			 WHEN LOWER(TRIM(decision)) IN ('revise', 'r&r', 'major revision', 'minor revision') THEN 'Revise'
  	END AS clean_decision,
    CASE WHEN submitted_date LIKE '____-__-__' THEN submitted_date
  	  ELSE substr(submitted_date,7,4) || '-' || 
  		   substr(submitted_date,4,2) || '-' || 
  		   substr(submitted_date,1,2)
  	END AS submitted_clean,
  CASE WHEN decision_date LIKE '____-__-__' THEN decision_date
  	  ELSE substr(decision_date,7,4) || '-' || 
  		   substr(decision_date,4,2) || '-' || 
  		   substr(decision_date,1,2)
  	END AS decision_clean_date,
  CASE WHEN published_date LIKE '____-__-__' THEN published_date
  	  ELSE substr(published_date,7,4) || '-' || 
  		   substr(published_date,4,2) || '-' || 
  		   substr(published_date,1,2)
  	END AS published_clean,
  CAST(REPLACE(REPLACE(REPLACE(apc_amount,'$',''),'£',''),',','') AS numeric) AS apc_clean
FROM submissions
),
clean_assignments AS (
  SELECT DISTINCT assignment_id, submission_id, reviewer_id
FROM review_assignments
WHERE reviewer_id IN (SELECT reviewer_id FROM reviewers)
),
clean_subscription AS (
  SELECT journal_id, year, 
  	CAST(REPLACE(REPLACE(subscription_revenue_local, '£', ''), ',', '') AS numeric) AS rev_clean
FROM subscription_revenue
WHERE journal_id IN (SELECT journal_id FROM journals) AND rev_clean IS NOT NULL
)
SELECT cj.journal_name, cs.clean_decision, COUNT(*) AS total_submissions
FROM clean_submissions cs 
JOIN clean_journals cj ON cs.journal_id = cj.journal_id
GROUP BY cj.journal_name, cs.clean_decision
ORDER BY cj.journal_name;


  -- Q2: how many days, on average, from submission to decision?
WITH clean_journals AS (
	SELECT DISTINCT journal_id, journal_name,
		CASE WHEN LOWER(TRIM(subject_area)) = 'political science' THEN 'Political Science'
			 WHEN LOWER(TRIM(subject_area)) = 'sociology' THEN 'Sociology' 
   	 		 WHEN LOWER(TRIM(subject_area)) = 'psychology' THEN 'Psychology'
    		 WHEN LOWER(TRIM(subject_area)) = 'methodology' then 'Methodology'
    		 WHEN LOWER(TRIM(subject_area)) = 'management' THEN 'Management'
    		 WHEN LOWER(TRIM(subject_area)) = 'education' THEN 'Education'
 		end as clean_subject_area,
  		CASE WHEN LOWER(TRIM(access_type)) IN ('subscription', 'sub') THEN 'Subscription'
  			 WHEN LOWER(TRIM(access_type)) IN ('open access', 'oa') THEN 'Open Access'
  		END AS clean_access_type
FROM journals
),
clean_reviewers AS (
SELECT DISTINCT reviewer_id, reviewer_name, field, 
	CASE WHEN LOWER(TRIM(is_active)) In ('yes', 'true', '1') THEN 1 ELSE 0 
    END AS active_clean 
FROM reviewers
),
clean_submissions AS (
	SELECT DISTINCT submission_id, journal_id,
  		CASE WHEN LOWER(TRIM(decision)) IN ('rejected', 'reject', 'rej') THEN 'Reject'
  			 WHEN LOWER(TRIM(decision)) IN ('accepted', 'accept')		 THEN 'Accept'
  			 WHEN LOWER(TRIM(decision)) IN ('revise', 'r&r', 'major revision', 'minor revision') THEN 'Revise'
  	END AS clean_decision,
    CASE WHEN submitted_date LIKE '____-__-__' THEN submitted_date
  	  ELSE substr(submitted_date,7,4) || '-' || 
  		   substr(submitted_date,4,2) || '-' || 
  		   substr(submitted_date,1,2)
  	END AS submitted_clean,
  CASE WHEN decision_date LIKE '____-__-__' THEN decision_date
  	  ELSE substr(decision_date,7,4) || '-' || 
  		   substr(decision_date,4,2) || '-' || 
  		   substr(decision_date,1,2)
  	END AS decision_clean_date,
  CASE WHEN published_date LIKE '____-__-__' THEN published_date
  	  ELSE substr(published_date,7,4) || '-' || 
  		   substr(published_date,4,2) || '-' || 
  		   substr(published_date,1,2)
  	END AS published_clean,
  CAST(REPLACE(REPLACE(REPLACE(apc_amount,'$',''),'£',''),',','') AS numeric) AS apc_clean
FROM submissions
),
clean_assignments AS (
  SELECT DISTINCT assignment_id, submission_id, reviewer_id
FROM review_assignments
WHERE reviewer_id IN (SELECT reviewer_id FROM reviewers)
),
clean_subscription AS (
  SELECT journal_id, year, 
  	CAST(REPLACE(REPLACE(subscription_revenue_local, '£', ''), ',', '') AS numeric) AS rev_clean
FROM subscription_revenue
WHERE journal_id IN (SELECT journal_id FROM journals) AND rev_clean IS NOT NULL
)
SELECT cj.clean_subject_area,
  ROUND(AVG(julianday(cs.decision_clean_date) - julianday(cs.submitted_clean)),1) AS avg_review_days,
  COUNT(*) AS num_of_papers
FROM clean_submissions cs 
JOIN clean_journals cj ON cs.journal_id = cj.journal_id
WHERE cs.decision_clean_date IS NOT NULL
GROUP BY cj.clean_subject_area
ORDER BY avg_review_days DESC;


-- Q3: which reviewers are carrying the heaviest workload? 
WITH clean_journals AS (
	SELECT DISTINCT journal_id, journal_name,
		CASE WHEN LOWER(TRIM(subject_area)) = 'political science' THEN 'Political Science'
			 WHEN LOWER(TRIM(subject_area)) = 'sociology' THEN 'Sociology' 
   	 		 WHEN LOWER(TRIM(subject_area)) = 'psychology' THEN 'Psychology'
    		 WHEN LOWER(TRIM(subject_area)) = 'methodology' then 'Methodology'
    		 WHEN LOWER(TRIM(subject_area)) = 'management' THEN 'Management'
    		 WHEN LOWER(TRIM(subject_area)) = 'education' THEN 'Education'
 		end as clean_subject_area,
  		CASE WHEN LOWER(TRIM(access_type)) IN ('subscription', 'sub') THEN 'Subscription'
  			 WHEN LOWER(TRIM(access_type)) IN ('open access', 'oa') THEN 'Open Access'
  		END AS clean_access_type
FROM journals
),
clean_reviewers AS (
SELECT DISTINCT reviewer_id, reviewer_name, field, 
	CASE WHEN LOWER(TRIM(is_active)) In ('yes', 'true', '1') THEN 1 ELSE 0 
    END AS active_clean 
FROM reviewers
),
clean_submissions AS (
	SELECT DISTINCT submission_id, journal_id,
  		CASE WHEN LOWER(TRIM(decision)) IN ('rejected', 'reject', 'rej') THEN 'Reject'
  			 WHEN LOWER(TRIM(decision)) IN ('accepted', 'accept')		 THEN 'Accept'
  			 WHEN LOWER(TRIM(decision)) IN ('revise', 'r&r', 'major revision', 'minor revision') THEN 'Revise'
  	END AS clean_decision,
    CASE WHEN submitted_date LIKE '____-__-__' THEN submitted_date
  	  ELSE substr(submitted_date,7,4) || '-' || 
  		   substr(submitted_date,4,2) || '-' || 
  		   substr(submitted_date,1,2)
  	END AS submitted_clean,
  CASE WHEN decision_date LIKE '____-__-__' THEN decision_date
  	  ELSE substr(decision_date,7,4) || '-' || 
  		   substr(decision_date,4,2) || '-' || 
  		   substr(decision_date,1,2)
  	END AS decision_clean_date,
  CASE WHEN published_date LIKE '____-__-__' THEN published_date
  	  ELSE substr(published_date,7,4) || '-' || 
  		   substr(published_date,4,2) || '-' || 
  		   substr(published_date,1,2)
  	END AS published_clean,
  CAST(REPLACE(REPLACE(REPLACE(apc_amount,'$',''),'£',''),',','') AS numeric) AS apc_clean
FROM submissions
),
clean_assignments AS (
  SELECT DISTINCT assignment_id, submission_id, reviewer_id
FROM review_assignments
WHERE reviewer_id IN (SELECT reviewer_id FROM reviewers)
),
clean_subscription AS (
  SELECT journal_id, year, 
  	CAST(REPLACE(REPLACE(subscription_revenue_local, '£', ''), ',', '') AS numeric) AS rev_clean
FROM subscription_revenue
WHERE journal_id IN (SELECT journal_id FROM journals) AND rev_clean IS NOT NULL
)
SELECT cr.reviewer_name, cr.field, COUNT(*) AS n_assignments
FROM clean_assignments ca 
JOIN clean_reviewers cr ON ca.reviewer_id = cr.reviewer_id
GROUP BY cr.reviewer_id
ORDER BY n_assignments DESC
LIMIT 10;


-- Q4: does reviewer workload actually explain the slow fields
WITH clean_journals AS (
	SELECT DISTINCT journal_id, journal_name,
		CASE WHEN LOWER(TRIM(subject_area)) = 'political science' THEN 'Political Science'
			 WHEN LOWER(TRIM(subject_area)) = 'sociology' THEN 'Sociology' 
   	 		 WHEN LOWER(TRIM(subject_area)) = 'psychology' THEN 'Psychology'
    		 WHEN LOWER(TRIM(subject_area)) = 'methodology' then 'Methodology'
    		 WHEN LOWER(TRIM(subject_area)) = 'management' THEN 'Management'
    		 WHEN LOWER(TRIM(subject_area)) = 'education' THEN 'Education'
 		end as clean_subject_area,
  		CASE WHEN LOWER(TRIM(access_type)) IN ('subscription', 'sub') THEN 'Subscription'
  			 WHEN LOWER(TRIM(access_type)) IN ('open access', 'oa') THEN 'Open Access'
  		END AS clean_access_type
FROM journals
),
clean_reviewers AS (
SELECT DISTINCT reviewer_id, reviewer_name, field, 
	CASE WHEN LOWER(TRIM(is_active)) In ('yes', 'true', '1') THEN 1 ELSE 0 
    END AS active_clean 
FROM reviewers
),
clean_submissions AS (
	SELECT DISTINCT submission_id, journal_id,
  		CASE WHEN LOWER(TRIM(decision)) IN ('rejected', 'reject', 'rej') THEN 'Reject'
  			 WHEN LOWER(TRIM(decision)) IN ('accepted', 'accept')		 THEN 'Accept'
  			 WHEN LOWER(TRIM(decision)) IN ('revise', 'r&r', 'major revision', 'minor revision') THEN 'Revise'
  	END AS clean_decision,
    CASE WHEN submitted_date LIKE '____-__-__' THEN submitted_date
  	  ELSE substr(submitted_date,7,4) || '-' || 
  		   substr(submitted_date,4,2) || '-' || 
  		   substr(submitted_date,1,2)
  	END AS submitted_clean,
  CASE WHEN decision_date LIKE '____-__-__' THEN decision_date
  	  ELSE substr(decision_date,7,4) || '-' || 
  		   substr(decision_date,4,2) || '-' || 
  		   substr(decision_date,1,2)
  	END AS decision_clean_date,
  CASE WHEN published_date LIKE '____-__-__' THEN published_date
  	  ELSE substr(published_date,7,4) || '-' || 
  		   substr(published_date,4,2) || '-' || 
  		   substr(published_date,1,2)
  	END AS published_clean,
  CAST(REPLACE(REPLACE(REPLACE(apc_amount,'$',''),'£',''),',','') AS numeric) AS apc_clean
FROM submissions
),
clean_assignments AS (
  SELECT DISTINCT assignment_id, submission_id, reviewer_id
FROM review_assignments
WHERE reviewer_id IN (SELECT reviewer_id FROM reviewers)
),
clean_subscription AS (
  SELECT journal_id, year, 
  	CAST(REPLACE(REPLACE(subscription_revenue_local, '£', ''), ',', '') AS numeric) AS rev_clean
FROM subscription_revenue
WHERE journal_id IN (SELECT journal_id FROM journals) AND rev_clean IS NOT NULL
),
per_reviewer AS (
  SELECT cr.reviewer_id, cr.field, COUNT(*) AS n
  FROM clean_assignments ca 
  JOIN clean_reviewers cr ON ca.reviewer_id = cr.reviewer_id
  GROUP BY cr.reviewer_id
)
SELECT field, ROUND(AVG(n),1) AS avg_assignments_per_reviewer, COUNT(*) AS n_reviewers
FROM per_reviewer
GROUP BY field
ORDER BY avg_assignments_per_reviewer DESC;


-- Q5: how much APC revenue does each open-access journal generate?
WITH clean_journals AS (
	SELECT DISTINCT journal_id, journal_name,
		CASE WHEN LOWER(TRIM(subject_area)) = 'political science' THEN 'Political Science'
			 WHEN LOWER(TRIM(subject_area)) = 'sociology' THEN 'Sociology' 
   	 		 WHEN LOWER(TRIM(subject_area)) = 'psychology' THEN 'Psychology'
    		 WHEN LOWER(TRIM(subject_area)) = 'methodology' then 'Methodology'
    		 WHEN LOWER(TRIM(subject_area)) = 'management' THEN 'Management'
    		 WHEN LOWER(TRIM(subject_area)) = 'education' THEN 'Education'
 		end as clean_subject_area,
  		CASE WHEN LOWER(TRIM(access_type)) IN ('subscription', 'sub') THEN 'Subscription'
  			 WHEN LOWER(TRIM(access_type)) IN ('open access', 'oa') THEN 'Open Access'
  		END AS clean_access_type
FROM journals
),
clean_reviewers AS (
SELECT DISTINCT reviewer_id, reviewer_name, field, 
	CASE WHEN LOWER(TRIM(is_active)) In ('yes', 'true', '1') THEN 1 ELSE 0 
    END AS active_clean 
FROM reviewers
),
clean_submissions AS (
	SELECT DISTINCT submission_id, journal_id,
  		CASE WHEN LOWER(TRIM(decision)) IN ('rejected', 'reject', 'rej') THEN 'Reject'
  			 WHEN LOWER(TRIM(decision)) IN ('accepted', 'accept')		 THEN 'Accept'
  			 WHEN LOWER(TRIM(decision)) IN ('revise', 'r&r', 'major revision', 'minor revision') THEN 'Revise'
  	END AS clean_decision,
    CASE WHEN submitted_date LIKE '____-__-__' THEN submitted_date
  	  ELSE substr(submitted_date,7,4) || '-' || 
  		   substr(submitted_date,4,2) || '-' || 
  		   substr(submitted_date,1,2)
  	END AS submitted_clean,
  CASE WHEN decision_date LIKE '____-__-__' THEN decision_date
  	  ELSE substr(decision_date,7,4) || '-' || 
  		   substr(decision_date,4,2) || '-' || 
  		   substr(decision_date,1,2)
  	END AS decision_clean_date,
  CASE WHEN published_date LIKE '____-__-__' THEN published_date
  	  ELSE substr(published_date,7,4) || '-' || 
  		   substr(published_date,4,2) || '-' || 
  		   substr(published_date,1,2)
  	END AS published_clean,
  CAST(REPLACE(REPLACE(REPLACE(apc_amount,'$',''),'£',''),',','') AS numeric) AS apc_clean
FROM submissions
),
clean_assignments AS (
  SELECT DISTINCT assignment_id, submission_id, reviewer_id
FROM review_assignments
WHERE reviewer_id IN (SELECT reviewer_id FROM reviewers)
),
clean_subscription AS (
  SELECT journal_id, year, 
  	CAST(REPLACE(REPLACE(subscription_revenue_local, '£', ''), ',', '') AS numeric) AS rev_clean
FROM subscription_revenue
WHERE journal_id IN (SELECT journal_id FROM journals) AND rev_clean IS NOT NULL
)
SELECT cj.journal_name, 
  COUNT(*) AS submissions, 
  ROUND(SUM(CASE WHEN cs.clean_decision = 'Accept' AND cs.published_clean IS NOT NULL THEN cs.apc_clean ELSE 0 END)) AS total_apc_revenue
FROM clean_submissions cs 
JOIN clean_journals cj ON cs.journal_id = cj.journal_id
WHERE cj.clean_access_type = 'Open Access'
GROUP BY cj.journal_name
ORDER BY total_apc_revenue DESC;


-- Q6: which open-access journal earns the most per submission?
WITH clean_journals AS (
	SELECT DISTINCT journal_id, journal_name,
		CASE WHEN LOWER(TRIM(subject_area)) = 'political science' THEN 'Political Science'
			 WHEN LOWER(TRIM(subject_area)) = 'sociology' THEN 'Sociology' 
   	 		 WHEN LOWER(TRIM(subject_area)) = 'psychology' THEN 'Psychology'
    		 WHEN LOWER(TRIM(subject_area)) = 'methodology' then 'Methodology'
    		 WHEN LOWER(TRIM(subject_area)) = 'management' THEN 'Management'
    		 WHEN LOWER(TRIM(subject_area)) = 'education' THEN 'Education'
 		end as clean_subject_area,
  		CASE WHEN LOWER(TRIM(access_type)) IN ('subscription', 'sub') THEN 'Subscription'
  			 WHEN LOWER(TRIM(access_type)) IN ('open access', 'oa') THEN 'Open Access'
  		END AS clean_access_type
FROM journals
),
clean_reviewers AS (
SELECT DISTINCT reviewer_id, reviewer_name, field, 
	CASE WHEN LOWER(TRIM(is_active)) In ('yes', 'true', '1') THEN 1 ELSE 0 
    END AS active_clean 
FROM reviewers
),
clean_submissions AS (
	SELECT DISTINCT submission_id, journal_id,
  		CASE WHEN LOWER(TRIM(decision)) IN ('rejected', 'reject', 'rej') THEN 'Reject'
  			 WHEN LOWER(TRIM(decision)) IN ('accepted', 'accept')		 THEN 'Accept'
  			 WHEN LOWER(TRIM(decision)) IN ('revise', 'r&r', 'major revision', 'minor revision') THEN 'Revise'
  	END AS clean_decision,
    CASE WHEN submitted_date LIKE '____-__-__' THEN submitted_date
  	  ELSE substr(submitted_date,7,4) || '-' || 
  		   substr(submitted_date,4,2) || '-' || 
  		   substr(submitted_date,1,2)
  	END AS submitted_clean,
  CASE WHEN decision_date LIKE '____-__-__' THEN decision_date
  	  ELSE substr(decision_date,7,4) || '-' || 
  		   substr(decision_date,4,2) || '-' || 
  		   substr(decision_date,1,2)
  	END AS decision_clean_date,
  CASE WHEN published_date LIKE '____-__-__' THEN published_date
  	  ELSE substr(published_date,7,4) || '-' || 
  		   substr(published_date,4,2) || '-' || 
  		   substr(published_date,1,2)
  	END AS published_clean,
  CAST(REPLACE(REPLACE(REPLACE(apc_amount,'$',''),'£',''),',','') AS numeric) AS apc_clean
FROM submissions
),
clean_assignments AS (
  SELECT DISTINCT assignment_id, submission_id, reviewer_id
FROM review_assignments
WHERE reviewer_id IN (SELECT reviewer_id FROM reviewers)
),
clean_subscription AS (
  SELECT journal_id, year, 
  	CAST(REPLACE(REPLACE(subscription_revenue_local, '£', ''), ',', '') AS numeric) AS rev_clean
FROM subscription_revenue
WHERE journal_id IN (SELECT journal_id FROM journals) AND rev_clean IS NOT NULL
)
SELECT cj.journal_name, 
  COUNT(*) AS submissions, 
  ROUND(SUM(CASE WHEN cs.clean_decision = 'Accept' AND cs.published_clean IS NOT NULL THEN cs.apc_clean ELSE 0 END)) AS total_apc_revenue,
  ROUND(SUM(CASE WHEN cs.clean_decision = 'Accept' AND cs.published_clean IS NOT NULL THEN cs.apc_clean ELSE 0 END) / COUNT(*),1) AS revenue_per_submission
FROM clean_submissions cs 
JOIN clean_journals cj ON cs.journal_id = cj.journal_id
WHERE cj.clean_access_type = 'Open Access'
GROUP BY cj.journal_name
ORDER BY revenue_per_submission DESC;


-- Q7: does subscription revenue track submission volume, or is it independent?
WITH clean_journals AS (
	SELECT DISTINCT journal_id, journal_name,
		CASE WHEN LOWER(TRIM(subject_area)) = 'political science' THEN 'Political Science'
			 WHEN LOWER(TRIM(subject_area)) = 'sociology' THEN 'Sociology' 
   	 		 WHEN LOWER(TRIM(subject_area)) = 'psychology' THEN 'Psychology'
    		 WHEN LOWER(TRIM(subject_area)) = 'methodology' then 'Methodology'
    		 WHEN LOWER(TRIM(subject_area)) = 'management' THEN 'Management'
    		 WHEN LOWER(TRIM(subject_area)) = 'education' THEN 'Education'
 		end as clean_subject_area,
  		CASE WHEN LOWER(TRIM(access_type)) IN ('subscription', 'sub') THEN 'Subscription'
  			 WHEN LOWER(TRIM(access_type)) IN ('open access', 'oa') THEN 'Open Access'
  		END AS clean_access_type
FROM journals
),
clean_reviewers AS (
SELECT DISTINCT reviewer_id, reviewer_name, field, 
	CASE WHEN LOWER(TRIM(is_active)) In ('yes', 'true', '1') THEN 1 ELSE 0 
    END AS active_clean 
FROM reviewers
),
clean_submissions AS (
	SELECT DISTINCT submission_id, journal_id,
  		CASE WHEN LOWER(TRIM(decision)) IN ('rejected', 'reject', 'rej') THEN 'Reject'
  			 WHEN LOWER(TRIM(decision)) IN ('accepted', 'accept')		 THEN 'Accept'
  			 WHEN LOWER(TRIM(decision)) IN ('revise', 'r&r', 'major revision', 'minor revision') THEN 'Revise'
  	END AS clean_decision,
    CASE WHEN submitted_date LIKE '____-__-__' THEN submitted_date
  	  ELSE substr(submitted_date,7,4) || '-' || 
  		   substr(submitted_date,4,2) || '-' || 
  		   substr(submitted_date,1,2)
  	END AS submitted_clean,
  CASE WHEN decision_date LIKE '____-__-__' THEN decision_date
  	  ELSE substr(decision_date,7,4) || '-' || 
  		   substr(decision_date,4,2) || '-' || 
  		   substr(decision_date,1,2)
  	END AS decision_clean_date,
  CASE WHEN published_date LIKE '____-__-__' THEN published_date
  	  ELSE substr(published_date,7,4) || '-' || 
  		   substr(published_date,4,2) || '-' || 
  		   substr(published_date,1,2)
  	END AS published_clean,
  CAST(REPLACE(REPLACE(REPLACE(apc_amount,'$',''),'£',''),',','') AS numeric) AS apc_clean
FROM submissions
),
clean_assignments AS (
  SELECT DISTINCT assignment_id, submission_id, reviewer_id
FROM review_assignments
WHERE reviewer_id IN (SELECT reviewer_id FROM reviewers)
),
clean_subscription AS (
  SELECT journal_id, year, 
  	CAST(REPLACE(REPLACE(subscription_revenue_local, '£', ''), ',', '') AS numeric) AS rev_clean
FROM subscription_revenue
WHERE journal_id IN (SELECT journal_id FROM journals) AND rev_clean IS NOT NULL
),
sub_vol AS (
  SELECT cj.journal_id, cj.journal_name, COUNT(*) AS submissions
  FROM clean_submissions cs 
  JOIN clean_journals cj ON cs.journal_id = cj.journal_id
  WHERE cj.clean_access_type = 'Subscription' 
  GROUP BY cj.journal_id
),
rev_total AS (
  SELECT journal_id, SUM(rev_clean) AS total_revenue
  FROM clean_subscription
  GROUP BY journal_id
)
SELECT sv.journal_name, sv.submissions, ROUND(rt.total_revenue) AS total_2yr_revenue
FROM sub_vol sv 
JOIN rev_total rt ON sv.journal_id = rt.journal_id
ORDER BY total_2yr_revenue DESC;


-- Q8: on average, which earns more per journal per year, subscription or open access?
WITH clean_journals AS (
	SELECT DISTINCT journal_id, journal_name,
		CASE WHEN LOWER(TRIM(subject_area)) = 'political science' THEN 'Political Science'
			 WHEN LOWER(TRIM(subject_area)) = 'sociology' THEN 'Sociology' 
   	 		 WHEN LOWER(TRIM(subject_area)) = 'psychology' THEN 'Psychology'
    		 WHEN LOWER(TRIM(subject_area)) = 'methodology' then 'Methodology'
    		 WHEN LOWER(TRIM(subject_area)) = 'management' THEN 'Management'
    		 WHEN LOWER(TRIM(subject_area)) = 'education' THEN 'Education'
 		end as clean_subject_area,
  		CASE WHEN LOWER(TRIM(access_type)) IN ('subscription', 'sub') THEN 'Subscription'
  			 WHEN LOWER(TRIM(access_type)) IN ('open access', 'oa') THEN 'Open Access'
  		END AS clean_access_type
FROM journals
),
clean_reviewers AS (
SELECT DISTINCT reviewer_id, reviewer_name, field, 
	CASE WHEN LOWER(TRIM(is_active)) In ('yes', 'true', '1') THEN 1 ELSE 0 
    END AS active_clean 
FROM reviewers
),
clean_submissions AS (
	SELECT DISTINCT submission_id, journal_id,
  		CASE WHEN LOWER(TRIM(decision)) IN ('rejected', 'reject', 'rej') THEN 'Reject'
  			 WHEN LOWER(TRIM(decision)) IN ('accepted', 'accept')		 THEN 'Accept'
  			 WHEN LOWER(TRIM(decision)) IN ('revise', 'r&r', 'major revision', 'minor revision') THEN 'Revise'
  	END AS clean_decision,
    CASE WHEN submitted_date LIKE '____-__-__' THEN submitted_date
  	  ELSE substr(submitted_date,7,4) || '-' || 
  		   substr(submitted_date,4,2) || '-' || 
  		   substr(submitted_date,1,2)
  	END AS submitted_clean,
  CASE WHEN decision_date LIKE '____-__-__' THEN decision_date
  	  ELSE substr(decision_date,7,4) || '-' || 
  		   substr(decision_date,4,2) || '-' || 
  		   substr(decision_date,1,2)
  	END AS decision_clean_date,
  CASE WHEN published_date LIKE '____-__-__' THEN published_date
  	  ELSE substr(published_date,7,4) || '-' || 
  		   substr(published_date,4,2) || '-' || 
  		   substr(published_date,1,2)
  	END AS published_clean,
  CAST(REPLACE(REPLACE(REPLACE(apc_amount,'$',''),'£',''),',','') AS numeric) AS apc_clean
FROM submissions
),
clean_assignments AS (
  SELECT DISTINCT assignment_id, submission_id, reviewer_id
FROM review_assignments
WHERE reviewer_id IN (SELECT reviewer_id FROM reviewers)
),
clean_subscription AS (
  SELECT journal_id, year, 
  	CAST(REPLACE(REPLACE(subscription_revenue_local, '£', ''), ',', '') AS numeric) AS rev_clean
FROM subscription_revenue
WHERE journal_id IN (SELECT journal_id FROM journals) AND rev_clean IS NOT NULL
),
oa_annual AS (
  SELECT cj.journal_id, SUM(CASE WHEN cs.clean_decision = 'Accept' AND cs.published_clean IS NOT NULL THEN cs.apc_clean ELSE 0 END) / 2.0 AS annual_rev
  FROM clean_submissions cs 
  JOIN clean_journals cj ON cs.journal_id = cj.journal_id
  WHERE cj.clean_access_type = 'Open Access' 
  GROUP BY cj.journal_id
),
sub_annual AS (
  SELECT journal_id, AVG(rev_clean) AS annual_rev
  FROM clean_subscription 
  GROUP BY journal_id
)
SELECT 'Open Access' AS model, ROUND(AVG(annual_rev)) AS avg_annual_revenue_per_journal 
FROM oa_annual
UNION ALL
SELECT 'Subscription', ROUND(AVG(annual_rev)) 
FROM sub_annual;


-- Q9: which journals are healthy, and which are stuck and low-value?
WITH clean_journals AS (
	SELECT DISTINCT journal_id, journal_name,
		CASE WHEN LOWER(TRIM(subject_area)) = 'political science' THEN 'Political Science'
			 WHEN LOWER(TRIM(subject_area)) = 'sociology' THEN 'Sociology' 
   	 		 WHEN LOWER(TRIM(subject_area)) = 'psychology' THEN 'Psychology'
    		 WHEN LOWER(TRIM(subject_area)) = 'methodology' then 'Methodology'
    		 WHEN LOWER(TRIM(subject_area)) = 'management' THEN 'Management'
    		 WHEN LOWER(TRIM(subject_area)) = 'education' THEN 'Education'
 		end as clean_subject_area,
  		CASE WHEN LOWER(TRIM(access_type)) IN ('subscription', 'sub') THEN 'Subscription'
  			 WHEN LOWER(TRIM(access_type)) IN ('open access', 'oa') THEN 'Open Access'
  		END AS clean_access_type
FROM journals
),
clean_reviewers AS (
SELECT DISTINCT reviewer_id, reviewer_name, field, 
	CASE WHEN LOWER(TRIM(is_active)) In ('yes', 'true', '1') THEN 1 ELSE 0 
    END AS active_clean 
FROM reviewers
),
clean_submissions AS (
	SELECT DISTINCT submission_id, journal_id,
  		CASE WHEN LOWER(TRIM(decision)) IN ('rejected', 'reject', 'rej') THEN 'Reject'
  			 WHEN LOWER(TRIM(decision)) IN ('accepted', 'accept')		 THEN 'Accept'
  			 WHEN LOWER(TRIM(decision)) IN ('revise', 'r&r', 'major revision', 'minor revision') THEN 'Revise'
  	END AS clean_decision,
    CASE WHEN submitted_date LIKE '____-__-__' THEN submitted_date
  	  ELSE substr(submitted_date,7,4) || '-' || 
  		   substr(submitted_date,4,2) || '-' || 
  		   substr(submitted_date,1,2)
  	END AS submitted_clean,
  CASE WHEN decision_date LIKE '____-__-__' THEN decision_date
  	  ELSE substr(decision_date,7,4) || '-' || 
  		   substr(decision_date,4,2) || '-' || 
  		   substr(decision_date,1,2)
  	END AS decision_clean_date,
  CASE WHEN published_date LIKE '____-__-__' THEN published_date
  	  ELSE substr(published_date,7,4) || '-' || 
  		   substr(published_date,4,2) || '-' || 
  		   substr(published_date,1,2)
  	END AS published_clean,
  CAST(REPLACE(REPLACE(REPLACE(apc_amount,'$',''),'£',''),',','') AS numeric) AS apc_clean
FROM submissions
),
clean_assignments AS (
  SELECT DISTINCT assignment_id, submission_id, reviewer_id
FROM review_assignments
WHERE reviewer_id IN (SELECT reviewer_id FROM reviewers)
),
clean_subscription AS (
  SELECT journal_id, year, 
  	CAST(REPLACE(REPLACE(subscription_revenue_local, '£', ''), ',', '') AS numeric) AS rev_clean
FROM subscription_revenue
WHERE journal_id IN (SELECT journal_id FROM journals) AND rev_clean IS NOT NULL
),
speed AS (
  SELECT cj.journal_id, cj.journal_name,
    ROUND(AVG(julianday(cs.decision_clean_date) - julianday(cs.submitted_clean)),1) AS avg_review_days
  FROM clean_submissions cs 
  JOIN clean_journals cj ON cs.journal_id = cj.journal_id
  WHERE cs.decision_clean_date IS NOT NULL GROUP BY cj.journal_id
)
SELECT s.journal_name, s.avg_review_days
FROM speed s
ORDER BY s.avg_review_days DESC;